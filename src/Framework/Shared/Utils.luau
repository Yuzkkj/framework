local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local Types = require(script.Parent.Types)

local debugger = require(ReplicatedStorage.Modules.Plataform.Debugger)

local module = {}

-- Returns a dictionary of module names and it contents
function module.getContents(folder: Folder): { [string]: { any? } }
	local modules = {}

	for _, descendant in pairs(folder:GetDescendants()) do
		if not descendant:IsA("ModuleScript") then
			continue
		end

		local success, result = pcall(require, descendant)
		if not success then
			debugger.warn(`Failed to require module {descendant.Name}: {result}`)
			continue
		end

		modules[descendant.Name] = result
	end

	return modules
end

-- Calls the given function name on all module contents
function module.callFrom(funcName: string, contents: { [string]: { any? } }, callback: (name: string) -> ()): ()
	for contentName, content in pairs(contents) do
		if type(content) ~= "table" then
			continue
		end

		if type(content[funcName]) ~= "function" then
			continue
		end

		Promise.promisify(content[funcName])(content):andThenCall(callback, contentName):catch(function(err)
			debugger.warn(`Something went wrong while calling {funcName} from {contentName}: {err}`)
		end)
	end
end

function module.startComponents(components: { [string]: Types.Component<Instance> }): ()
	for componentName, content in pairs(components) do
		if type(content.new) ~= "function" then
			continue
		end

		if not content.Tag then
			debugger.warn(`Missing tag for {componentName} component`)
			continue
		end

		for _, instance in pairs(CollectionService:GetTagged(content.Tag)) do
			local success, object = pcall(content.new, instance)
			if not success then
				debugger.warn(
					`Failed to create object for instance {instance.Name} of component {componentName}: {object}`
				)
				continue
			end

			object._janitor:Add(CollectionService:GetInstanceRemovedSignal(content.Tag):Connect(function(removedFrom)
				if instance == removedFrom then
					object:Destroy()
				end
			end))
		end

		CollectionService:GetInstanceAddedSignal(content.Tag):Connect(function(instance)
			local success, object = pcall(content.new, instance)
			if not success then
				debugger.warn(
					`Failed to create object for instance {instance.Name} of component {componentName}: {object}`
				)
				return
			end

			object._janitor:Add(CollectionService:GetInstanceRemovedSignal(content.Tag):Connect(function(removedFrom)
				if instance == removedFrom then
					object:Destroy()
				end
			end))
		end)

		debugger.print(`{componentName} component started`)
	end
end

return module
