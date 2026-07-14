local ProcessUpgradeConfig = {}

function ProcessUpgradeConfig.GetIncrement(level: number): number
	return math.round(2 * 1.26 ^ (level - 1))
end

function ProcessUpgradeConfig.GetCost(level: number): number
	return math.round(11 * 1.38 ^ (level - 1))
end

return ProcessUpgradeConfig
