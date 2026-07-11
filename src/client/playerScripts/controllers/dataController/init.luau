-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Folders
local DataEventsFolder = ReplicatedStorage:WaitForChild("src"):WaitForChild("dataEvents")

-->
local DataController = knit.CreateController({
	Name = "DataController",
	Events = {},
	Data = {},
})

function DataController:getValue(valueName: string)
	assert(TypeCheck.string(valueName), "valueName arg must be a string")
	local dataToReturn = self.Data[valueName]
	if not dataToReturn then
		repeat
			task.wait()
			dataToReturn = self.Data[valueName]
		until dataToReturn ~= nil
	end
	return dataToReturn
end

function DataController:getValueChangedSignal(valueName: string)
	local event = self.Events[valueName]
	assert(event, `No client signal registered for "{valueName}"`)
	return event.Event
end

function DataController:connect()
	local dataChangedRE: RemoteEvent = DataEventsFolder:WaitForChild(Players.LocalPlayer.UserId)
	dataChangedRE.OnClientEvent:Connect(function(key: string, newValue: any?)
		local eventToFire: BindableEvent = self.Events[key]
		if not eventToFire then
			return
		end
		eventToFire:Fire(newValue)
		self.Data[key] = newValue
	end)
end

function DataController:loadEvents(profileKeys: { string })
	assert(TypeCheck.table(profileKeys), "profileKeys arg must be a table")
	for _, valueName: string in pairs(profileKeys) do
		self.Events[valueName] = InstanceCreator("BindableEvent", valueName, script)
		self.DataService
			:getValue(valueName)
			:andThen(function(data)
				self.Data[valueName] = data
			end)
			:catch(warn)
	end
end

function DataController:KnitInit()
	self.DataService = knit.GetService("DataService")
	local status, keys = SafeFunctionCaller(function()
		local _status, _keys = self.DataService:getProfileKeys():await()
		assert(TypeCheck.boolean(_status) and _status == true, "getProfileKeys request failed.")
		return _keys
	end)
	assert(
		TypeCheck.boolean(status) and status == true or not TypeCheck.table(keys),
		"[SafeFunctionCaller] getProfileKeys request failed."
	)

	self:loadEvents(keys)
	self:connect()
	print("DataController Initiated.")
end

return DataController
