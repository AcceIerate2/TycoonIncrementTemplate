-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local BuyItemService = knit.CreateService({
	Name = "BuyItemService",
	Connections = {},
})

-- Public Methods
function BuyItemService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	if not plotAsset then
		return
	end

	local purchases = self.DataService:GetValueObject(player, "Purchases")
	local function update()
		local cost = itemConfig.GetCost(purchases:Get())
		plotAsset.Buttons["Buy1"].Gui.Enabled = true
		plotAsset.Buttons["Buy1"].Gui.Cost.Text = `${NumberShortner(cost)}`

		plotAsset.Buttons["Buy5"].Gui.Enabled = true
		plotAsset.Buttons["Buy5"].Gui.Cost.Text = `${NumberShortner(cost * 5)}`

		plotAsset.Buttons["Buy25"].Gui.Enabled = true
		plotAsset.Buttons["Buy25"].Gui.Cost.Text = `${NumberShortner(cost * 25)}`

		plotAsset.Buttons["Buy100"].Gui.Enabled = true
		plotAsset.Buttons["Buy100"].Gui.Cost.Text = `${NumberShortner(cost * 100)}`
	end

	update()

	self.Connections[player] = {}
	table.insert(self.Connections[player], purchases.Changed:Connect(update))
end

function BuyItemService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	-- Reset Gui
	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	if plotAsset then
		plotAsset.Buttons["Buy1"].Gui.Enabled = false
		plotAsset.Buttons["Buy5"].Gui.Enabled = false
		plotAsset.Buttons["Buy25"].Gui.Enabled = false
		plotAsset.Buttons["Buy100"].Gui.Enabled = false
	end

	-- Disconnect Connections
	for _, connection: RBXScriptConnection in pairs(self.Connections[player] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self.Connections[player] = nil
end

-- LifeCycle
function BuyItemService:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self.DataService = knit.GetService("DataService")
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
