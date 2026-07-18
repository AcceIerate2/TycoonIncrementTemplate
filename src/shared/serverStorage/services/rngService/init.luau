-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local rngConfig = require(ReplicatedStorage.src.GameConfiguration.General.rngConfig)
local knit = require(ReplicatedStorage.src.Packages.knit)
local rngWeight = require(ReplicatedStorage.src.utility.rngWeight)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local RngService = knit.CreateService({
	Name = "RngService",
	Client = {},
})

-- Client Exposed Methods
function RngService.Client:Discard(player: Player, rngItem: string)
	return self.Server:Discard(player, rngItem)
end

function RngService.Client:Unlock(player: Player, rngItem: string)
	return self.Server:Unlock(player, rngItem)
end

-- Public Methods
function RngService:Discard(player: Player, rngItem: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self.InventoryService:Remove(player, rngItem)
	if self.InventoryService:GetQuantity(player, rngItem) > 0 then
		local tool = player.Backpack:FindFirstChild(rngItem)
		if tool then
			self.InventoryService:EquipTool(player, tool)
		end
	end
end

function RngService:Unlock(player: Player, rngItem: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	local owns = self.InventoryService:GetQuantity(player, rngItem) > 0
	if not owns then
		return {
			Status = false,
			Reason = "You don't own this item!",
		}
	end

	local cost = rngConfig.RngItems[rngItem].Cost
	if not self.CashService:canAfford(player, cost) then
		return {
			Status = false,
			Reason = `You need ${cost - self.DataService:GetValue(player, "Cash")} more!`,
		}
	end

	self.CashService:manipulatePlayerCash(player, -cost, "Addition")

	self.InventoryService:Remove(player, rngItem)
	local itemIndex = rngWeight(rngConfig.RngItems[rngItem].Items)
	local itemName = rngConfig.RngItems[rngItem].Items[itemIndex].ItemName
	local asset = self.PlotService:PlaceItem(player, itemName)

	return {
		Status = true,
		ItemName = itemName,
		ItemAsset = asset,
	}
end

-- LifeCycle
function RngService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
	self.PlotService = knit.GetService("PlotService")
	self.CashService = knit.GetService("CashService")
end

return RngService
