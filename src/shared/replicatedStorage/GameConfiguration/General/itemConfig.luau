local ItemConfig = {}

function ItemConfig.GetCost(purchases: number)
	return math.round(5 + purchases ^ 0.87 * 2)
end

ItemConfig.Items = {
	Template = {
		Resource = "Yes",
		RngItems = {
			Default = {
				Weight = 50,
			},
		},
	},

	Test = {
		Resource = "No",
		RngItems = {
			Default = {
				Weight = 50,
			},
		},
	},

	Diamond = {
		Resource = "Okay",
		RngItems = {
			Default = {
				Weight = 50,
			},
		},
	},
}

ItemConfig.Order = {
	[1] = "Template",
	[2] = "Test",
	[3] = "Diamond",
}

return ItemConfig
