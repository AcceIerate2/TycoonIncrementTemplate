-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)
local resourceConfig = require(ReplicatedStorage.src.GameConfiguration.General.resourceConfig)
local rngWeight = require(ReplicatedStorage.src.utility.rngWeight)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local ResourceService = knit.CreateService({
	Name = "ResourceService",
	Profiles = {},
	RngItems = {},
	Connections = {},
	Client = {
		Output = knit.CreateSignal(),
		OutputRng = knit.CreateSignal(),
	},
})

-- Client Exposed Methods
function ResourceService.Client:ClaimRng(player: Player, rngItem: any)
	return self.Server:claimRng(player, rngItem)
end

function ResourceService.Client:RngItemDestroyed(player: Player)
	return self.Server:rngItemDestroyed(player)
end

function ResourceService.Client:ResourceDestroyed(player: Player, itemAsset: any)
	return self.Server:resourceDestroyed(player, itemAsset)
end

function ResourceService.Client:ClaimResource(player: Player, itemAsset: any, itemName: string)
	return self.Server:claimResource(player, itemAsset, itemName)
end

-- Private Methods
function ResourceService:claimRng(player: Player, rngItem: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	self:rngItemDestroyed(player, rngItem)
	local tool = self.InventoryService:Give(player, rngItem, "RngItem")
	if tool then
		self.InventoryService:EquipTool(player, tool)
		self.DataService:GetValueObject(player, "EquippedRng"):Set(rngItem)
	end
end

function ResourceService:rngItemDestroyed(player: Player, rngItem: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	if typeof(self.RngItems[player]) ~= "number" then
		return
	end

	local index = table.find(self.RngItems[player], rngItem)
	if index then
		table.remove(self.RngItems[player], index)
	end

	self.DataService:GetValueObject(player, "EquippedRng"):Set("")
end

function ResourceService:resourceDestroyed(player: Player, itemAsset: any)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if not profile then
		return
	end

	if profile[itemAsset] and profile[itemAsset] > 0 then
		profile[itemAsset] -= 1
	end
end

function ResourceService:claimResource(player: Player, itemAsset: any, itemName: string)
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
	end

	itemName = itemName or itemAsset.Name:split("_")[1]
	local resource = itemConfig.Items[itemName].Resource
	local amount = resourceConfig.Resources[resource].Amount
	ResourceValueObject:Set(ResourceValueObject:Get() + amount)

	return {
		Status = true,
	}
end

function ResourceService:getProfile(player: Player)
	return self.Profiles[player]
end

-- Public Methods
function ResourceService:RngItemExists(player: Player, rngItem: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	return table.find(self.RngItems[player], rngItem) ~= nil
end

function ResourceService:RemoveRngItem(player: Player, rngItem: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(rngItem) == "string", "rngItem arg must be a string")
	local index = table.find(self.RngItems[player], rngItem)
	if index then
		table.remove(self.RngItems[player], index)
	end
end

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

function ResourceService:GetResourcesOutput(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	local profile = self:getProfile(player)
	if not profile then
		return
	end

	local resources = 0
	for itemAsset: any, count: number in pairs(profile) do
		local referenceId = itemAsset.Name
		local itemName = referenceId:split("_")[1]
		local resource = itemConfig.Items[itemName].Resource
		local amount = resourceConfig.Resources[resource].Amount
		resources += amount
	end

	return resources
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

		local rng = math.random(1, 10) == 1
		if rng then
			local rngItem = rngWeight(itemConfig.Items[itemAsset.Name:split("_")[1]].RngItems)
			table.insert(self.RngItems[player], rngItem)
			task.delay(math.random(0, 100) / 100, function()
				self.Client.OutputRng:Fire(player, itemAsset, rngItem)
			end)
			continue
		end

		local doubleOre = self.DataService:GetValue(player, "DoubleOre")
		profile[itemAsset] += doubleOre and 2 or 1

		task.delay(math.random(0, 100) / 100, function()
			self.Client.Output:Fire(player, itemAsset)

			if doubleOre then
				task.delay(0.25, function()
					self.Client.Output:Fire(player, itemAsset)
				end)
			end
		end)
	end
end

function ResourceService:Connect(player: Player)
	assert(isPlayer(player), "player arg must be a Player Instance")
	self.Profiles[player] = {}
	self.Connections[player] = {}
	self.RngItems[player] = {}

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
	self.DataService = knit.GetService("DataService")
	self.InventoryService = knit.GetService("InventoryService")
end

return ResourceService
