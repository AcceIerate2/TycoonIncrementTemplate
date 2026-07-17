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
		end)
	)

	return connections
end

function RngItemTool:Disconnect(tool: Tool)
	self.RngController:Disconnect(tool.Name)
end

return RngItemTool
