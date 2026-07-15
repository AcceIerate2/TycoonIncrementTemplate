-- Roblox Services
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local AvatarHeadshot = require(ReplicatedStorage.src.utility.AvatarHeadshot)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)

-- Constants
local Assets = ReplicatedStorage.Assets
local Items = Assets.Items
local StandTemplate = Assets.PlotAssets.StandTemplate

-- Local Types
type PlotState = {
	Owner: Player?,
	Taken: boolean,
	Asset: any,
}

-- Helper Functions
local function getItemAsset(itemName: string)
	return Items:FindFirstChild(itemName) and Items:FindFirstChild(itemName):Clone()
end

-->
local PlotService = knit.CreateService({
	Name = "PlotService",
	PlotStates = {},
	Client = {},
})

-- Client Exposed Methods
function PlotService.Client:GetPlotAsset(player: Player)
	return self.Server:GetPlayerPlotAsset(player)
end

-- Private Methods
function PlotService:getAvailablePlot(): PlotState?
	for plotAsset, plotState: PlotState in pairs(self.PlotStates) do
		if plotState.Taken == false and not plotState.Owner then
			return plotState
		end
	end
	return
end

function PlotService:getAvailableSlotIndex(player: Player): number
	local takenSlots = self.DataService:GetValue(player, "TakenSlots")
	local slotIndex = 1

	while takenSlots[slotIndex] ~= nil do
		slotIndex += 1
	end

	return slotIndex
end

function PlotService:getSlotSpawn(player: Player, slotIndex: number, standIndex: number)
	local plotAsset = self:GetPlayerPlotAsset(player)
	local standAsset = plotAsset.Stands:FindFirstChild(`Stand_{standIndex}`)
	return standAsset.SlotSpawns:FindFirstChild(((slotIndex - 1) % 10) + 1)
end

function PlotService:getSlotIndexByPlacedItemId(player: Player, referenceId: string): number?
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	assert(TypeCheck.string(referenceId), "referenceId arg must be a string")
	for slotIndex: number, itemId: string in pairs(self.DataService:GetValue(player, "TakenSlots")) do
		if itemId == referenceId then
			return slotIndex
		end
	end
	return
end

function PlotService:place(player: Player, referenceId: string, slotIndex: number?)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	assert(TypeCheck.string(referenceId), "referenceId arg must be a string")

	local plotAsset = self:GetPlayerPlotAsset(player)
	if not plotAsset then
		return
	end

	local newSlotIndex = slotIndex or self:getAvailableSlotIndex(player)
	local standIndex = math.ceil(newSlotIndex / 10)
	while not plotAsset.Stands:FindFirstChild(`Stand_{standIndex}`) do
		self:AddStand(player, true)
		task.wait()
	end

	local itemName = referenceId:split("_")[1]
	local slotSpawn = self:getSlotSpawn(player, newSlotIndex, standIndex)
	local itemAsset = getItemAsset(itemName)
	itemAsset:SetAttribute("Type", itemName)
	itemAsset.Name = referenceId
	itemAsset:PivotTo(slotSpawn:GetPivot())
	itemAsset.Parent = plotAsset.PlacedItems

	self.ResourceService:ActivateItem(player, itemAsset)
end

-- Public Methods
function PlotService:SortItems(player: Player)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")

	local plotAsset = self:GetPlayerPlotAsset(player)
	local placedItems = plotAsset.PlacedItems:GetChildren()

	table.sort(placedItems, function(itemA, itemB)
		local typeA = itemA:GetAttribute("Type")
		local typeB = itemB:GetAttribute("Type")

		local rankA = table.find(itemConfig.Order, typeA) or 0
		local rankB = table.find(itemConfig.Order, typeB) or 0

		-- Higher index means better because merging uses index + 1.
		if rankA == rankB then
			-- Deterministic ordering when both items are the same tier.
			return itemA.Name < itemB.Name
		end

		return rankA > rankB
	end)

	local sortedSlots = {}

	for slotIndex, itemAsset in ipairs(placedItems) do
		local standIndex = math.ceil(slotIndex / 10)
		local standName = `Stand_{standIndex}`

		while not plotAsset.Stands:FindFirstChild(standName) do
			local previousStandCount = #plotAsset.Stands:GetChildren()

			self:AddStand(player, true)

			if #plotAsset.Stands:GetChildren() == previousStandCount then
				error(`Failed to create {standName}`)
			end
		end

		local slotSpawn = self:getSlotSpawn(player, slotIndex, standIndex)

		itemAsset:PivotTo(slotSpawn:GetPivot())
		sortedSlots[slotIndex] = itemAsset.Name
	end

	self.DataService:GetValueObject(player, "TakenSlots"):Update(function(takenSlots)
		table.clear(takenSlots)
		for slotIndex, referenceId in ipairs(sortedSlots) do
			takenSlots[slotIndex] = referenceId
		end
	end)
end

