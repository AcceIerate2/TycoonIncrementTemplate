-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local cashMultiplierConfig = require(ReplicatedStorage.src.GameConfiguration.General.cashMultiplierConfig)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local cashProductsConfig = require(ReplicatedStorage.src.GameConfiguration.General.cashProductsConfig)

-->
local ProductIds = {}

-- Cash Products
ProductIds[cashProductsConfig[1]] = function(player: Player)
	knit.GetService("DataService"):GetValueObject(player, "Cash"):Set(
		knit.GetService("DataService"):GetValue(player, "Cash")
			+ knit.GetService("CashProductService"):GetCashToGive(player, 1)
	)
	return true
end

ProductIds[cashProductsConfig[2]] = function(player: Player)
	knit.GetService("DataService"):GetValueObject(player, "Cash"):Set(
		knit.GetService("DataService"):GetValue(player, "Cash")
			+ knit.GetService("CashProductService"):GetCashToGive(player, 2)
	)
	return true
end

ProductIds[cashProductsConfig[3]] = function(player: Player)
	knit.GetService("DataService"):GetValueObject(player, "Cash"):Set(
		knit.GetService("DataService"):GetValue(player, "Cash")
			+ knit.GetService("CashProductService"):GetCashToGive(player, 3)
	)
	return true
end

-- Cash Multiplier Products
for _, config: { ProductId: number } in pairs(cashMultiplierConfig) do
	ProductIds[config.ProductId] = function(player: Player)
		local cashMultiplierIndexVO = knit.GetService("DataService"):GetValueObject(player, "CashMultiplierIndex")
		local cashMultiplierVO = knit.GetService("DataService"):GetValueObject(player, "CashMultiplier")
		cashMultiplierVO:Set(cashMultiplierConfig[cashMultiplierIndexVO:Get()].Multiplier)
		cashMultiplierIndexVO:Set(cashMultiplierIndexVO:Get() + 1)
		return true
	end
end

return ProductIds
