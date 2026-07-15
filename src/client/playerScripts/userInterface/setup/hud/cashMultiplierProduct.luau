local ReplicatedStorage = game:GetService("ReplicatedStorage")
local cashMultiplierConfig = require(ReplicatedStorage.src.GameConfiguration.General.cashMultiplierConfig)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local CashMultiplierProduct = {}

function CashMultiplierProduct:Init(player: Player)
	self.Button = player.PlayerGui:WaitForChild("Hud"):WaitForChild("CashMultiplier")
	self.DataController = knit.GetController("DataController")
	self.MonetizationController = knit.GetController("MonetizationController")

	local function update()
		if not cashMultiplierConfig[self.DataController:GetValue("CashMultiplierIndex")] then
			self.Button.Visible = false
			return
		end

		self.Button:SetAttribute(
			"Id",
			cashMultiplierConfig[self.DataController:GetValue("CashMultiplierIndex")].ProductId
		)

		self.Button:WaitForChild("TextLabel").Text =
			`X{cashMultiplierConfig[self.DataController:GetValue("CashMultiplierIndex")].Multiplier} Cash`

		self.Button:WaitForChild("Price").Text = `{self.MonetizationController:getMonetizationItemInfo(
			"Product",
			cashMultiplierConfig[self.DataController:GetValue("CashMultiplierIndex")].ProductId
		).PriceInRobux}`
	end

	task.spawn(update)
	self.DataController:GetValueChangedSignal("CashMultiplierIndex"):Connect(function()
		task.spawn(update)
	end)
end

return CashMultiplierProduct
