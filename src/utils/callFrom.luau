local Promise = require(script.Parent.Parent.Parent:WaitForChild("Promise"))

local debugger = require(script.Parent.debugger)

return function(funcName: string, contents: { [string]: { any? } }, callback: (name: string) -> ()): ()
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
