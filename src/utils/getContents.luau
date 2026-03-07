local debugger = require(script.Parent.debugger)

return function(folder: Folder): { [string]: any }
	local modules = {}

	for _, descendant in pairs(folder:GetDescendants()) do
		if not descendant:IsA("ModuleScript") then
			continue
		end

		local success, result = pcall(require, descendant)
		if not success then
			debugger.warn(`Failed to require module {descendant.Name}: {result}`)
			continue
		end

		modules[descendant.Name] = result
	end

	return modules
end
