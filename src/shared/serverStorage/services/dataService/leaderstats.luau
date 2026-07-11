-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

local leaderstats = {}
leaderstats.playerConnections = {}
leaderstats.Config = require(ReplicatedStorage.src.GameConfiguration.Gameplay.leaderstatsConfig)

function leaderstats.setup(player: Player, playerData)
	local leaderstatsFolder = InstanceCreator("Folder", "leaderstats", player)

	leaderstats.playerConnections[player] = {}
	local playerConnectionsFolder = leaderstats.playerConnections[player]

	for _, valueName: string in pairs(leaderstats.Config.ValuesToDisplay) do
		local leaderstatsValueInstance: NumberValue =
			InstanceCreator("NumberValue", valueName, leaderstatsFolder) :: NumberValue

		local objectValue = playerData[valueName]
		leaderstatsValueInstance.Value = objectValue:Get()

		playerConnectionsFolder[valueName] = objectValue.Changed:Connect(function(newValue)
			leaderstatsValueInstance.Value = newValue
		end) :: RBXScriptConnection
	end
end

function leaderstats.clear(player: Player)
	local connections = leaderstats.playerConnections[player] or {}
	for _, connection: RBXScriptConnection in pairs(connections) do
		connection:Disconnect()
	end
	leaderstats.playerConnections[player] = nil
end

return leaderstats
