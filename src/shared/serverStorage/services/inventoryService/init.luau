-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local InventoryService = knit.CreateService({
	Name = "InventoryService",
	Client = {
		disconnectHandler = knit.CreateSignal(),
		toolAdded = knit.CreateSignal(),
		toolRemoved = knit.CreateSignal(),
		updateSlot = knit.CreateSignal(),
	},

	InventoryChanged = Signal.new(),

	Connections = {} :: { [Player]: { RBXScriptConnection } },
	Utility = require(script.InventoryServiceUtility),
})

-- Client Exposed Methods
function InventoryService.Client:getInventory(player: Player)
	local inventoryData = self.Server:GetPlayerInventoryValueObject(player):Get()
	return {
		Status = true,
		Data = inventoryData,
	}
end

-- Server Only Methods
function InventoryService:GetPlayerInventoryValueObject(player: Player)
	return self.DataService:GetValueObject(player, "Inventory")
end

function InventoryService:Owns(player: Player, toolName: string)
	local inventoryValueObject = self:GetPlayerInventoryValueObject(player)
	return inventoryValueObject:Get()[toolName] ~= nil
end

function InventoryService:GetQuantity(player: Player, toolName: string): number
	local inventoryValueObject = self:GetPlayerInventoryValueObject(player)
	local toolData = inventoryValueObject:Get()[toolName]

	if not toolData then
		if RunService:IsStudio() then
			warn(`[{toolName}] not found in inventory or has zero uses left - InventoryService:getQuantity`)
		end
		return 0
	end

	local uses = toolData["Quantity"]
	if typeof(uses) ~= "number" then
		if RunService:IsStudio() then
			warn(`Invalid Quantity for [{toolName}] (got: {typeof(uses)}) - InventoryService:getQuantity`)
		end
		return 0
	end

	return uses
end

function InventoryService:EquipTool(player: Player, tool: Tool)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "player arg must be a Player Instance")
	assert(typeof(tool) == "Instance" and tool:IsA("Tool"), "tool arg must be a Tool Instance")
	task.spawn(function()
		local character = player.Character
		if character then
			tool.Parent = character
		end
	end)
end

function InventoryService:Remove(player: Player, toolName: string)
	local inventoryValueObject = self:GetPlayerInventoryValueObject(player)
	local toolData = inventoryValueObject:Get()[toolName]

	inventoryValueObject:Remove(nil, toolName)
	local quantity = self:GetQuantity(player, toolName)

	if quantity < 1 then
		self.Utility:DestroyTool(player, toolName)

		if typeof(toolData.Handler) == "string" then
			self.Client.disconnectHandler:Fire(player, toolData.Handler, { toolName })
		end

		self.Client.toolRemoved:Fire(player, {
			Name = toolName,
			Quantity = 0,
		})
	else
		self.Client.updateSlot:Fire(player, {
			Name = toolName,
			Quantity = quantity,
		})
	end

	self.InventoryChanged:Fire(player, inventoryValueObject:Get())
	return quantity
end

function InventoryService:Give(player: Player, toolName: string, handler: string, customData: { [string]: any })
	local dataToInsert = {
		Quantity = 1,
		Handler = handler,
		Name = toolName,
	}

	if typeof(customData) == "table" then
		for key: string, value: any in pairs(customData) do
			dataToInsert[key] = value
		end
	end

	local inventoryValueObject = self:GetPlayerInventoryValueObject(player)
	inventoryValueObject:Insert(nil, toolName, dataToInsert)

	dataToInsert.Quantity = typeof(inventoryValueObject:Get()[toolName]) == "table"
			and inventoryValueObject:Get()[toolName].Quantity
		or 1

	self.Client.toolAdded:Fire(player, dataToInsert)
	self.InventoryChanged:Fire(player, inventoryValueObject:Get())

	if self.Utility:ToolExistsInPlayerOrCharacter(player, toolName) then
		return
	end

	local tool = self.Utility:CreateTool(toolName, handler)
	tool.Parent = player.Backpack
	return tool
end

function InventoryService:RemovePlayerTools(player: Player)
	local inventoryValueObject = self:GetPlayerInventoryValueObject(player)
	return inventoryValueObject:Clear() and self.Utility:DestroyPlayerTools(player)
end

function InventoryService:LoadTools(player: Player)
	local function load()
		local playerInventory = self:GetPlayerInventoryValueObject(player):Get()

		for toolName: string, data: {
			Quantity: number,
			Handler: string,
		} in pairs(playerInventory) do
			local tool = self.Utility:CreateTool(toolName, data.Handler)
			tool.Parent = player.Backpack
		end
	end

	-- Reload Tools on CharacterAdded Event
	if typeof(player.Character) == "Instance" then
		load()
	end

	--
	self.Connections[player] = {}
	table.insert(self.Connections[player], player.CharacterAdded:Connect(load))
end

function InventoryService:Disconnect(player: Player)
	assert(typeof(player) == "Instance" and player:IsA("Player"), "player arg must be a Player")

	if typeof(self.Connections[player]) ~= "table" then
		return
	end

	for _, connection: RBXScriptConnection in pairs(self.Connections[player]) do
		if typeof(connection) ~= "RBXScriptConnection" then
			continue
		end
		connection:Disconnect()
	end
	self.Connections[player] = nil
end

function InventoryService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

function InventoryService:KnitStart() end

return InventoryService
