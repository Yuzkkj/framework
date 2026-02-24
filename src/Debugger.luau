local RunService = game:GetService("RunService")

local module = {
	["print"] = function<T...>(...: T...): ()
		if not RunService:IsStudio() then
			return
		end

		local prefix = (RunService:IsServer() and "S") or "C"

		print(`[{prefix}]: `, ...)
	end :: typeof(print),
	["warn"] = function<T...>(...: T...): ()
		if not RunService:IsStudio() then
			return
		end

		local prefix = (RunService:IsServer() and "S") or "C"

		warn(`[{prefix}]: `, ...)
	end :: typeof(warn),
	["error"] = function<T>(message: T, level: number?): ()
		if not RunService:IsStudio() then
			return
		end

		local prefix = (RunService:IsServer() and "S") or "C"

		error(`[{prefix}]: {message}`, level)
	end :: typeof(error),
}

return module
