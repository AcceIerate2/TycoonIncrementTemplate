-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local ResourceMultiplierController = knit.CreateController({
	Name = "ResourceMultiplierController",
	Multiplier = 1,
})

-- LifeCycle
function ResourceMultiplierController:KnitInit()
	self.Service = knit.GetService("ResourceMultiplierService")
	self.Multiplier = table.pack(self.Service:GetMultiplier():await())[2]
	self.Service.MultiplierChanged:Connect(function(newMultiplier: number)
		self.Multiplier = newMultiplier
	end)
end

return ResourceMultiplierController
