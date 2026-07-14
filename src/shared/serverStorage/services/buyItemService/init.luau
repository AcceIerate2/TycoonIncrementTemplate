-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-->
local BuyItemService = knit.CreateService({
	Name = "BuyItemService",
})

-- LifeCycle
function BuyItemService:KnitInit()
	self.PlotService = knit.GetService("PlotService")
end

function BuyItemService:KnitStart()
	for _, part: BasePart in pairs(CollectionService:GetTagged("BuyItemPart")) do
		local plotAsset = part.Parent and part.Parent.Parent
		local debounce = false

		part.Touched:Connect(function(partThatTouched: BasePart)
			local player = Players:GetPlayerFromCharacter(partOfCharacter(partThatTouched))
			if player and player == plotAsset.Owner.Value then
				if not debounce then
					debounce = true
					task.delay(1, function()
						debounce = false
					end)

					local amount = part:GetAttribute("Amount")
					if typeof(amount) == "number" then
						self.PlotService:PurchaseItem(player, amount)
					end
				end
			end
		end)
	end
end

return BuyItemService
