-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local UIHighlighterController = knit.CreateController({
	Name = "UIHighlighterController",
	Draw = Signal.new(),
	Destroy = Signal.new(),
})

function UIHighlighterController:draw(
	config: {
		AbsoluteSize: Vector2,
		AbsolutePosition: Vector2,
		Padding: number?,
	},
	returnDisconnectMethod: boolean?
)
	self.Draw:Fire(config)

	if not returnDisconnectMethod then
		return
	end

	return {
		Disconnect = function()
			UIHighlighterController:destroy()
		end,
	}
end

function UIHighlighterController:destroy()
	self.Destroy:Fire()
end

function UIHighlighterController:KnitInit() end

return UIHighlighterController
