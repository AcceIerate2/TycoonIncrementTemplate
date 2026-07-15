-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Helper Functions
local function isPlayer(player: Player?): boolean
	return typeof(player) == "Instance" and player:IsA("Player")
end

-->
local IndexService = knit.CreateService({
	Name = "IndexService",
	Client = {
		ItemAdded = knit.CreateSignal(),
	},
})

-- Public Methods
function IndexService:AddToIndex(player: Player, itemName: string)
	assert(isPlayer(player), "player arg must be a Player Instance")
	assert(typeof(itemName) == "string", "itemName arg must be a string")
	local indexValueObject = self.DataService:GetValueObject(player, "Index")
	if indexValueObject:Get()[itemName] then
		return
	end

	indexValueObject:Update(function(_table)
		_table[itemName] = true
	end)

	self.Client.ItemAdded:Fire(player, itemName)
end

-- LifeCycle
function IndexService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return IndexService
