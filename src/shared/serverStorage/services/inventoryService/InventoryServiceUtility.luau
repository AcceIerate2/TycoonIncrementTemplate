-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assets
local RngAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("RngAssets")
local tools = ReplicatedStorage.Assets.Tools
local toolTemplate = tools.Template
assert(typeof(toolTemplate) == "Instance", `Could not find Tool: [Template] under ServerStorage:src:Tools`)

-- Utility Modules
local CollisionHandler = require(ReplicatedStorage.src.utility.CollisionHandler)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Helper Functions
local function getRngAsset(rngAssetName)
	local asset = RngAssets:WaitForChild(rngAssetName):Clone()
	CollisionHandler.ToggleCollisionProperties(asset, {
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		CastShadow = false,
		Anchored = false,
		Massless = true,
	}, {})
	return asset
end

local function handlerPart(asset, tool)
	local handler = InstanceCreator("Part", "Handle", tool, {
		Size = asset:GetExtentsSize(),
		Transparency = 1,
		Material = Enum.Material.Neon,
		CastShadow = false,
		Massless = true,
		Anchored = false,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
	})
	return handler
end

local function weld(handler, asset)
	for _, desc in pairs(asset:GetDescendants()) do
		InstanceCreator("WeldConstraint", "WeldConstraint", handler, {
			Part0 = desc,
			Part1 = handler,
			Enabled = true,
		})
	end
end

-->
local Utility = {}

function Utility:CreateTool(itemName: string, handler: string, textureId: string?): Tool
	assert(typeof(itemName) == "string", "itemName arg is nil")
	local toolName: string = itemName:split("_")[1] :: string

	local source = tools:FindFirstChild(toolName) or toolTemplate
	local tool = source:Clone() :: Tool
	tool:SetAttribute("Handler", handler)

	local asset = getRngAsset(itemName)
	local handle = handlerPart(asset, tool)
	asset.Parent = tool
	asset:PivotTo(handle.CFrame)
	weld(handle, asset)

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
