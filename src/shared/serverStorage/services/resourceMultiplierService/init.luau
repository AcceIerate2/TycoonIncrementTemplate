-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Constants
local Gui = workspace.src.MultiplierUI.BillboardGui

-- Helper Functions
local function isPlayer(player: Player)
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local ResourceMultiplierService = knit.CreateService({
	Name = "ResourceMultiplierService",
	Multiplier = 1,
	Client = {
		MultiplierChanged = knit.CreateSignal(),
	},
})

-- Client Exposed Methods
function ResourceMultiplierService.Client:GetMultiplier(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	return self.Server.Multiplier
end

-- LifeCycle
function ResourceMultiplierService:KnitStart()
	while true do
		self.Multiplier = math.round(((math.random(50, 200)) / 100) * 10) / 10
		if self.Multiplier == 1 or self.Multiplier == 2 then
			self.Multiplier = `{self.Multiplier}.0`
		end

		self.Client.MultiplierChanged:FireAll(self.Multiplier)

		Gui.MultiplierContainer.Label.RichText = true
		Gui.MultiplierContainer.Label.Text =
			`<font color="rgb(200,200,200)">Resource Multiplier:</font> <font color="#ffffff">{self.Multiplier}x</font>`

		local x = 1 - (self.Multiplier / 2)
		Gui.Scale.Cover.Size = UDim2.fromScale(x, 1)
		Gui.Scale.Arrow.Position = UDim2.fromScale(self.Multiplier / 2, 0)

		for i = 30, 1, -1 do
			Gui.Label.Text = `Next change in {i}`
			task.wait(1)
		end
	end
end

return ResourceMultiplierService
