-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config Modules
local offlineResourcesConfig = require(ReplicatedStorage.src.GameConfiguration.General.offlineResourcesConfig)

-- Constants
local offlineAsset = ReplicatedStorage.Assets.Offline.Asset

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local OfflineResourceService = knit.CreateService({
	Name = "OfflineResourceService",
	OfflineRewardToClaim = {},
	Assets = {},
	Connections = {},
})

-- Public Methods
function OfflineResourceService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local joinedBefore = self.DataService:GetValue(player, "JoinedBefore")
	if not joinedBefore then
		return
	end

	local lastSeen = self.DataService:GetValue(player, "LastSeen")
	local now = os.time()

	local offlineSeconds = math.clamp(now - (lastSeen or now), 0, offlineResourcesConfig.MaxSeconds)
	local totalOutput = self.ResourceService:GetResourcesOutput(player)

	local offlineResourcesReward = (totalOutput * offlineSeconds) * offlineResourcesConfig.Multiplier
	if offlineResourcesReward < 1 then
		return
	end

	self.OfflineRewardToClaim[player] = offlineResourcesReward
	self.Connections[player] = {}

	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	if plotAsset then
		local newAsset = offlineAsset:Clone()
		newAsset:PivotTo(plotAsset.Buttons.OfflineResources:GetPivot())
		newAsset.PrimaryPart.Gui.Enabled = true
		newAsset.PrimaryPart.Gui.Cash.Text = `+ ${NumberShortner(offlineResourcesReward)}`
		newAsset.Parent = plotAsset.Buttons.OfflineResources
		self.Assets[player] = newAsset

		local debounce = false
		table.insert(
			self.Connections[player],
			plotAsset.Buttons.OfflineResources.Touched:Connect(function(partThatTouched: BasePart)
				local playerThatTouched = Players:GetPlayerFromCharacter(partOfCharacter(partThatTouched))
				if not playerThatTouched or debounce then
					return
				end

				debounce = true
				task.delay(1, function()
					debounce = false
				end)

				local resourcesVO = self.DataService:GetValueObject(player, "Resources")
				resourcesVO:Set(resourcesVO:Get() + offlineResourcesReward)
				self:Disconnect(player)
			end)
		)
	end

	return {
		Function = self.Disconnect,
		Args = { self, player },
	}
end

function OfflineResourceService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.OfflineRewardToClaim[player] = nil

	-- Destroy Asset
	if typeof(self.Assets[player]) == "Instance" then
		self.Assets[player]:Destroy()
		self.Assets[player] = nil
	end

	-- Disconnect Connections
	for _, connection in pairs(self.Connections[player] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self.Connections[player] = nil
end

-- LifeCycle
function OfflineResourceService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.ResourceService = knit.GetService("ResourceService")
	self.PlotService = knit.GetService("PlotService")
end

return OfflineResourceService
