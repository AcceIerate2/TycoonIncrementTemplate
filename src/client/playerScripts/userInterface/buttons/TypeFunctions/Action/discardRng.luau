local ReplicatedStorage = game:GetService("ReplicatedStorage")
local knit = require(ReplicatedStorage.src.Packages.knit)
return function(button)
	local rngItem = button:GetAttribute("Rng")
	knit.GetController("RngController"):Discard(rngItem)
end