function PlotService:PurchaseItem(player: Player, amount: number)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	assert(TypeCheck.number(amount), "amount arg must be a number")

	local purchasesVO = self.DataService:GetValueObject(player, "Purchases")

	local cost = itemConfig.GetCost(purchasesVO:Get())
	if not self.CashService:canAfford(player, cost * amount) then
		local cashNeeded = cost - self.DataService:GetValue(player, "Cash")
		return {
			Status = false,
			Reason = `You need <font color="rgb(255,255,255)">${NumberShortner(cashNeeded)}</font> more!`,
		}
	end

	self.CashService:manipulatePlayerCash(player, -cost, "Addition")
	purchasesVO:Set(purchasesVO:Get() + (1 * amount))

	for i = amount, 1, -1 do
		self:PlaceItem(player, "Template")
	end

	if amount == 100 or self:getAvailableSlotIndex(player) >= 100 then
		self.MergeService:MergeAll(player)
	end

	return {
		Status = true,
	}
end

function PlotService:AddStand(player: Player, syncData: boolean)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")

	local plotAsset = self:GetPlayerPlotAsset(player)
	local extraStandsValueObject = self.DataService:GetValueObject(player, "ExtraStands")

	local lastStandIndex = 0
	for _, standAsset in ipairs(plotAsset.Stands:GetChildren()) do
		local standIndex = tonumber(standAsset.Name:match("^Stand_(%d+)$"))
		if standIndex and standIndex > lastStandIndex then
			lastStandIndex = standIndex
		end
	end

	local lastStand = plotAsset.Stands:FindFirstChild(`Stand_{lastStandIndex}`)
	if not lastStand then
		warn("Couldn't find last stand")
		return
	end

	local newStand = StandTemplate:Clone()
	newStand.Name = `Stand_{lastStandIndex + 1}`
	newStand:PivotTo(lastStand:GetPivot() * CFrame.new(0, lastStand:GetExtentsSize().Y / 2, 0) * CFrame.new(0, 10, 0))
	newStand.Parent = plotAsset.Stands

	if syncData then
		extraStandsValueObject:Set(lastStandIndex)
	end
end

function PlotService:RemoveUnnecessaryStands(player: Player)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	local plotAsset = self:GetPlayerPlotAsset(player)

	local itemCount = self:getAvailableSlotIndex(player) - 1
	local requiredStands = math.max(1, math.ceil(itemCount / 10))

	for _, stand in pairs(plotAsset.Stands:GetChildren()) do
		local standIndex = tonumber(stand.Name:split("_")[2])
		if TypeCheck.number(standIndex) and standIndex > requiredStands then
			stand:Destroy()
		end
	end

	local extraStandsValueObject = self.DataService:GetValueObject(player, "ExtraStands")
	extraStandsValueObject:Set(requiredStands - 1)
end

function PlotService:PlaceItem(player: Player, itemName: string)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	assert(typeof(itemName) == "string", "itemName arg must be a string")

	itemName = itemName:split("_")[1]
	local referenceId = `{itemName}_{HttpService:GenerateGUID(false)}`
	local newSlotIndex = self:getAvailableSlotIndex(player)

	self.DataService:GetValueObject(player, "TakenSlots"):Update(function(_table)
		_table[newSlotIndex] = referenceId
	end)

	self.IndexService:AddToIndex(player, itemName)
	self:place(player, referenceId, newSlotIndex)
end

function PlotService:RemoveItem(player: Player, referenceId: string)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	local slotIndex = self:getSlotIndexByPlacedItemId(player, referenceId)
	if not slotIndex then
		return
	end

	local plotAsset = self:GetPlayerPlotAsset(player)
	local itemAsset = plotAsset.PlacedItems:FindFirstChild(referenceId)
	self.ResourceService:DeactivateItem(player, itemAsset)

	if itemAsset then
		itemAsset:Destroy()
	end

	self.DataService:GetValueObject(player, "TakenSlots"):Update(function(_table)
		table.remove(_table, slotIndex)
	end)
end

function PlotService:GetPlayerPlotAsset(player: Player)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	for _, plotState: PlotState in pairs(self.PlotStates) do
		if plotState.Owner == player then
			return plotState.Asset
		end
	end
	return
end

function PlotService:Connect(player: Player)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	local plotState: PlotState = self:getAvailablePlot(player)
	if not plotState then
		player:Kick("Couldn't find an available Plot")
		return
	end

	plotState.Asset.Owner.Value = player
	plotState.Owner = player
	plotState.Taken = true

	plotState.Asset.Sign.SurfaceGui.ImageLabel.Image = AvatarHeadshot(player)
	plotState.Asset.Sign.SurfaceGui.TextLabel.Text = `{player.Name}`

	for slotIndex: number, referenceId: string in pairs(self.DataService:GetValue(player, "TakenSlots")) do
		self:place(player, referenceId, slotIndex)
	end
end

function PlotService:Disconnect(player: Player)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player Instance")
	local plotAsset = self:GetPlayerPlotAsset(player)
	local plotState: PlotState = self.PlotStates[plotAsset]
	plotAsset.Sign.SurfaceGui.ImageLabel.Image = ""
	plotAsset.Sign.SurfaceGui.TextLabel.Text = `N/A`
	plotState.Asset.Owner.Value = nil
	plotState.Owner = nil
	plotState.Taken = false
end

-- LifeCycle
function PlotService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.MergeService = knit.GetService("MergeService")
	self.ResourceService = knit.GetService("ResourceService")
	self.IndexService = knit.GetService("IndexService")
end

function PlotService:KnitStart()
	for _, plotAsset in pairs(workspace.src.Plots:GetChildren()) do
		self.PlotStates[plotAsset] = {
			Owner = nil,
			Taken = false,
			Asset = plotAsset,
		}
	end
end

return PlotService
