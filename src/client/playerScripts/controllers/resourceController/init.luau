-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local CollisionHandler = require(ReplicatedStorage.src.utility.CollisionHandler)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config Modules
local itemConfig = require(ReplicatedStorage.src.GameConfiguration.General.itemConfig)

-- Constants
local Player = Players.LocalPlayer
local Assets = ReplicatedStorage:WaitForChild("Assets")
local ResourceAssets = Assets:WaitForChild("Resources")
local RngAssets = Assets:WaitForChild("RngAssets")

-- Helper Functions
local function getBallAsset(resourceAsset: any)
	return InstanceCreator("Part", "Hitbox", resourceAsset, {
		Transparency = 1,
		CastShadow = false,
		Massless = true,
		Anchored = false,
		Shape = Enum.PartType.Ball,
		Size = resourceAsset:GetExtentsSize(),
		CFrame = resourceAsset:GetPivot(),
	})
end

local function getResourceAsset(itemAsset: any, resource: string)
	local resourceAsset = ResourceAssets:FindFirstChild(resource) and ResourceAssets:FindFirstChild(resource):Clone()
	resourceAsset:PivotTo(itemAsset:GetPivot() * CFrame.new(5, 0, 0))
	CollisionHandler.ToggleCollisionProperties(resourceAsset, {
		Anchored = false,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Massless = true,
	}, {})
	resourceAsset.Parent = workspace
	return resourceAsset
end

local function getRngAsset(itemAsset: any, rngItem: string)
	local rngAsset = RngAssets:FindFirstChild(rngItem) and RngAssets:FindFirstChild(rngItem):Clone()
	rngAsset:PivotTo(itemAsset:GetPivot() * CFrame.new(5, 0, 0))
	CollisionHandler.ToggleCollisionProperties(rngAsset, {
		Anchored = false,
		CanCollide = false,
		CanTouch = false,
		CanQuery = false,
		Massless = true,
	}, {})
	rngAsset.Parent = workspace
	return rngAsset
end

local function weld(resourceAsset: any, ballAsset: any)
	for _, child in pairs(resourceAsset:GetDescendants()) do
		if ballAsset == child or not child:IsA("BasePart") then
			continue
		end

		InstanceCreator("WeldConstraint", `Weld_{child.Name}_Ball`, ballAsset, {
			Part0 = child,
			Part1 = ballAsset,
			Enabled = true,
		})
	end
end

-->
local ResourceController = knit.CreateController({
	Name = "ResourceController",
})

-- Private Methods
function ResourceController:itemAssetEffects(itemAsset: any) end

function ResourceController:outputRng(itemAsset: any, rngItem: string)
	self:itemAssetEffects(itemAsset)
	rngItem = rngItem:split("_")[1]

	local rngAsset = getRngAsset(itemAsset, rngItem)
	local ballAsset = getBallAsset(rngAsset)

	ballAsset:AddTag("Rng")

	rngAsset.Parent = workspace
	weld(rngAsset, ballAsset)

	task.delay(120, function()
		if rngAsset and rngAsset.Parent then
			self.ResourceService
				:RngItemDestroyed(itemAsset)
				:andThen(function()
					rngAsset:Destroy()
				end)
				:catch(warn)
		end
	end)
end

function ResourceController:output(itemAsset: any)
	self:itemAssetEffects(itemAsset)

	local itemName = itemAsset.Name:split("_")[1]
	local resource = itemConfig.Items[itemName].Resource

	local resourceAsset = getResourceAsset(itemAsset, resource)
	local ballAsset = getBallAsset(resourceAsset)

	ballAsset:AddTag("Resource")

	resourceAsset.Parent = workspace
	weld(resourceAsset, ballAsset)

	task.delay(120, function()
		if resourceAsset and resourceAsset.Parent then
			self.ResourceService
				:ResourceDestroyed(itemAsset)
				:andThen(function()
					resourceAsset:Destroy()
				end)
				:catch(warn)
		end
	end)
end

function ResourceController:claimRng(hitbox)
	local isRngItem = hitbox:HasTag("Rng")
	if not isRngItem then
		return
	end

	if hitbox:GetAttribute("Claiming") then
		return
	end

	hitbox:SetAttribute("Claiming", true)
	self.ResourceService
		:ClaimRng(hitbox.Parent.Name)
		:andThen(function()
			hitbox.Parent:Destroy()
		end)
		:catch(warn)
end

function ResourceController:claimResource(hitbox)
	local isResource = hitbox:HasTag("Resource")
	if not isResource then
		return
	end

	if hitbox:GetAttribute("Claiming") then
		return
	end

	hitbox:SetAttribute("Claiming", true)
	self.ResourceService
		:ClaimResource(hitbox.Parent.Parent)
		:andThen(function(response: { Status: boolean })
			if response.Status then
				hitbox.Parent:Destroy()
			else
				hitbox:SetAttribute("Claiming", nil)
			end
		end)
		:catch(function(errorMessage)
			hitbox:SetAttribute("Claiming", nil)
			warn(errorMessage)
		end)
end

function ResourceController:listenToCharacterTouchConnections()
	local connections = {}
	local function disconnect()
		for _, connection: RBXScriptConnection in pairs(connections) do
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			end
		end
		table.clear(connections)
	end

	local function connect(character: Model)
		disconnect()

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			or character:WaitForChild("HumanoidRootPart", 2)

		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local hitboxSize = Vector3.new(4, 4, 4)
		local verticalOffset = humanoid.HipHeight + humanoidRootPart.Size.Y / 2 - hitboxSize.Y / 2

		local hitbox = InstanceCreator("Part", "ResourceHitbox", character, {
			Size = hitboxSize,
			Transparency = 1,
			CanCollide = false,
			CanTouch = true,
			CastShadow = false,
			Massless = true,
			CanQuery = false,
			CFrame = humanoidRootPart.CFrame * CFrame.new(0, -verticalOffset, 0),
		}) :: BasePart

		InstanceCreator("WeldConstraint", "ResourceTouchWeldConstraint", humanoidRootPart, {
			Part0 = hitbox,
			Part1 = humanoidRootPart,
		})

		table.insert(
			connections,
			hitbox.Touched:Connect(function(partThatTouched: BasePart)
				if partThatTouched:HasTag("Resouce") then
					self:claimResource(partThatTouched)
				elseif partThatTouched:HasTag("Rng") then
					self:claimRng(partThatTouched)
				end
			end)
		)
	end

	if Player.Character then
		connect(Player.Character)
	end

	Player.CharacterAdded:Connect(function(newCharacter)
		connect(newCharacter)
	end)
end

function ResourceController:listenToAutoCollectOrePart()
	local plotAsset = self.PlotController:GetPlotAsset()
	plotAsset:WaitForChild("AutoCollectOre").Touched:Connect(function(partThatTouched: BasePart)
		if self.DataController:GetValue("AutoLoot") == true then
			self:claimResource(partThatTouched)
		end
	end)
end

-- LifeCycle
function ResourceController:KnitInit()
	self.ResourceService = knit.GetService("ResourceService")
	self.DataController = knit.GetController("DataController")
	self.PlotController = knit.GetController("PlotController")
end

function ResourceController:KnitStart()
	self:listenToCharacterTouchConnections()
	self:listenToAutoCollectOrePart()

	self.ResourceService.Output:Connect(function(itemAsset)
		self:output(itemAsset)
	end)

	self.ResourceService.OutputRng:Connect(function(itemAsset, rngItem: string)
		self:outputRng(itemAsset, rngItem)
	end)
end

return ResourceController
