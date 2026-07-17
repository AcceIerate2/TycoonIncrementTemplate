-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Player = Players.LocalPlayer

-->
local RngController = knit.CreateController({
	Name = "RngController",
	Signals = {
		OpenUI = Signal.new(),
		HideUI = Signal.new(),
		RevealEffect = Signal.new(),
	},
})

-- Public Methods
function RngController:Discard(rngItem: string)
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	if Player.Character then
		local humanoid = Player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end

	self.Signals.HideUI:Fire(rngItem)
	self.RngService:Discard(rngItem):andThen(function() end):catch(warn)
end

function RngController:Open(rngItem: string)
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self.RngService
		:Open(rngItem)
		:andThen(function(response: { Status: boolean, ItemName: string })
			warn(response)
			if response.Status then
				self:RevealEffect(response.ItemName)
			end
		end)
		:catch(warn)
end

function RngController:Connect(rngItem: string)
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self.Signals.OpenUI:Fire(rngItem)
end

function RngController:Disconnect(rngItem: string)
	if not rngItem then
		return
	end
	self.Signals.HideUI:Fire(rngItem)
end

-- LifeCycle
function RngController:KnitInit()
	self.RngService = knit.GetService("RngService")
end

return RngController
