-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
return function(button: GuiButton)
	local purchaseType = button:GetAttribute("PurchaseType")
	if not TypeCheck.string(purchaseType) then
		return
	end

	local id = button:GetAttribute("Id")
	if not TypeCheck.number(id) then
		return
	end

	knit.GetController("MonetizationController"):promptPurchase(purchaseType, id)
end
