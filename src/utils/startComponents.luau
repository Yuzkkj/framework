local CollectionService = game:GetService("CollectionService")

local Promise = require(script.Parent.Parent.Parent:WaitForChild("Promise"))

local debugger = require(script.Parent.debugger)
local objectsCache = {} :: { [Instance]: any & { Destroy: () -> () } }

return function(components: { [string]: any }): ()
	for componentName, content in pairs(components) do
		if type(content.new) ~= "function" then
			continue
		end

		for _, instance in pairs(CollectionService:GetTagged(componentName)) do
			Promise.promisify(content.new)(instance)
				:andThen(function(object)
					objectsCache[instance] = object
				end)
				:catch(function(err)
					debugger.warn(
						`Failed to create object for instance {instance.Name} of component {componentName}: {err}`
					)
				end)
		end

		CollectionService:GetInstanceAddedSignal(componentName):Connect(function(instance)
			Promise.promisify(content.new)(instance)
				:andThen(function(object)
					objectsCache[instance] = object
				end)
				:catch(function(err)
					debugger.warn(
						`Failed to create object for instance {instance.Name} of component {componentName}: {err}`
					)
				end)
		end)

		CollectionService:GetInstanceRemovedSignal(componentName):Connect(function(instance)
			local object = objectsCache[instance]
			if object then
				object:Destroy()
			end
		end)

		debugger.print(`{componentName} component started`)
	end
end
