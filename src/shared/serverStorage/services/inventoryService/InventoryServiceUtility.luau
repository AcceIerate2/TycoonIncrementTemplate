-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assets
local tools = ReplicatedStorage.Assets.Tools
local toolTemplate = tools.Template
assert(typeof(toolTemplate) == "Instance", `Could not find Tool: [Template] under ServerStorage:src:Tools`)

-->
local Utility = {}

function Utility:CreateTool(itemName: string, handler: string, textureId: string?): Tool
	assert(typeof(itemName) == "string", "itemName arg is nil")
	local toolName: string = itemName:split("_")[1] :: string

	local source = tools:FindFirstChild(toolName) or toolTemplate
	local tool = source:Clone()
	tool:SetAttribute("Handler", handler)

	tool.Name = itemName
	tool.TextureId = typeof(textureId) == "string" and textureId or tool.TextureId
	return tool
end

function Utility:DestroyTool(player: Player, toolName: string)
	if not player or not player.Parent then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local equippedTool = character:FindFirstChild(toolName)
	if equippedTool and equippedTool:IsA("Tool") then
		equippedTool:Destroy()
	end

	local tool = player.Backpack:FindFirstChild(toolName)
	if tool and tool:IsA("Tool") then
		tool:Destroy()
	end
end

function Utility:DestroyEquippedTool(player)
	local character = player.Character
	if not character then
		return
	end

	local tool = character:FindFirstChildOfClass("Tool")
	if tool then
		tool:Destroy()
	end
end

function Utility:ToolExistsInPlayerOrCharacter(player: Player, toolName: string): boolean
	local inBackpack = player.Backpack and player.Backpack:FindFirstChild(toolName) ~= nil
	local inCharacter = player.Character ~= nil and player.Character:FindFirstChild(toolName) ~= nil
	return inBackpack or inCharacter
end

return Utility
