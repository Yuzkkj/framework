local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent:WaitForChild("Promise"))

local utils = require(script.Parent.utils)

export type CaseStyle = "camel" | "Pascal"

export type StartOptions = {
	components: Folder,
	handlers: Folder,
	services: Folder,
}

local server = {}
--[=[
	Determinates what case style should be used when calling methods.
]=]
server.casing = "Pascal" :: CaseStyle
--[=[
	Determines if client startup should wait until server load finish.
]=]
server.waitForServer = true
--[=[
	Initializes services, then starts services, and then start components.

	@param startOptions StartOptions
	@return A promise that resolves with the time taken to start
]=]
function server:start(startOptions: StartOptions): Promise.Promise
	assert(RunService:IsServer(), "Framework server can only be called from server")

	return Promise.new(function(resolve)
		local startTick = tick()

		local services = utils.getContents(startOptions.services)
		local components = utils.getContents(startOptions.components)
		local handlers = utils.getContents(startOptions.handlers)

		utils.debugger.warn("Initializing services")
		utils.callFrom(if self.casing == "Pascal" then "Init" else "init", services, function(serviceName)
			utils.debugger.print(`{serviceName} initialized`)
		end)

		utils.debugger.warn("Starting services")
		utils.callFrom(if self.casing == "Pascal" then "Start" else "start", services, function(serviceName)
			utils.debugger.print(`{serviceName} started`)
		end)

		utils.debugger.warn("Starting components")
		utils.startComponents(components)

		utils.debugger.warn("Calling handlers")
		utils.call(handlers, function(name)
			utils.debugger.print(`Handler {name} called`)
		end)

		if self.waitForServer then
			script.Parent:SetAttribute(utils.constants.SERVER_LOADED_ATTRIBUTE, true)
		end

		resolve(tick() - startTick)
	end)
end

return server
