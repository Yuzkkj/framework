local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent:WaitForChild("Promise"))

local utils = require(script.Parent.utils)

export type CaseStyle = "camel" | "Pascal"

export type StartOptions = {
	components: Folder,
	controllers: Folder,
	handlers: Folder,
}

local client = {}
--[=[
	Determinates what case style should be used when calling methods.
]=]
client.casing = "camel" :: CaseStyle
--[=[
	Determinates if it should wait for server to load before starting.
]=]
client.waitForServer = true
--[=[
	Yields until server load completes if `waitForServer` is true.
	Initializes controllers, then starts controllers, and then start components.

	```luau
	Framework:start({
		components = path.to.components,
		controllers = path.to.controllers,
		handlers = path.to.handlers,
	})
		:andThen(function(delta)
			print(`Client load completed. Took: {delta}s`)
		end)
		:catch(function(err)
			warn(`Something went wrong while starting framework from client: {err}`)
		end)
	```

	@yields
	@param startOptions StartOptions
	@return A promise that resolves with the time taken to start
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

		local controllers = utils.getContents(startOptions.controllers)
		local components = utils.getContents(startOptions.components)
		local handlers = utils.getContents(startOptions.handlers)

		utils.debugger.warn("Initializing controllers")
		utils.callFrom(if self.casing == "Pascal" then "Init" else "init", controllers, function(controllerName)
			utils.debugger.print(`{controllerName} initialized`)
		end)

		utils.debugger.warn("Starting controllers")
		utils.callFrom(if self.casing == "Pascal" then "Start" else "start", controllers, function(controllerName)
			utils.debugger.print(`{controllerName} started`)
		end)

		utils.debugger.warn("Starting components")
		utils.startComponents(components)

		utils.debugger.warn("Calling handlers")
		utils.call(handlers, function(name)
			utils.debugger.print(`Handler {name} called`)
		end)

		resolve(tick() - startTick)
	end)
end

return client
