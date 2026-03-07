local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent:WaitForChild("Promise"))

local utils = require(script.Parent.utils)

export type CaseStyle = "camel" | "Pascal"

export type StartOptions = {
	controllersContainer: Folder,
	componentsContainer: Folder,
}

local client = {}
--[=[
	Determinates what case should be used when calling methods.
]=]
client.caseStyle = "camel" :: CaseStyle
--[=[
	Determinates if it should wait for server to load before starting.
]=]
client.waitForServer = true
--[=[
	Yields until server load completes if `waitForServer` is true.

	Initializes controllers, then starts controllers, and then start components.

	@yields
	@param startOptions StartOptions
	@return Promise A promise that resolves with the time taken to start
]=]
function client:start(startOptions: StartOptions): Promise.Promise
	assert(RunService:IsClient(), "Framework client can only be called from client")
	return Promise.new(function(resolve)
		local startTick = tick()
		if self.waitForServer and script.Parent:GetAttribute(utils.constants.SERVER_LOADED_ATTRIBUTE) == nil then
			utils.debugger.print("Waiting for server to load...")

			repeat
				task.wait(1)
			until script.Parent:GetAttribute(utils.constants.SERVER_LOADED_ATTRIBUTE) ~= nil
		end

		local controllers = utils.getContents(startOptions.controllersContainer)
		local components = utils.getContents(startOptions.componentsContainer)

		utils.debugger.warn("Initializing controllers")
		utils.callFrom(if self.caseStyle == "Pascal" then "Init" else "init", controllers, function(controllerName)
			utils.debugger.print(`{controllerName} initialized`)
		end)

		utils.debugger.warn("Starting controllers")
		utils.callFrom(if self.caseStyle == "Pascal" then "Start" else "start", controllers, function(controllerName)
			utils.debugger.print(`{controllerName} started`)
		end)

		utils.debugger.warn(`Starting components`)
		utils.startComponents(components)

		resolve(tick() - startTick)
	end)
end

return client
