--!strict
-- PlayerCollision.luau
-- Assigns each player to their own collision group on spawn so players
-- cannot stand on or push each other. Runs in ServerScriptService.

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local PLAYER_GROUP = "Players"

-- Create the collision group once at startup
local ok, err = pcall(function()
	PhysicsService:RegisterCollisionGroup(PLAYER_GROUP)
end)
if not ok and not err:find("already") then
	warn("[PlayerCollision] Could not register collision group:", err)
end

-- Disable player-to-player collisions
PhysicsService:CollisionGroupSetCollidable(PLAYER_GROUP, PLAYER_GROUP, false)

local function applyCollisionGroup(character: Model)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, PLAYER_GROUP)
		end
	end

	-- Handle parts added after the character loads (accessories, tools, etc.)
	character.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, PLAYER_GROUP)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(applyCollisionGroup)

	if player.Character then
		applyCollisionGroup(player.Character)
	end
end)
