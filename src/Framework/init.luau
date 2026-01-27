local RunService = game:GetService("RunService")

local Promise = require(script.Shared.Promise)

local Types = require(script.Shared.Types)

local debugger = require(script.Shared.Debugger)
local utils = require(script.Shared.Utils)

local SERVER_LOADED_ATTRIBUTE = "ServerFinished"

local Framework = {}

Framework.WaitForServer = true
Framework.Types = Types

function Framework.SetServices(self: Framework, container: Folder): ()
	assert(RunService:IsServer(), "SetServices can only be called from server.")

	self._services = utils.getContents(container)
end

function Framework.SetControllers(self: Framework, container: Folder): ()
	assert(RunService:IsClient(), "SetControllers can only be called on client.")

	self._controllers = utils.getContents(container)
end

function Framework.SetComponents(self: Framework, container: Folder): ()
	self._components = utils.getContents(container)
end

function Framework.SetUI(self: Framework, container: Folder): ()
	assert(RunService:IsClient(), "SetUserInterface can only be called on client")

	self._userInterface = utils.getContents(container)
end

function Framework.Start(self: Framework): typeof(Promise.new())
	if RunService:IsServer() then
		return Promise.new(function(resolve)
			local startTick = tick()

			debugger.warn("Initializing services")
			utils.callFrom("Init", self._services, function(serviceName)
				debugger.print(`{serviceName} initialized`)
			end)

			debugger.warn("Starting services")
			utils.callFrom("Start", self._services, function(serviceName)
				debugger.print(`{serviceName} started`)
			end)

			debugger.warn("Starting components")
			utils.startComponents(self._components)

			if self.WaitForServer then
				script:SetAttribute(SERVER_LOADED_ATTRIBUTE, true)
			end

			local delta = tick() - startTick
			resolve(delta * 1000)
		end)
	elseif RunService:IsClient() then
		return Promise.new(function(resolve)
			local startTick = tick()
			if self.WaitForServer and script:GetAttribute(SERVER_LOADED_ATTRIBUTE) == nil then
				debugger.print("Waiting for server to load...")

				repeat
					task.wait(1)
				until script:GetAttribute(SERVER_LOADED_ATTRIBUTE) ~= nil
			end

			debugger.warn("Initializing controllers")
			utils.callFrom("Init", self._controllers, function(controllerName)
				debugger.print(`{controllerName} initialized`)
			end)

			debugger.warn("Starting controllers")
			utils.callFrom("Start", self._controllers, function(controllerName)
				debugger.print(`{controllerName} started`)
			end)

			debugger.warn(`Starting components`)
			utils.startComponents(self._components)

			debugger.warn("Starting user interface")
			for name, callback in pairs(self._userInterface) do
				if type(callback) ~= "function" then
					continue
				end

				Promise.promisify(callback)()
					:andThen(function()
						debugger.print(`UI {name} started`)
					end)
					:catch(function(err)
						debugger.warn(`Something went wrong while starting UI {name}: {err}`)
					end)
			end

			local delta = tick() - startTick
			resolve(delta * 1000)
		end)
	else
		error(`WTF?`)
	end
end

type Framework = typeof(Framework) & {
	_services: { [string]: Types.Service }?,
	_controllers: { [string]: Types.Controller },
	_components: { [string]: Types.Component<Instance> },
	_userInterface: { [string]: Types.UI },
}

return Framework :: Framework
