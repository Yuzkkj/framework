local Promise = require(script.Parent.Parent.Parent:WaitForChild("Promise"))

local debugger = require(script.Parent.debugger)

return function(contents: { [string]: () -> () }, callback: (name: string) -> ()): ()
    for contentName, func in pairs(contents) do
        if type(func) ~= "function" then
            continue
        end

        Promise.promisify(func)():andThenCall(callback, contentName):catch(function(err)
            debugger.warn(`Something went wrong while calling {contentName}: {err}`)
        end)
    end
end
