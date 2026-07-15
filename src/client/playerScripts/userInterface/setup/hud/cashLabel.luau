-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local CashLabel = {}

function CashLabel:Init(player: Player)
	self.Cash = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Cash")
	self.DataController = knit.GetController("DataController")

	local function update(cashValue: number)
		self.Cash.Text = `${NumberShortner(cashValue)}`
	end

	update(self.DataController:GetValue("Cash"))
	self.DataController:GetValueChangedSignal("Cash"):Connect(function(newValue: number)
		update(newValue)
	end)
end

return CashLabel
