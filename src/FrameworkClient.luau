local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent:WaitForChild("Promise"))

local FrameworkUtils = require(script.Parent.FrameworkUtils)

--[=[
	@interface StartOptions
	@within FrameworkClient
	.components Folder -- Folder containing components.
	.controllers Folder -- Folder containing controllers.
	.handlers Folder -- Folder containing handlers.

	Provides options to start FrameworkClient.

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local options = {
		components = ReplicatedStorage.components,
		controllers = ReplicatedStorage.controllers,
		handlers = ReplicatedStorage.handlers,
	}
	```
]=]
export type StartOptions = {
	components: Folder,
	controllers: Folder,
	handlers: Folder,
}

--[=[
	@class FrameworkClient

	The client-side of framework.
]=]
local FrameworkClient = {}

--[=[
	@prop casing "camel" | "Pascal"
	@within FrameworkClient

	Determinates what case style should be used when calling methods.
]=]
FrameworkClient.casing = "camel" :: "camel" | "Pascal"

--[=[
	@prop waitForServer boolean
	@within FrameworkClient

	Determines if it should yield until server fully start.
]=]
FrameworkClient.waitForServer = true

--[=[
	@method start
	@within FrameworkClient
	@yields
	@param startOptions StartOptions
	@return Promise -- A promise that resolves with the time it took to start the framework.

	Initializes controllers, then starts controllers, then start components and finally call the handlers.

	```lua
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

	:::note
	The tag used for components will be the same as it's name, and `destroy` will be automatically called either when the tag is removed or the instance is destroyed.
	:::

	:::warning
	`:start(...)` yields until server load completes if `waitForServer` is set to true.
	:::
]=]
function FrameworkClient:start(startOptions: StartOptions): Promise.Promise
	assert(RunService:IsClient(), "Framework client can only be called from client")

	return Promise.new(function(resolve)
		local startTick = tick()
		if
			self.waitForServer
			and script.Parent:GetAttribute(FrameworkUtils.constants.SERVER_LOADED_ATTRIBUTE) == nil
		then
			FrameworkUtils.debugger.print("Waiting for server to load...")

			repeat
				task.wait(1)
			until script.Parent:GetAttribute(FrameworkUtils.constants.SERVER_LOADED_ATTRIBUTE) ~= nil
		end

		local controllers = FrameworkUtils.getContents(startOptions.controllers)
		local components = FrameworkUtils.getContents(startOptions.components)
		local handlers = FrameworkUtils.getContents(startOptions.handlers)

		FrameworkUtils.debugger.warn("Initializing controllers")
		FrameworkUtils.callFrom(
			if self.casing == "Pascal" then "Init" else "init",
			controllers,
			function(controllerName)
				FrameworkUtils.debugger.print(`{controllerName} initialized`)
			end
		)

		FrameworkUtils.debugger.warn("Starting controllers")
		FrameworkUtils.callFrom(
			if self.casing == "Pascal" then "Start" else "start",
			controllers,
			function(controllerName)
				FrameworkUtils.debugger.print(`{controllerName} started`)
			end
		)

		FrameworkUtils.debugger.warn("Starting components")
		FrameworkUtils.startComponents(components, self.casing)

		FrameworkUtils.debugger.warn("Calling handlers")
		FrameworkUtils.call(handlers, function(name)
			FrameworkUtils.debugger.print(`Handler {name} called`)
		end)

		resolve(tick() - startTick)
	end)
end

return FrameworkClient
