-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local cashProductsConfig = require(ReplicatedStorage.src.GameConfiguration.General.cashProductsConfig)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local CashProducts = {}

function CashProducts:Init(player: Player)
	self.DataController = knit.GetController("DataController")
	self.MonetizationController = knit.GetController("MonetizationController")

	local function getCash(cashId: number)
		local playerCash = self.DataController:GetValue("Cash")
		return NumberShortner(playerCash * (50 ^ math.clamp(cashId, 1, 3)))
	end

	self.CashProducts = player.PlayerGui:WaitForChild("Hud"):WaitForChild("CashProducts")
	local function update()
		task.spawn(function()
			self.CashProducts:WaitForChild("1"):WaitForChild("TextLabel").Text = `+ ${getCash(1)}`
			self.CashProducts:WaitForChild("1"):WaitForChild("Price").Text =
				`{self.MonetizationController:getMonetizationItemInfo("Product", cashProductsConfig[1]).PriceInRobux}`
		end)

		task.spawn(function()
			self.CashProducts:WaitForChild("2"):WaitForChild("TextLabel").Text = `+ ${getCash(2)}`
			self.CashProducts:WaitForChild("2"):WaitForChild("Price").Text =
				`{self.MonetizationController:getMonetizationItemInfo("Product", cashProductsConfig[2]).PriceInRobux}`
		end)

		task.spawn(function()
			self.CashProducts:WaitForChild("3"):WaitForChild("TextLabel").Text = `+ ${getCash(3)}`
			self.CashProducts:WaitForChild("3"):WaitForChild("Price").Text =
				`{self.MonetizationController:getMonetizationItemInfo("Product", cashProductsConfig[3]).PriceInRobux}`
		end)
	end

	update()
	self.DataController:GetValueChangedSignal("Cash"):Connect(update)
end

return CashProducts
