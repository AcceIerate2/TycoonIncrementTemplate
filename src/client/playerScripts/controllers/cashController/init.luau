-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local CashController = knit.CreateController({
	Name = "CashController",
	UpdateUI = Signal.new(),
	Amount = 0,
})

function CashController:syncCash()
	self.Service
		:getCash()
		:andThen(function(response: {
			Amount: number,
			Status: boolean,
		})
			self.Amount = response.Amount
			self.UpdateUI:Fire(response.Status and response.Amount or 0, true)
		end)
		:catch(warn)
end

function CashController:listenToService()
	self.Service = knit.GetService("CashService")
	self.Service.CashChanged:Connect(function(newCash: number, delay: number)
		if not TypeCheck.number(newCash) then
			return
		end
		task.delay(delay or 0, function()
			--[[if newCash > self.Amount then
				self.EffectController:PlayEffect("cashEffect", {})
			end]]

			self.UpdateUI:Fire(newCash, false)
			self.Amount = newCash
		end)
	end)
end

function CashController:KnitInit()
	self.EffectController = knit.GetController("EffectController")
	self:listenToService()
	print("CashController Initiated.")
end

return CashController
