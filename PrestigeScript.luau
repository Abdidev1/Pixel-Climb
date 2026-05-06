--!strict
-- PrestigeScript.luau
-- Handles the prestige trigger, confirmation flow, and delegates the reset
-- to CheckpointAndLeaderboard. Runs in ServerScriptService.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CheckpointSystem = require(script.Parent:WaitForChild("CheckpointAndLeaderboard"))

local CONFIG = {
	Cooldown           = 1,   -- seconds between prestige attempts
	RequiredObstacles  = 100, -- stages a player must complete before prestiging
}

-- Ensure the confirmation event exists
local PrestigeConfirmEvent: RemoteEvent = ReplicatedStorage:FindFirstChild("RequestPrestigeConfirm")
	or (function()
		local e      = Instance.new("RemoteEvent")
		e.Name       = "RequestPrestigeConfirm"
		e.Parent     = ReplicatedStorage
		return e
	end)()

local cooldowns:     { [Player]: number  } = {}
local touchDebounce: { [Player]: thread? } = {}

local function clearDebounce(player: Player)
	if touchDebounce[player] then
		task.cancel(touchDebounce[player])
		touchDebounce[player] = nil
	end
end

local function canPrestige(player: Player): (boolean, string?)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Leaderstats not initialised."
	end

	local obstacles = leaderstats:FindFirstChild("ObstaclesCompleted")
	if not obstacles then
		return false, "ObstaclesCompleted stat not found."
	end

	if obstacles.Value < CONFIG.RequiredObstacles then
		local remaining = CONFIG.RequiredObstacles - obstacles.Value
		return false, ("Complete %d more stage(s) to prestige."):format(remaining)
	end

	local lastPrestige = cooldowns[player]
	if lastPrestige and (os.time() - lastPrestige) < CONFIG.Cooldown then
		local wait = math.ceil(CONFIG.Cooldown - (os.time() - lastPrestige))
		return false, ("Prestige on cooldown — try again in %d second(s)."):format(wait)
	end

	return true, nil
end

local function performPrestige(player: Player): boolean
	local ok, reason = canPrestige(player)
	if not ok then
		warn("[PrestigeScript] Prestige denied for", player.Name, "—", reason)
		return false
	end

	local service = CheckpointSystem.GetPlayerService(player)
	if not service then
		warn("[PrestigeScript] PlayerService not found for", player.Name)
		return false
	end

	service:prestige()
	cooldowns[player] = os.time()
	return true
end

local function hideConfirmGui(player: Player)
	local gui = player:FindFirstChild("PlayerGui")
		and player.PlayerGui:FindFirstChild("PrestigeConfirmGui")
	if gui then
		gui.Enabled = false
	end
end

-- Handle confirmation response from client
PrestigeConfirmEvent.OnServerEvent:Connect(function(player: Player, confirm: boolean)
	if confirm then
		performPrestige(player)
	end
	clearDebounce(player)
	hideConfirmGui(player)
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player]     = nil
	clearDebounce(player)
end)

-- Create the prestige trigger part if it does not exist
local trigger: BasePart = workspace:FindFirstChild("PrestigeTrigger")
	or (function()
		local p           = Instance.new("Part")
		p.Name            = "PrestigeTrigger"
		p.Size            = Vector3.new(10, 5, 10)
		p.Position        = Vector3.new(0, 5, 0)
		p.Anchored        = true
		p.CanCollide      = true
		p.BrickColor      = BrickColor.new("Neon orange")
		p.Transparency    = 0.5
		p.Parent          = workspace
		return p
	end)()

trigger.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or touchDebounce[player] then return end

	touchDebounce[player] = task.delay(0.5, function()
		touchDebounce[player] = nil
	end)

	local ok, _ = canPrestige(player)
	if not ok then
		clearDebounce(player)
		return
	end

	local gui = player:WaitForChild("PlayerGui"):FindFirstChild("PrestigeConfirmGui")
	if gui then
		gui.Enabled = true
	else
		warn("[PrestigeScript] PrestigeConfirmGui missing for", player.Name)
		clearDebounce(player)
	end
end)
