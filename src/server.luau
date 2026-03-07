local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent:WaitForChild("Promise"))

local utils = require(script.Parent.utils)

export type CaseStyle = "camel" | "Pascal"

export type StartOptions = {
	servicesContainer: Folder,
	componentsContainer: Folder,
}

local server = {}
--[=[
	Determinates what case should be used when calling methods.
]=]
server.caseStyle = "camel" :: CaseStyle
--[=[
	Determines if client startup should wait until server load finish.
]=]
server.waitForServer = true
--[=[
	Initializes services, then starts services, and then start components.

	@yields
	@param startOptions StartOptions
	@return Promise A promise that resolves with the time taken to start
]=]
function server:start(startOptions: StartOptions): Promise.Promise
	assert(RunService:IsServer(), "Framework server can only be called from server")
	return Promise.new(function(resolve)
		local startTick = tick()

		local services = utils.getContents(startOptions.servicesContainer)
		local components = utils.getContents(startOptions.componentsContainer)

		utils.debugger.warn("Initializing services")
		utils.callFrom(if self.caseStyle == "Pascal" then "Init" else "init", services, function(serviceName)
			utils.debugger.print(`{serviceName} initialized`)
		end)

		utils.debugger.warn("Starting services")
		utils.callFrom(if self.caseStyle == "Pascal" then "Start" else "start", services, function(serviceName)
			utils.debugger.print(`{serviceName} started`)
		end)

		utils.debugger.warn("Starting components")
		utils.startComponents(components)

		if self.waitForServer then
			script.Parent:SetAttribute(utils.constants.SERVER_LOADED_ATTRIBUTE, true)
		end

		resolve(tick() - startTick)
	end)
end

return server
