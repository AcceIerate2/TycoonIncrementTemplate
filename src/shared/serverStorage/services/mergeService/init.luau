-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Helper Functions
local function isPlayer(player: Player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local MergeService = knit.CreateService({
	Name = "MergeService",
})

-- Public Methods
function MergeService:Merge(player: Player, itemOne: any, itemTwo: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local index = table.find(itemConfig.Order, itemOne.Name:split("_")[1])
	local newItemIndex = index and index + 1
	if not newItemIndex or not itemConfig.Order[newItemIndex] then
		return false
	end

	self.PlotService:RemoveItem(player, itemOne.Name)
	self.PlotService:RemoveItem(player, itemTwo.Name)
	self.PlotService:PlaceItem(player, itemConfig.Order[newItemIndex])
	return true
end

function MergeService:MergeAll(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	local mergedSomething = true

	while mergedSomething do
		mergedSomething = false

		local sortedItems = {}
		for _, placedItem: any in pairs(plotAsset.PlacedItems:GetChildren()) do
			local itemType = placedItem:GetAttribute("Type")
			if not sortedItems[itemType] then
				sortedItems[itemType] = {}
			end

			sortedItems[itemType][placedItem] = true
		end

		for itemType: string, placedItems in pairs(sortedItems) do
			local lastPlacedItem
			for placedItem: any, _ in pairs(placedItems) do
				if lastPlacedItem then
					local merged = self:Merge(player, lastPlacedItem, placedItem)
					if merged then
						mergedSomething = true
						lastPlacedItem = nil
						continue
					end
				end
				lastPlacedItem = placedItem
			end
		end

		self.PlotService:SortItems(player)
		self.PlotService:RemoveUnnecessaryStands(player)
	end
end

-- LifeCycle
function MergeService:KnitInit()
	self.PlotService = knit.GetService("PlotService")
end

function MergeService:KnitStart()
	for _, part: BasePart in pairs(CollectionService:GetTagged("MergePart")) do
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

					self:MergeAll(player)
				end
			end
		end)
	end
end

return MergeService
