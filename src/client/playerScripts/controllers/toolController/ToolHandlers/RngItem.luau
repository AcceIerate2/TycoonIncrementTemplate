-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local RngItemTool = {
	RngController = knit.GetController("RngController"),
}

function RngItemTool:Bind(tool: Tool)
	local connections = {}
	local instances = {}

	table.insert(
		connections,
		tool.Equipped:Connect(function()
			self.RngController:Connect(tool.Name)
		end)
	)

	table.insert(
		connections,
		tool.Unequipped:Connect(function()
			self.RngController:Disconnect(tool.Name)
			for _, v in pairs(instances) do
				if v then
					v:Destroy()
				end
			end
			table.clear(instances)
		end)
	)

	return connections
end

function RngItemTool:Disconnect(tool: Tool)
	self.RngController:Disconnect(tool.Name)
end

return RngItemTool
