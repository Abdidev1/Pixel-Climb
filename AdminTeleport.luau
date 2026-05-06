--!strict
-- AdminTeleport.luau
-- Server-side handler for admin/VIP teleport commands.
-- Replaces the individual "Teleport To Stage N" scripts with one
-- consolidated handler. Runs in ServerScriptService.
--
-- Usage: fire the "AdminTeleport" RemoteEvent from a client GUI
-- with the target stage number as the argument.
-- Only players listed in ADMIN_IDS, or players with the "Developer"
-- role assigned by PlayerRole.luau, are authorised.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CheckpointSystem = require(script.Parent:WaitForChild("CheckpointAndLeaderboard"))

-- Authorised user IDs (Roblox UserId integers)
local ADMIN_IDS: { number } = {
	-- e.g. 123456789,
}

-- Named teleport destinations (in addition to any numeric stage)
local NAMED_DESTINATIONS: { [string]: string } = {
	end_ = "CheckpointEnd",  -- name of the final checkpoint part
}

local AdminTeleportEvent: RemoteEvent = ReplicatedStorage:FindFirstChild("AdminTeleport")
	or (function()
		local e    = Instance.new("RemoteEvent")
		e.Name     = "AdminTeleport"
		e.Parent   = ReplicatedStorage
		return e
	end)()

local function isAdmin(player: Player): boolean
	for _, id in ipairs(ADMIN_IDS) do
		if player.UserId == id then return true end
	end

	local role = player:FindFirstChild("Role")
	return role ~= nil and (role.Value == "Developer" or role.Value == "Owner")
end

local function teleportTo(player: Player, checkpointName: string)
	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then
		warn("[AdminTeleport] Checkpoints folder not found.")
		return
	end

	local part = folder:FindFirstChild(checkpointName)
	if not part or not part:IsA("BasePart") then
		warn("[AdminTeleport] Destination not found:", checkpointName)
		return
	end

	local character = player.Character
	local hrp       = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	local service = CheckpointSystem.GetPlayerService(player)
	if service then
		service:reachedCheckpoint(checkpointName)
	end

	hrp.CFrame = part.CFrame * CFrame.new(0, 3, 0)
	print(("[AdminTeleport] %s teleported to %s"):format(player.Name, checkpointName))
end

AdminTeleportEvent.OnServerEvent:Connect(function(player: Player, destination: unknown)
	if not isAdmin(player) then
		warn("[AdminTeleport] Unauthorised request from", player.Name)
		return
	end

	if type(destination) == "number" then
		teleportTo(player, "Checkpoint" .. destination)
	elseif type(destination) == "string" then
		local mapped = NAMED_DESTINATIONS[destination]
		if mapped then
			teleportTo(player, mapped)
		else
			teleportTo(player, destination) -- pass through as a raw checkpoint name
		end
	end
end)
