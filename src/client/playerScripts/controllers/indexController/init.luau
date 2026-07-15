-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local IndexController = knit.CreateController({
	Name = "IndexController",
	Signals = {
		ItemAdded = Signal.new(),
	},
})

-- LifeCycle
function IndexController:KnitInit()
	self.IndexService = knit.GetService("IndexService")
end

function IndexController:KnitStart()
	self.IndexService.ItemAdded:Connect(function(itemAdded: string)
		self.Signals.ItemAdded:Fire(itemAdded)
	end)
end

return IndexController
