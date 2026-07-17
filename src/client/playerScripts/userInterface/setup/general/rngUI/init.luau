-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local rngConfig = require(ReplicatedStorage.src.GameConfiguration.General.rngConfig)

-->
local RngUI = {}

function RngUI:syncDetails(rngItem: string)
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self.Gui:WaitForChild("Details"):WaitForChild("Cost"):WaitForChild("Cost").Text =
		`${NumberShortner(rngConfig.RngItems[rngItem].Cost)}`

	self.Gui:WaitForChild("Details"):WaitForChild("Details"):WaitForChild("RngName").Text =
		rngConfig.RngItems[rngItem].Name

	self.Gui:WaitForChild("Details"):WaitForChild("Buttons"):WaitForChild("Unlock"):SetAttribute("Rng", rngItem)
	self.Gui:WaitForChild("Details"):WaitForChild("Buttons"):WaitForChild("Discard"):SetAttribute("Rng", rngItem)

	for order: number, config: { Weight: number, ItemName: string } in pairs(rngConfig.RngItems[rngItem].Items) do
		local tierFrame = self.Gui:WaitForChild("Details"):WaitForChild("Details"):WaitForChild("Tier" .. order)
		tierFrame:WaitForChild("Chance").Text = config.Weight .. "%"
		tierFrame:WaitForChild("ItemName").Text = config.ItemName

		local tier = table.find(itemConfig.Order, config.ItemName)
		tierFrame:WaitForChild("Tier").Text = `Tier {tier}`
		tierFrame.LayoutOrder = tier
	end
end

function RngUI:Init(player: Player)
	self.Gui = player.PlayerGui:WaitForChild("Rng")
	self.Gui:WaitForChild("Details").Visible = false

	self.RngController = knit.GetController("RngController")
	self.RngController.Signals.OpenUI:Connect(function(rngItem: string)
		assert(typeof(rngItem) == "string", "rngItem arg must be a string")
		self:syncDetails(rngItem)
		self.Gui:WaitForChild("Details").Visible = true
	end)

	self.RngController.Signals.HideUI:Connect(function(rngItem: string)
		assert(typeof(rngItem) == "string", "rngItem arg must be a string")
		self.Gui:WaitForChild("Details").Visible = false
	end)

	self.RngController.Signals.RevealEffect:Connect(function() end)
end

return RngUI
