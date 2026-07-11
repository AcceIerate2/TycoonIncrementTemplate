-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-->
local DataService = knit.CreateService({
	Name = "DataService",
	Client = {},
	Data = {},
	ClientDataChanges = {},
	Utility = require(script.utility),
	LeaderstatsHandler = require(script.leaderstats),
})

function DataService.Client:getProfileKeys(player: Player)
	local dataToReturn: { string } = {}

	local profile = self.Server:getProfile(player)
	for key: string, _ in pairs(profile) do
		table.insert(dataToReturn, key)
	end
	return dataToReturn
end

function DataService.Client:getValue(player: Player, valueName: string): any
	return self.Server:getValue(player, valueName)
end

function DataService:getValue(player: Player, valueName: string): any
	assert(TypeCheck.Instance(player), "player arg must be a player")
	local playerData = self:getProfile(player)
	return playerData and playerData[valueName]:Get()
end

function DataService:get(player: Player, valueName: string)
	assert(TypeCheck.Instance(player), "player arg must be a player")
	local playerData = self:getProfile(player)
	return playerData[valueName]
end

function DataService:getProfile(player: Player)
	assert(TypeCheck.Instance(player), "player arg must be a player")
	return self.Data[player]
end

function DataService:delete(player: Player, valueName: string)
	assert(TypeCheck.Instance(player), "player arg must be a player")
	local playerData = self:getProfile(player)
	playerData[valueName]:Destroy()
	playerData[valueName] = nil
end

function DataService:create(player: Player, profileData, valueData: { Name: string, Value: any })
	local playerData = self:getProfile(player)

	local name = valueData.Name
	local value = valueData.Value

	local valueExists = playerData[name] ~= nil
	assert(valueExists == false, "Attempt to connect existing Value to player data")

	playerData[name] = self.Utility.createValueObject(name, value, profileData, function(key: string, newValue: any?)
		self.ClientDataChanges[player]:FireClient(player, key, newValue)
	end)
	return playerData[name]
end

function DataService:connectProfile(player: Player, profileData)
	self.Data[player] = {}
	self.ClientDataChanges[player] = InstanceCreator("RemoteEvent", `{player.UserId}`, ReplicatedStorage.src.dataEvents)

	for valueName: string, value: any in pairs(profileData) do
		local valueData = {
			Name = valueName,
			Value = value,
		}
		self:create(player, profileData, valueData)
	end

	self.LeaderstatsHandler.setup(player, self:getProfile(player))

	return {
		["Function"] = self.disconnectProfile,
		["Args"] = { self, player },
	}
end

function DataService:disconnectProfile(player: Player)
	self.LeaderstatsHandler.clear(player, self:getProfile(player))
	local profile = self:getProfile(player)

	for _, data in pairs(profile or {}) do
		data:Destroy()
	end

	self.Data[player] = nil

	if self.ClientDataChanges[player] then
		self.ClientDataChanges[player]:Destroy()
		self.ClientDataChanges[player] = nil
	end
end

function DataService:KnitInit()
	print(`DataService Initiated.`)
end

return DataService
