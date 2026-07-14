-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-->
local ResourcesLabel = {}

function ResourcesLabel:update(number)
	self.Label.Text = `{NumberShortner(number)}`
end

function ResourcesLabel:Init(player: Player)
	self.DataController = knit.GetController("DataController")
	self.Label = player.PlayerGui:WaitForChild("Hud"):WaitForChild("Resources")
	self:update(self.DataController:GetValue("Resources"))
	self.DataController:GetValueChangedSignal("Resources"):Connect(function(newValue)
		self:update(newValue)
	end)
end

return ResourcesLabel
