local RunService = game:GetService("RunService")

local Promise = require(script.Parent:WaitForChild("Promise"))

local debugger = require(script.Debugger)
local utils = require(script.Utils)

local SERVER_LOADED_ATTRIBUTE = "ServerFinished"

local Framework = {}

Framework.WaitForServer = true
Framework.SendDebugMessages = true

--[=[
	Set the services to be used on `Start`. Can be called only by the server.
]=]
function Framework.SetServices(self: Framework, container: Folder): ()
	assert(RunService:IsServer(), "SetServices can only be called from server.")

	self._services = utils.getContents(container)
end
--[=[
	Set the controllers to be used on `Start`. Can be called only by the client.
]=]
function Framework.SetControllers(self: Framework, container: Folder): ()
	assert(RunService:IsClient(), "SetControllers can only be called on client.")

	self._controllers = utils.getContents(container)
end
--[=[
	Set the components to be used on `Start`. Can be called on both server and client.
]=]
function Framework.SetComponents(self: Framework, container: Folder): ()
	self._components = utils.getContents(container)
end
--[=[
	Set the handlers to be used on `Start`. Can be called on both server and client.
]=]
function Framework.SetHandlers(self: Framework, container: Folder): ()
	self._handlers = utils.getContents(container)
end
--[=[
	Initialize services/controllers, then start services/controllers, then start components and handlers.
	@return a promise that resolves with delta time of startup.
]=]
function Framework.Start(self: Framework): Promise.Promise
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

			debugger.warn("Calling handlers")
			utils.call(self._handlers, function(handlerName: string)
				debugger.print(`Called {handlerName} handler`)
			end)

			if self.WaitForServer then
				script:SetAttribute(SERVER_LOADED_ATTRIBUTE, true)
			end

			resolve(tick() - startTick)
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

			debugger.warn("Calling handlers")
			utils.call(self._handlers, function(handlerName: string)
				debugger.print(`Called {handlerName} handler`)
			end)

			resolve(tick() - startTick)
		end)
	else
		return Promise.reject(`An unknown error has occurred while starting the framework`)
	end
end

type Framework = typeof(Framework) & {
	_services: { [string]: any }?,
	_controllers: { [string]: any },
	_components: { [string]: any },
	_handlers: { [string]: () -> () },
}

return Framework :: Framework
