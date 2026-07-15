-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)

-- Constants
local ItemAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items")

-- Helper Functions
local function getItemAsset(itemName: string)
	return ItemAssets:WaitForChild(itemName, 3) and ItemAssets:WaitForChild(itemName):Clone()
end

-->
local IndexPanel = {
	Cards = {},
}

function IndexPanel:createCard(itemName: string, tier: number)
	local newCard = self.CardTemplate:Clone()

	newCard:WaitForChild("Tier").Text = `Tier {tier}`
	local viewportFrame = newCard:WaitForChild("ViewportFrame")
	viewportHandler.Setup(viewportFrame, getItemAsset(itemName), {
		Padding = 2,
	})

	newCard.Visible = true
	newCard.LayoutOrder = tier
	newCard.Parent = self.Container
	self.Cards[itemName] = newCard

	viewportFrame.ImageColor3 = self.DataController:GetValue("Index")[itemName] and Color3.fromRGB(255, 255, 255)
		or Color3.fromRGB(0, 0, 0)
	newCard:WaitForChild("Tier").Visible = self.DataController:GetValue("Index")[itemName] ~= nil
end

function IndexPanel:Init(player: Player)
	self.Panel = player.PlayerGui:WaitForChild("Panels"):WaitForChild("Index")
	self.Container = self.Panel:WaitForChild("Body"):WaitForChild("ScrollingFrame")
	self.CardTemplate = self.Container:WaitForChild("Template")
	self.CardTemplate.Visible = false

	self.DataController = knit.GetController("DataController")
	for tier: number, itemName: string in ipairs(itemConfig.Order) do
		self:createCard(itemName, tier)
	end

	self.IndexController = knit.GetController("IndexController")
	self.IndexController.Signals.ItemAdded:Connect(function(itemName: string)
		local card = self.Cards[itemName]
		if card then
			card:WaitForChild("ViewportFrame").ImageColor3 = Color3.fromRGB(255, 255, 255)
			card:WaitForChild("Tier").Visible = true
		end
	end)
end

return IndexPanel
