-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

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
end

function RngService:Unlock(player: Player, rngItem: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
end

-- LifeCycle
function RngService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
end

return RngService
