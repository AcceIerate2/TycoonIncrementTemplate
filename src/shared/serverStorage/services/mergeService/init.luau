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
function MergeService:Merge(player: Player, itemOne: any, itemTwo: any, itemThree: any)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local itemType = itemOne:GetAttribute("Type")
	if itemTwo:GetAttribute("Type") ~= itemType or itemThree:GetAttribute("Type") ~= itemType then
		return false
	end

	local index = table.find(itemConfig.Order, itemType)
	local newItemIndex = index and index + 1
	local newItemType = newItemIndex and itemConfig.Order[newItemIndex]

	if not newItemType then
		return false
	end

	self.PlotService:RemoveItem(player, itemOne.Name)
	self.PlotService:RemoveItem(player, itemTwo.Name)
	self.PlotService:RemoveItem(player, itemThree.Name)

	self.PlotService:PlaceItem(player, newItemType)

	return true
end

function MergeService:MergeAll(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	local mergedSomething = true

	while mergedSomething do
		mergedSomething = false

		local sortedItems = {}

		for _, placedItem: any in ipairs(plotAsset.PlacedItems:GetChildren()) do
			local itemType = placedItem:GetAttribute("Type")

			if itemType then
				sortedItems[itemType] = sortedItems[itemType] or {}
				table.insert(sortedItems[itemType], placedItem)
			end
		end

		for _, placedItems in pairs(sortedItems) do
			local itemIndex = 1

			while itemIndex + 2 <= #placedItems do
				local merged =
					self:Merge(player, placedItems[itemIndex], placedItems[itemIndex + 1], placedItems[itemIndex + 2])

				if merged then
					mergedSomething = true
				end

				itemIndex += 3
			end
		end

		if mergedSomething then
			self.PlotService:SortItems(player)
			self.PlotService:RemoveUnnecessaryStands(player)
		end
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
