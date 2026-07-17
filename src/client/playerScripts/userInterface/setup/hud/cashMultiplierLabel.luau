-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local CashMultiplierLabel = {}

function CashMultiplierLabel:Init(player: Player)
	self.Label = player.PlayerGui:WaitForChild("Hud"):WaitForChild("CashMultiplierLabel")
	self.DataController = knit.GetController("DataController")

	local function update()
		self.Label.Text = `X{self.DataController:GetValue("CashMultiplier")} All Cash`
	end

	update()
	self.DataController:GetValueChangedSignal("CashMultiplier"):Connect(update)
end

return CashMultiplierLabel
