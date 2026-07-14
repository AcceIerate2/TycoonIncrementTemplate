-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local NotificationService = knit.CreateService({
	Name = "NotificationService",
	Client = {
		Push = knit.CreateSignal(),
	},
})

-- Public Methods
function NotificationService:Push(player: Player, notificationData: { Message: string, Color: Color3, Sound: string })
	self.Client.Push:Fire(player, notificationData)
end

return NotificationService
