-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local upgradesConfig = require(ReplicatedStorage.src.GameConfiguration.General.upgradesConfig)

-->
local upgradeUI = {}

function upgradeUI:Init()
	self.DataController = knit.GetController("DataController")
	self.MonetizationController = knit.GetController("MonetizationController")
	self.PlotController = knit.GetController("PlotController")

	local content = self.PlotController
		:GetPlotAsset()
		:WaitForChild("UI")
		:WaitForChild("UpgradeUI")
		:WaitForChild("SurfaceGui")
		:WaitForChild("Content")

	local function update()
		task.spawn(function()
			local doubleOreBtn = content:WaitForChild("DoubleOre")
			doubleOreBtn:SetAttribute("Id", upgradesConfig.DoubleOre.ProductId)
			doubleOreBtn:WaitForChild("Price").Text = self.DataController:GetValue("DoubleOre") and "Owned"
				or `{self.MonetizationController:getMonetizationItemInfo(
					"GamePass",
					upgradesConfig.DoubleOre.ProductId
				).PriceInRobux}`
		end)

		task.spawn(function()
			local autoMoneyBtn = content:WaitForChild("AutoMoney")
			autoMoneyBtn:SetAttribute("Id", upgradesConfig.AutoMoney.ProductId)
			autoMoneyBtn:WaitForChild("Price").Text = self.DataController:GetValue("AutoMoney") and "Owned"
				or `{self.MonetizationController:getMonetizationItemInfo(
					"GamePass",
					upgradesConfig.AutoMoney.ProductId
				).PriceInRobux}`
		end)

		task.spawn(function()
			local autoLootBtn = content:WaitForChild("AutoLoot")
			autoLootBtn:SetAttribute("Id", upgradesConfig.AutoLoot.ProductId)
			autoLootBtn:WaitForChild("Price").Text = self.DataController:GetValue("AutoLoot") and "Owned"
				or `{self.MonetizationController:getMonetizationItemInfo(
					"GamePass",
					upgradesConfig.AutoLoot.ProductId
				).PriceInRobux}`
		end)
	end

	update()
	self.DataController:GetValueChangedSignal("DoubleOre"):Connect(update)
	self.DataController:GetValueChangedSignal("AutoMoney"):Connect(update)
	self.DataController:GetValueChangedSignal("AutoLoot"):Connect(update)
end

return upgradeUI
