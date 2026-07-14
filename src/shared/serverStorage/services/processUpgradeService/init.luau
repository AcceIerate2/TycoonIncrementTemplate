-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Config Modules
local processUpgradeConfig = require(ReplicatedStorage.src.GameConfiguration.General.processUpgradeConfig)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local ProcessUpgradeService = knit.CreateService({
	Name = "ProcessUpgradeService",
	Connections = {},
})

-- Public Methods
function ProcessUpgradeService:Upgrade(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	local processUpgradeLevelVO = self.DataService:GetValueObject(player, "ProcessUpgradeLevel")
	local ProcessIncrementVO = self.DataService:GetValueObject(player, "ProcessIncrement")

	local currentLevel = processUpgradeLevelVO:Get()
	local nextLevel = currentLevel + 1

	local cost = processUpgradeConfig.GetCost(nextLevel)
	local newProcessIncrement = processUpgradeConfig.GetIncrement(nextLevel)
	if not self.CashService:canAfford(player, cost) then
		self.NotificationService:Push(player, {
			Message = `You need ${NumberShortner(cost - self.DataService:GetValue(player, "Cash"))} more!`,
			Color = Color3.fromRGB(255, 0, 0),
			Sound = "Decline",
		})
		return
	end

	self.CashService:manipulatePlayerCash(player, -cost, "Addition")
	ProcessIncrementVO:Set(newProcessIncrement)
	processUpgradeLevelVO:Set(nextLevel)
end

function ProcessUpgradeService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	self.Connections[player] = {}
	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	if not plotAsset then
		return
	end

	local debounce = false
	table.insert(
		self.Connections[player],
		plotAsset.Buttons.ConversionRateUpgrader.Touched:Connect(function(partThatTouched: BasePart)
			local player = Players:GetPlayerFromCharacter(partOfCharacter(partThatTouched))
			if not player or debounce then
				return
			end

			debounce = true
			task.delay(1, function()
				debounce = false
			end)

			self:Upgrade(player)
		end)
	)

	return {
		Function = self.Disconnect,
		Args = { self, player },
	}
end

function ProcessUpgradeService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	-- Disconnect Connections
	for _, connection: RBXScriptConnection in pairs(self.Connections[player] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self.Connections[player] = nil
end

-- LifeCycle
function ProcessUpgradeService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.NotificationService = knit.GetService("NotificationService")
	self.PlotService = knit.GetService("PlotService")
end

return ProcessUpgradeService
