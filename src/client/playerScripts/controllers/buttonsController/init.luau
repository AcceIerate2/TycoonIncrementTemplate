-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local ButtonsController = knit.CreateController({
	Name = "ButtonsController",

	IncrementAlertLabel = Signal.new(),
	ClearButtonAlerts = Signal.new(),
	ToggleAction = Signal.new(),
	Link = Signal.new(),
	Unlink = Signal.new(),
	DestroyAndUnlink = Signal.new(),
})

function ButtonsController:incrementButtonAlerts(button, increment)
	self.IncrementAlertLabel:Fire(button, increment)
end

function ButtonsController:clearButtonAlerts(button)
	self.ClearButtonAlerts:Fire(button)
end

function ButtonsController:toggleAction(actionName: string, ...)
	self.ToggleAction:Fire(actionName, ... or {})
end

function ButtonsController:link(button)
	self.Link:Fire(button)
end

function ButtonsController:unlink(button)
	self.Unlink:Fire(button)
end

function ButtonsController:destroy(button)
	self.DestroyAndUnlink:Fire(button)
end

function ButtonsController:KnitInit() end

return ButtonsController
