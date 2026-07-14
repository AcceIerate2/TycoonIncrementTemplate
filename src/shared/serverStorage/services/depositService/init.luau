-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local partOfCharacter = require(ReplicatedStorage.src.utility.partOfCharacter)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local DepositService = knit.CreateService({
	Name = "DepositService",
	Connections = {},
})

-- Private Methods
function DepositService:depositResources(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local resources = self.DataService:GetValueObject(player, "Resources")
	local unprocessedResources = self.DataService:GetValueObject(player, "UnprocessedResources")
	unprocessedResources:Set(unprocessedResources:Get() + resources:Get())
	resources:Set(0)
end

-- Public Methods
function DepositService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	if not plotAsset then
		return
	end

	local debounce = false

	self.Connections[player] = {}
	table.insert(
		self.Connections[player],
		plotAsset.Buttons.Deposit.Touched:Connect(function(partThatTouched: BasePart)
			local playerThatTouched = Players:GetPlayerFromCharacter(partOfCharacter(partThatTouched))
			if playerThatTouched then
				if debounce then
					return
				end

				debounce = true
				task.delay(1, function()
					debounce = false
				end)

				self:depositResources(player)
			end
		end)
	)

	return {
		Function = self.Disconnect,
		Args = { self, player },
	}
end

function DepositService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	for _, connection in pairs(self.Connections[player] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self.Connections[player] = nil
end

-- LifeCycle
function DepositService:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self.DataService = knit.GetService("DataService")
end

return DepositService
