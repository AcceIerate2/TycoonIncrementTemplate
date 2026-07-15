-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local CashProductService = knit.CreateService({
	Name = "CashProductService",
})

-- Public Methods
function CashProductService:GetCashToGive(player: Player, cashId: number)
	local playerCash = self.DataService:GetValue(player, "Cash")
	return playerCash * (50 ^ math.clamp(cashId, 1, 3))
end

-- LifeCycle
function CashProductService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return CashProductService
