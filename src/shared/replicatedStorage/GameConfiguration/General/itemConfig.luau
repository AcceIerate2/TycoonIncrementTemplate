local ItemConfig = {}

function ItemConfig.GetCost(purchases: number)
	return math.round(5 + purchases ^ 0.87 * 2)
end

ItemConfig.Items = {
	Template = {
		Resource = "Yes",
	},

	Test = {
		Resource = "No",
	},

	Diamond = {
		Resource = "Okay",
	},
}

ItemConfig.Order = {
	[1] = "Template",
	[2] = "Test",
	[3] = "Diamond",
}

return ItemConfig
