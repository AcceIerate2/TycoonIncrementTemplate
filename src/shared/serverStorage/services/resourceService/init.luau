-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local resourceConfig = require(ReplicatedStorage.src.GameConfiguration.General.resourceConfig)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local ResourceService = knit.CreateService({
	Name = "ResourceService",
	Profiles = {},
	Connections = {},
	Client = {
		Output = knit.CreateSignal(),
	},
})

-- Client Exposed Methods
function ResourceService.Client:ResourceDestroyed(player: Player, itemAsset: any)
	return self.Server:resourceDestroyed(player, itemAsset)
end

function ResourceService.Client:ClaimResource(player: Player, itemAsset: any)
	return self.Server:claimResource(player, itemAsset)
end

-- Private Methods
function ResourceService:resourceDestroyed(player: Player, itemAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if not profile then
	end

	if profile[itemAsset] and profile[itemAsset] > 0 then
		profile[itemAsset] -= 1
	end
end

function ResourceService:claimResource(player: Player, itemAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local ResourceValueObject = self.DataService:GetValueObject(player, "Resources")

	local profile = self:getProfile(player)
	if not profile then
		return {
			Status = false,
		}
	end

	if profile[itemAsset] and profile[itemAsset] > 0 then
		profile[itemAsset] -= 1

		local itemName = itemAsset.Name:split("_")[1]
		local resource = itemConfig.Items[itemName].Resource
		local amount = resourceConfig.Resources[resource].Amount
		ResourceValueObject:Set(ResourceValueObject:Get() + amount)

		return {
			Status = true,
		}
	end

	return {
		Status = false,
	}
end

function ResourceService:getProfile(player: Player)
	return self.Profiles[player]
end

-- Public Methods
function ResourceService:ActivateItem(player: Player, itemAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if profile then
		profile[itemAsset] = 0
	else
		warn(`Player does not own a profile?`)
	end
end

function ResourceService:DeactivateItem(player: Player, itemAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if profile then
		profile[itemAsset] = nil
	end
end

function ResourceService:GetTotalOutput(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if not profile then
		return
	end

	local resources = 0
	for itemAsset: any, count: number in pairs(profile) do
		resources += count
	end
	return resources
end

function ResourceService:Output(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if not profile then
		return
	end

	for itemAsset: any, count: number in pairs(profile) do
		if self:GetTotalOutput(player) >= 100 then
			return
		end

		profile[itemAsset] += 1

		task.delay(math.random(0, 100) / 100, function()
			self.Client.Output:Fire(player, itemAsset)
		end)
	end
end

function ResourceService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.Profiles[player] = {}
	self.Connections[player] = {}

	local elapsed = 0
	table.insert(
		self.Connections[player],
		RunService.Heartbeat:Connect(function(deltaTime: number)
			elapsed += deltaTime
			if elapsed < 3 then
				return
			end

			elapsed = 0
			self:Output(player)
		end)
	)

	return {
		Function = self.Disconnect,
		Args = { self, player },
	}
end

function ResourceService:Disconnect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")

	-- Disconnect Connections
	for _, connection: RBXScriptConnection in pairs(self.Connections[player] or {}) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		end
	end
	self.Connections[player] = nil

	-- Clear References
	self.Profiles[player] = nil
end

-- LifeCycle
function ResourceService:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self.DataService = knit.GetService("DataService")
end

return ResourceService
