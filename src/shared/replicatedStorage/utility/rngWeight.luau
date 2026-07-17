return function(items)
	local totalWeight = 0
	for _, item in items do
		assert(item.Weight >= 0, "Weights cannot be negative")
		totalWeight += item.Weight
	end

	assert(totalWeight > 0, "Total weight must be greater than 0")
	local RandomGenerator = Random.new()
	local roll = RandomGenerator:NextNumber(0, totalWeight)
	local accumulatedWeight = 0

	for name, item in items do
		accumulatedWeight += item.Weight

		if roll <= accumulatedWeight then
			return name
		end
	end
	return
end
