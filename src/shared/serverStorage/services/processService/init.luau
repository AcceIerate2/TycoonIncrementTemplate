-- Roblox Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
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
local ProcessService = knit.CreateService({
	Name = "ProcessService",
	Connections = {},
})

-- Private Methods
function ProcessService:process(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local processIncrement = self.DataService:GetValue(player, "ProcessIncrement")
	local cashToClaimVO = self.DataService:GetValueObject(player, "CashToClaim")

	local UnprocessedResourcesVO = self.DataService:GetValueObject(player, "UnprocessedResources")
	if UnprocessedResourcesVO:Get() <= 0 then
		return
	end

	local newUnprocessedResources = UnprocessedResourcesVO:Get() - processIncrement
	UnprocessedResourcesVO:Set(math.max(0, newUnprocessedResources))

	local newCashToClaim = cashToClaimVO:Get() + processIncrement
	cashToClaimVO:Set(newCashToClaim)
end

-- Public Methods
function ProcessService:ClaimCash(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local cashToClaimVO = self.DataService:GetValueObject(player, "CashToClaim")
	local playerCashVO = self.DataService:GetValueObject(player, "Cash")

	playerCashVO:Set(playerCashVO:Get() + cashToClaimVO:Get())
	cashToClaimVO:Set(0)
end

function ProcessService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.Connections[player] = {}

	local elapsed = 0
	table.insert(
		self.Connections[player],
		RunService.Heartbeat:Connect(function(deltaTime: number)
			elapsed += deltaTime
			if elapsed < 1 then
				return
			end

			elapsed = 0
			self:process(player)
		end)
	)

	local plotAsset = self.PlotService:GetPlayerPlotAsset(player)
	if plotAsset then
		local debounce = false
		table.insert(
			self.Connections[player],
			plotAsset.Buttons.CashCollector.Touched:Connect(function(partThatTouched: BasePart)
				local playerThatTouched = Players:GetPlayerFromCharacter(partOfCharacter(partThatTouched))
				if not playerThatTouched or debounce then
					return
				end

				debounce = true
				task.delay(1, function()
					debounce = false
				end)

				self:ClaimCash(player)
			end)
		)
	end

	return {
		Function = self.Disconnect,
		Args = { self, player },
	}
end

function ProcessService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	for _, connection: RBXScriptConnection in pairs(self.Connections[player] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self.Connections[player] = nil
end

-- LifeCycle
function ProcessService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.PlotService = knit.GetService("PlotService")
end

return ProcessService
