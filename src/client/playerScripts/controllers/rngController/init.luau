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
	Active = false,
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
	self.AnimationActive = true
	self.RngService
		:Unlock(rngItem)
		:andThen(function(response: { Status: boolean, ItemName: string, ItemAsset: any, Reason: string })
			if response.Status then
				if response.ItemAsset then
					response.ItemAsset:SetAttribute("Pivot", response.ItemAsset:GetPivot())
					response.ItemAsset:PivotTo(CFrame.new(0, -50, 0))
				end

				local callback = Signal.new()
				self.Signals.RevealEffect:Fire(rngItem, response.ItemName, callback)
				callback:Once(function(...)
					self.AnimationActive = false
					self.Active = false
					self:Disconnect(rngItem)

					response.ItemAsset:PivotTo(response.ItemAsset:GetAttribute("Pivot"))
				end)
			else
				self.NotificationController:Push({
					Message = response.Reason,
					Color = Color3.fromRGB(255, 0, 0),
					Sound = "Decline",
				})
			end
		end)
		:catch(warn)
end

function RngController:Connect(rngItem: string)
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self.Signals.OpenUI:Fire(rngItem)

	self.Active = true
end

function RngController:Disconnect(rngItem: string)
	if not rngItem then
		return
	end
	self.Signals.HideUI:Fire(rngItem)

	if not self.AnimationActive then
		self.Active = false
	end
end

-- LifeCycle
function RngController:KnitInit()
	self.RngService = knit.GetService("RngService")
	self.NotificationController = knit.GetController("NotificationController")
end

return RngController
