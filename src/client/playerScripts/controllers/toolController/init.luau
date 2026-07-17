-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- References
local Player = Players.LocalPlayer
local Backpack = Player:WaitForChild("Backpack")
local toolHandlers = script:WaitForChild("ToolHandlers")

-->
local ToolController = knit.CreateController({
	Name = "ToolController",
	ToolConnections = {} :: { [Tool]: { RBXScriptConnection } },
	ContainerConnections = {} :: { RBXScriptConnection },
})

function ToolController:disconnectContainerConnections()
	for _, connection: RBXScriptConnection in pairs(self.ContainerConnections) do
		connection:Disconnect()
	end
	table.clear(self.ContainerConnections)
end

function ToolController:connectTool(tool: Tool)
	if not tool:IsA("Tool") then
		return
	end

	local handlerName = tool:GetAttribute("Handler")
	if typeof(handlerName) ~= "string" then
		warn(`Tool "{tool.Name}" is missing a string Handler attribute`)
		return
	end

	local moduleScript = toolHandlers:FindFirstChild(handlerName)
	if not moduleScript then
		warn(`Tool handler "{handlerName}" not found`)
		return
	end

	local handler = require(moduleScript)
	if typeof(handler) ~= "table" then
		warn(`Tool handler "{handlerName}" must return a table`)
		return
	end

	self:disconnectTool(tool)
	local connections = {}

	if typeof(handler.Bind) == "function" then
		local bindConnections = handler:Bind(tool)

		if typeof(bindConnections) == "table" then
			for _, connection in bindConnections do
				table.insert(connections, connection)
			end
		end
	end

	table.insert(
		connections,
		tool.Destroying:Connect(function()
			self:disconnectTool(tool)
		end)
	)

	self.ToolConnections[tool] = {
		Handler = handler,
		Connections = connections,
	}
end

function ToolController:disconnectTool(tool: Tool)
	if not tool:IsA("Tool") then
		return
	end

	local data = self.ToolConnections[tool]
	if typeof(data) ~= "table" then
		return
	end

	local handler = data.Handler
	if typeof(handler) == "table" and typeof(handler.Disconnect) == "function" then
		handler:Disconnect(tool)
	end

	for _, connection: RBXScriptConnection in data.Connections do
		if connection.Connected then
			connection:Disconnect()
		end
	end

	self.ToolConnections[tool] = nil
end

function ToolController:connectContainer(container: Instance)
	table.insert(
		self.ContainerConnections,
		container.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				self:connectTool(child)
			end
		end)
	)

	table.insert(
		self.ContainerConnections,
		container.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				self:disconnectTool(child)
			end
		end)
	)
end

function ToolController:preloadTools()
	for _, tool in pairs(Backpack:GetChildren()) do
		if tool:IsA("Tool") then
			self:connectTool(tool)
		end
	end

	if Player.Character then
		for _, tool in pairs(Player.Character:GetChildren()) do
			if tool:IsA("Tool") then
				self:connectTool(tool)
			end
		end
	end
end

-- LifeCycle
function ToolController:KnitInit()
	self.InventoryService = knit.GetService("InventoryService")
end

function ToolController:KnitStart()
	self.InventoryService.disconnectHandler:Connect(function(handler: string, args: {})
		local moduleScript = toolHandlers:FindFirstChild(handler)
		if not moduleScript then
			warn(`Tool handler "{handler}" not found`)
			return
		end

		local handlerFn = require(moduleScript)
		handlerFn:Disconnect(table.unpack(args))
	end)

	self:preloadTools()
	self:connectContainer(Backpack)

	if Player.Character then
		self:connectContainer(Player.Character)
	end

	Player.CharacterAdded:Connect(function(newCharacter)
		self:disconnectContainerConnections()
		self:connectContainer(Backpack)
		self:connectContainer(newCharacter)
	end)
end

return ToolController
