local RunService = game:GetService("RunService")

local Promise = require(script.Parent.Parent:WaitForChild("Promise"))

local FrameworkUtils = require(script.Parent.FrameworkUtils)

--[=[
	@interface StartOptions
	@within FrameworkServer
	.components Folder -- Folder containing components.
	.handlers Folder -- Folder containing handlers.
	.services Folder -- Folder containing services.

	Provides options to start FrameworkServer.

	```lua
	local ServerScriptService = game:GetService("ServerScriptService")

	local options = {
		components = ServerScriptService.components,
		handlers = ServerScriptService.handlers,
		services = ServerScriptService.services,
	}
	```
]=]
export type StartOptions = {
	components: Folder,
	handlers: Folder,
	services: Folder,
}

--[=[
	@class FrameworkServer

	The server-side of framework.
]=]
local FrameworkServer = {}

--[=[
	@prop casing "camel" | "Pascal"
	@within FrameworkServer

	Determinates what case style should be used when calling methods.
]=]
FrameworkServer.casing = "camel" :: "camel" | "Pascal"

--[=[
	@method start
	@within FrameworkServer
	@param options StartOptions
	@return Promise -- A promise that resolves with the time it took to start the framework.

	Initializes services, then starts services, then start components and finally call the handlers.

	```lua
	Framework:start({
		components = path.to.components,
		handlers = path.to.handlers,
		services = path.to.services,
	})
		:andThen(function(delta)
			print(`Server load completed. Took: {delta}s`)
		end)
		:catch(function(err)
			warn(`Something went wrong while starting framework from server: {err}`)
		end)
	````

	:::note
	The tag used for components will be the same as it's name, and `destroy` will be automatically called either when the tag is removed or the instance is destroyed.
	:::
]=]
function FrameworkServer:start(startOptions: StartOptions): Promise.Promise
	assert(RunService:IsServer(), "Framework server can only be called from server")

	return Promise.new(function(resolve)
		local startTick = tick()

		local services = FrameworkUtils.getContents(startOptions.services)
		local components = FrameworkUtils.getContents(startOptions.components)
		local handlers = FrameworkUtils.getContents(startOptions.handlers)

		FrameworkUtils.debugger.warn("Initializing services")
		FrameworkUtils.callFrom(if self.casing == "Pascal" then "Init" else "init", services, function(serviceName)
			FrameworkUtils.debugger.print(`{serviceName} initialized`)
		end)

		FrameworkUtils.debugger.warn("Starting services")
		FrameworkUtils.callFrom(if self.casing == "Pascal" then "Start" else "start", services, function(serviceName)
			FrameworkUtils.debugger.print(`{serviceName} started`)
		end)

		FrameworkUtils.debugger.warn("Starting components")
		FrameworkUtils.startComponents(components, self.casing)

		FrameworkUtils.debugger.warn("Calling handlers")
		FrameworkUtils.call(handlers, function(name)
			FrameworkUtils.debugger.print(`Handler {name} called`)
		end)

		script.Parent:SetAttribute(FrameworkUtils.constants.SERVER_LOADED_ATTRIBUTE, true)

		resolve(tick() - startTick)
	end)
end

return FrameworkServer
