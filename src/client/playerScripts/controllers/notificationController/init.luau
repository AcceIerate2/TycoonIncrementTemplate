-- Roblox  Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-->
local NotificationController = knit.CreateController({
	Name = "NotificationController",

	showNotification = Signal.new(),
	hideNotification = Signal.new(),

	canvasPositionChanged = Signal.new(),
	canvasPositionReset = Signal.new(),

	Notifications = {},
	_nextId = 0,
	Duration = 3,
})

function NotificationController:resetCanvasPosition()
	self.canvasPositionReset:Fire()
end

function NotificationController:mutateCanvasPosition(position: UDim2)
	assert(TypeCheck.UDim2(position), "position arg must be UDim2")
	self.canvasPositionChanged:Fire(position)
end

function NotificationController:Push(notificationData)
	assert(TypeCheck.table(notificationData), "notificationData arg must be a Table")
	if not TypeCheck.string(notificationData.Message) then
		return
	end

	self._nextId += 1
	local id = self._nextId

	self.Notifications[id] = notificationData

	if typeof(notificationData.Sound) == "string" then
		local sound = SoundService:WaitForChild("src")
			:WaitForChild("Sfx")
			:WaitForChild("NotificationSounds")
			:WaitForChild(notificationData.Sound)
		soundHandler:play(sound, {
			PlayOver = true,
			Parent = SoundService,
		})
	end

	self.showNotification:Fire(notificationData, id)

	task.delay(notificationData.Duration or self.Duration, function()
		if self.Notifications[id] == nil then
			return
		end
		self.Notifications[id] = nil
		self.hideNotification:Fire(id)
	end)
end

function NotificationController:KnitInit()
	self.NotificationService = knit.GetService("NotificationService")
end

function NotificationController:KnitStart()
	self.NotificationService.Push:Connect(function(notificationData)
		self:Push(notificationData)
	end)
end

return NotificationController
