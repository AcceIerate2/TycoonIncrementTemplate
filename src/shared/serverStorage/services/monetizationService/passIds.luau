-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local upgradesConfig = require(ReplicatedStorage.src.GameConfiguration.General.upgradesConfig)

-->
local PassIds = {}

for _type: string, config: { ProductId: number } in pairs(upgradesConfig) do
	PassIds[config.ProductId] = function(player: Player)
		knit.GetService("DataService"):GetValueObject(player, _type):Set(true)
		return true
	end
end

return PassIds
