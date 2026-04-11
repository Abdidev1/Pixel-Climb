local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- >>> DEBUGGING START <<< --
print("PrestigeScript: Starting initialization...")
local moduleName = "CheckpointAndLeaderboard"

local CheckpointSystem = require(script.Parent:WaitForChild(moduleName))

print("PrestigeScript: Successfully loaded CheckpointSystem module!")

-- Configuration
local CONFIG = {
	Cooldown = 1, -- seconds
	RequiredObstacles = 100 -- Example requirement
}

local PrestigeConfirmEvent = ReplicatedStorage:FindFirstChild("RequestPrestigeConfirm")
if not PrestigeConfirmEvent then
	PrestigeConfirmEvent = Instance.new("RemoteEvent")
	PrestigeConfirmEvent.Name = "RequestPrestigeConfirm"
	PrestigeConfirmEvent.Parent = ReplicatedStorage
	print("PrestigeScript: Created RequestPrestigeConfirm RemoteEvent.")
else
	print("PrestigeScript: Found existing RequestPrestigeConfirm RemoteEvent.")
end

local cooldowns = {}
local touchDebounce = {}

local function resetTouchDebounce(player)
	if touchDebounce[player] then
		task.cancel(touchDebounce[player])
		touchDebounce[player] = nil
		print("SERVER: Debounce for", player.Name, "reset IMMEDIATELY for PrestigeTrigger.")
	end
end

local function canPrestige(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return false, "Leaderstats not found."
	end

	local obstacles = leaderstats:FindFirstChild("ObstaclesCompleted")
	if not obstacles then
		return false, "ObstaclesCompleted stat not found."
	end

	if obstacles.Value < CONFIG.RequiredObstacles then
		return false, "Complete more obstacles ("..(CONFIG.RequiredObstacles - obstacles.Value).." more) first!"
	end

	if cooldowns[player] and (os.time() - cooldowns[player] < CONFIG.Cooldown) then
		local remaining = CONFIG.Cooldown - (os.time() - cooldowns[player])
		return false, "Prestige on cooldown! Wait "..math.ceil(remaining).." seconds"
	end

	return true
end

local function performPrestige(player)
	local success, err = canPrestige(player)
	if not success then
		warn("SERVER: Prestige failed for", player.Name, "because:", err)
		return false
	end

	local playerService = CheckpointSystem.GetPlayerService(player)
	if not playerService then
		warn("SERVER: Could not get PlayerService for " .. player.Name .. ". Prestige cannot proceed.")
		return false
	end

	if typeof(playerService.prestige) ~= "function" then
		warn("SERVER: PlayerService is missing the 'prestige' method!")
		return false
	end

	playerService:prestige()

	cooldowns[player] = os.time()

	print(player.Name.." successfully prestiged to level "..playerService.prestigeStat.Value)
	return true
end

PrestigeConfirmEvent.OnServerEvent:Connect(function(player, confirm)
	if confirm then
		local successfullyPrestiged = performPrestige(player)
	end

	-- Always reset debounce and hide GUI regardless of success/fail
	resetTouchDebounce(player)
	local playerGui = player:WaitForChild("PlayerGui")
	local prestigeConfirmGui = playerGui:FindFirstChild("PrestigeConfirmGui")
	if prestigeConfirmGui then
		prestigeConfirmGui.Enabled = false
	end
end)

Players.PlayerRemoving:Connect(function(player)
	cooldowns[player] = nil
	resetTouchDebounce(player)
end)

local trigger = workspace:FindFirstChild("PrestigeTrigger")
if not trigger then
	trigger = Instance.new("Part")
	trigger.Name = "PrestigeTrigger"
	trigger.Size = Vector3.new(10, 5, 10)
	trigger.Position = Vector3.new(0, 5, 0)
	trigger.Anchored = true
	trigger.CanCollide = true
	trigger.BrickColor = BrickColor.new("Neon orange")
	trigger.Transparency = 0.5
	trigger.Parent = workspace
else
	print("PrestigeScript: Found existing PrestigeTrigger part.")
end

trigger.Touched:Connect(function(hit)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		if not touchDebounce[player] then
			touchDebounce[player] = task.delay(0.5, function()
				touchDebounce[player] = nil
			end)

			local playerGui = player:WaitForChild("PlayerGui")
			local prestigeConfirmGui = playerGui:FindFirstChild("PrestigeConfirmGui")

			if prestigeConfirmGui then
				local can, reason = canPrestige(player)
				if can then
					prestigeConfirmGui.Enabled = true
				else
					resetTouchDebounce(player)
				end
			else
				warn("SERVER: PrestigeConfirmGui NOT found in PlayerGui for", player.Name)
				resetTouchDebounce(player)
			end
		end
	end
end)

print("PrestigeScript: Initialization complete. Trigger Connected.")