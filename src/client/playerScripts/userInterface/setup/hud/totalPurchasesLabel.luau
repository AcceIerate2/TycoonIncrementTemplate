local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knit = require(ReplicatedStorage.src.Packages.knit)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local TotalPurchasesLabel = {}

function TotalPurchasesLabel:Init(player)
	self.PurchasesLabel = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Purchases")
	self.DataController = knit.GetController("DataController")

	local function update()
		self.PurchasesLabel.Text = `Total Purchases: {NumberShortner(self.DataController:GetValue("Purchases"))}`
	end

	update()
	self.DataController:GetValueChangedSignal("Purchases"):Connect(function()
		update()
	end)
end

return TotalPurchasesLabel
