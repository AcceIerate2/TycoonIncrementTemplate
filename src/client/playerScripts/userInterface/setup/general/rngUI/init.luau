-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local rngConfig = require(ReplicatedStorage.src.GameConfiguration.General.rngConfig)
local PlayTween = require(ReplicatedStorage.src.utility.PlayTween)
local viewportHandler = require(ReplicatedStorage.src.utility.viewportHandler)

-->
local RngUI = {}

function RngUI:syncDetails(rngItem: string)
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self.Gui:WaitForChild("Details"):WaitForChild("Cost"):WaitForChild("Cost").Text =
		`${NumberShortner(rngConfig.RngItems[rngItem].Cost)}`

	self.Gui:WaitForChild("Details"):WaitForChild("Details"):WaitForChild("RngName").Text =
		rngConfig.RngItems[rngItem].Name

	self.Gui:WaitForChild("Details"):WaitForChild("Buttons"):WaitForChild("Unlock"):SetAttribute("Rng", rngItem)
	self.Gui:WaitForChild("Details"):WaitForChild("Buttons"):WaitForChild("Discard"):SetAttribute("Rng", rngItem)

	for order: number, config: { Weight: number, ItemName: string } in pairs(rngConfig.RngItems[rngItem].Items) do
		local tierFrame = self.Gui:WaitForChild("Details"):WaitForChild("Details"):WaitForChild("Tier" .. order)
		tierFrame:WaitForChild("Chance").Text = config.Weight .. "%"
		tierFrame:WaitForChild("ItemName").Text = config.ItemName

		local tier = table.find(itemConfig.Order, config.ItemName)
		tierFrame:WaitForChild("Tier").Text = `Tier {tier}`
		tierFrame.LayoutOrder = tier
	end
end

function RngUI:Init(player: Player)
	self.Gui = player.PlayerGui:WaitForChild("Rng")
	self.Gui:WaitForChild("Details").Visible = false

	self.RngController = knit.GetController("RngController")
	self.RngController.Signals.OpenUI:Connect(function(rngItem: string)
		assert(typeof(rngItem) == "string", "rngItem arg must be a string")
		self:syncDetails(rngItem)
		self.Gui:WaitForChild("Details").Visible = true
	end)

	self.RngController.Signals.HideUI:Connect(function(rngItem: string)
		assert(typeof(rngItem) == "string", "rngItem arg must be a string")
		self.Gui:WaitForChild("Details").Visible = false
	end)

	self.RngController.Signals.RevealEffect:Connect(function(rngItem: string, itemName: string, callback)
		self.Gui:WaitForChild("Details").Visible = false
		local revealFrame = self.Gui:WaitForChild("Reveal")
		revealFrame:WaitForChild("ViewportFrameRng").Visible = true
		revealFrame:WaitForChild("ViewportFrameItem").Visible = false
		local rngAsset = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("RngAssets"):WaitForChild(rngItem)
		local itemAsset = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Items"):WaitForChild(itemName)
		viewportHandler.Setup(revealFrame:WaitForChild("ViewportFrameRng"), rngAsset, {
			Padding = 2,
		})

		revealFrame.Visible = true
		revealFrame:WaitForChild("ViewportFrameRng").Size = UDim2.fromScale(0, 0)
		PlayTween(
			revealFrame:WaitForChild("ViewportFrameRng"),
			TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
			{
				Size = UDim2.fromScale(1, 1),
			}
		)

		revealFrame:WaitForChild("ViewportFrameRng").Rotation = -45
		PlayTween(
			revealFrame:WaitForChild("ViewportFrameRng"),
			TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 5, true, 0),
			{
				Rotation = 45,
			}
		).Completed:Wait()

		PlayTween(
			revealFrame:WaitForChild("ViewportFrameRng"),
			TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
			{
				Size = UDim2.fromScale(0, 0),
			}
		).Completed:Once(function(a0: Enum.PlaybackState)
			revealFrame:WaitForChild("ViewportFrameRng").Visible = false
		end)

		revealFrame:WaitForChild("ViewportFrameItem").Visible = true
		revealFrame:WaitForChild("ViewportFrameItem").Size = UDim2.fromScale(0, 0)
		viewportHandler.Setup(revealFrame:WaitForChild("ViewportFrameItem"), itemAsset, { Padding = 2 })

		PlayTween(
			revealFrame:WaitForChild("ViewportFrameItem"),
			TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
			{
				Size = UDim2.fromScale(1, 1),
			}
		)

		task.delay(1, function()
			PlayTween(
				revealFrame:WaitForChild("ViewportFrameItem"),
				TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
				{
					Size = UDim2.fromScale(0, 0),
				}
			).Completed:Once(function()
				revealFrame:WaitForChild("ViewportFrameItem").Visible = false
				revealFrame.Visible = false

				if callback then
					callback:Fire()
				end
			end)
		end)
	end)
end

return RngUI
