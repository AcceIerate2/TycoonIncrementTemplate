-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
return function(button)
	local tpType = button:GetAttribute("TpType")
	local cFrame = tpType == "CFrame" and button:GetAttribute("CFrame")
		or knit.GetController("PlotController"):GetPlotAsset():WaitForChild("Spawn"):GetPivot()

	local character = Players.LocalPlayer.Character
	if character then
		character:PivotTo(cFrame)
	end
end
