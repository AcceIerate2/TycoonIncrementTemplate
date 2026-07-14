-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local PlotController = knit.CreateController({
	Name = "PlotController",
})

-- Private Methods
function PlotController:syncPlotAsset()
	local promiseOk: boolean, plotAsset = self.PlotService:GetPlotAsset():await()
	self.PlotAsset = promiseOk and plotAsset
end

-- Public Methods
function PlotController:GetPlotAsset()
	return self.PlotAsset
end

-- LifeCycle
function PlotController:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self:syncPlotAsset()
end

return PlotController
