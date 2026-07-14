-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local StandService = knit.CreateService({
	Name = "StandService",
})

-- Public Methods
function StandService:AddItem() end

-- LifeCycle
function StandService:KnitInit()
	self.PlotService = knit.GetService("PlotService")
end

return StandService
