--!strict
-- CheckpointAndLeaderboard.luau
-- Manages player checkpoint persistence, leaderboard stats, and spawn logic.
-- Runs in ServerScriptService.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CONFIG = {
	Checkpoints = {
		Folder = workspace:WaitForChild("Checkpoints"),
		SpawnHeight = 3,
		DataStore = DataStoreService:GetDataStore("CheckpointData"),
	},
	Prestige = {
		DataStore = DataStoreService:GetDataStore("PrestigeData"),
	},
}

local TOTAL_CHECKPOINTS = 0

-- Remote events
local Events = {
	CheckpointReached = Instance.new("RemoteEvent"),
	PrestigeEvent     = Instance.new("RemoteEvent"),
	InitProgress      = Instance.new("RemoteEvent"),
}

Events.CheckpointReached.Name = "CheckpointReached"
Events.PrestigeEvent.Name     = "PrestigeEvent"
Events.InitProgress.Name      = "InitProgress"

for _, event in pairs(Events) do
	event.Parent = ReplicatedStorage
end

local function log(...)
	print("[CheckpointSystem]", ...)
end

-- PlayerService class

local PlayerService = {}
PlayerService.__index = PlayerService

function PlayerService.new(player: Player)
	local self = setmetatable({}, PlayerService)
	self.player        = player
	self.userId        = player.UserId
	self.obstacles     = 0
	self.prestigeLevel = 0
	self.checkpoint    = nil
	self.loaded        = false

	local leaderstats = Instance.new("Folder")
	leaderstats.Name   = "leaderstats"
	leaderstats.Parent = player

	self.obstaclesStat        = Instance.new("IntValue")
	self.obstaclesStat.Name   = "ObstaclesCompleted"
	self.obstaclesStat.Value  = 0
	self.obstaclesStat.Parent = leaderstats

	self.prestigeStat        = Instance.new("IntValue")
	self.prestigeStat.Name   = "Prestige"
	self.prestigeStat.Value  = 0
	self.prestigeStat.Parent = leaderstats

	return self
end

function PlayerService:loadData()
	local ok, checkpoint = pcall(function()
		return CONFIG.Checkpoints.DataStore:GetAsync("player_" .. self.userId)
	end)

	if ok and checkpoint then
		self.checkpoint = checkpoint
		self.obstacles  = tonumber(checkpoint:match("%d+$")) or 0
	else
		self.checkpoint = nil
		self.obstacles  = 0
		if not ok then
			warn("[CheckpointSystem] Failed to load checkpoint for", self.player.Name, ":", checkpoint)
		end
	end

	local ok2, prestigeValue = pcall(function()
		return CONFIG.Prestige.DataStore:GetAsync("player_" .. self.userId)
	end)

	if ok2 and type(prestigeValue) == "number" then
		self.prestigeLevel = prestigeValue
	else
		self.prestigeLevel = 0
		if not ok2 then
			warn("[CheckpointSystem] Failed to load prestige for", self.player.Name, ":", prestigeValue)
		end
	end

	self.obstaclesStat.Value = self.obstacles
	self.prestigeStat.Value  = self.prestigeLevel
	self.loaded              = true

	log("Loaded", self.player.Name, "| Stage:", self.obstacles, "| Prestige:", self.prestigeLevel)
end

function PlayerService:saveData()
	local ok1, err1 = pcall(function()
		if self.checkpoint then
			CONFIG.Checkpoints.DataStore:SetAsync("player_" .. self.userId, self.checkpoint)
		else
			CONFIG.Checkpoints.DataStore:RemoveAsync("player_" .. self.userId)
		end
	end)
	if not ok1 then
		warn("[CheckpointSystem] Failed to save checkpoint for", self.player.Name, ":", err1)
	end

	local ok2, err2 = pcall(function()
		CONFIG.Prestige.DataStore:SetAsync("player_" .. self.userId, self.prestigeLevel)
	end)
	if not ok2 then
		warn("[CheckpointSystem] Failed to save prestige for", self.player.Name, ":", err2)
	end

	log("Saved data for", self.player.Name)
end

function PlayerService:reachedCheckpoint(checkpointName: string): boolean
	local checkpointNum = tonumber(checkpointName:match("%d+$")) or 0

	if checkpointNum > self.obstacles then
		self.obstacles              = checkpointNum
		self.checkpoint             = checkpointName
		self.obstaclesStat.Value    = self.obstacles

		Events.CheckpointReached:FireClient(self.player, checkpointName)

		task.spawn(function()
			local ok, err = pcall(function()
				CONFIG.Checkpoints.DataStore:SetAsync("player_" .. self.userId, checkpointName)
			end)
			if not ok then
				warn("[CheckpointSystem] Async save failed for", self.player.Name, ":", err)
			end
		end)

		log(self.player.Name, "reached", checkpointName)
		return true
	end

	return false
end

function PlayerService:spawn()
	local character = self.player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	if self.checkpoint then
		local part = CONFIG.Checkpoints.Folder:FindFirstChild(self.checkpoint)
		if part then
			hrp.CFrame = part.CFrame * CFrame.new(0, CONFIG.Checkpoints.SpawnHeight, 0)
			return
		end
	end

	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLocation then
		hrp.CFrame = spawnLocation.CFrame * CFrame.new(0, CONFIG.Checkpoints.SpawnHeight, 0)
	else
		warn("[CheckpointSystem] No SpawnLocation found for", self.player.Name)
	end
end

function PlayerService:prestige(): boolean
	self.obstacles           = 0
	self.checkpoint          = nil
	self.obstaclesStat.Value = 0
	self.prestigeLevel       += 1
	self.prestigeStat.Value  = self.prestigeLevel

	task.spawn(function()
		pcall(function()
			CONFIG.Prestige.DataStore:SetAsync("player_" .. self.userId, self.prestigeLevel)
		end)
		pcall(function()
			CONFIG.Checkpoints.DataStore:RemoveAsync("player_" .. self.userId)
		end)
	end)

	Events.InitProgress:FireClient(self.player, TOTAL_CHECKPOINTS)
	task.wait(0.1)
	self.player:LoadCharacter()

	log(self.player.Name, "prestiged to level", self.prestigeLevel)
	return true
end

-- System initialisation

local activePlayers: { [Player]: typeof(PlayerService.new(...)) } = {}

local function setupSystem()
	for _, part in ipairs(CONFIG.Checkpoints.Folder:GetChildren()) do
		if part:IsA("BasePart") and part.Name:match("^Checkpoint%d+$") then
			TOTAL_CHECKPOINTS += 1
		end
	end
	log("Total checkpoints:", TOTAL_CHECKPOINTS)

	for _, part in ipairs(CONFIG.Checkpoints.Folder:GetDescendants()) do
		if part:IsA("BasePart") and part.Name:match("^Checkpoint%d+$") then
			part.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and activePlayers[player] then
					activePlayers[player]:reachedCheckpoint(part.Name)
				end
			end)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		local service = PlayerService.new(player)
		activePlayers[player] = service

		task.spawn(function()
			service:loadData()
			Events.InitProgress:FireClient(player, TOTAL_CHECKPOINTS)

			player.CharacterAdded:Connect(function()
				service:spawn()
			end)

			if player.Character then
				service:spawn()
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		if activePlayers[player] then
			activePlayers[player]:saveData()
			activePlayers[player] = nil
		end
	end)

	-- Fallback: create a default checkpoint if the folder is empty
	if #CONFIG.Checkpoints.Folder:GetChildren() == 0 then
		local part       = Instance.new("Part")
		part.Name        = "Checkpoint1"
		part.Anchored    = true
		part.Size        = Vector3.new(10, 2, 10)
		part.Position    = Vector3.new(0, 5, 0)
		part.BrickColor  = BrickColor.new("Bright blue")
		part.Transparency = 0.5
		part.Parent      = CONFIG.Checkpoints.Folder
		TOTAL_CHECKPOINTS = 1
		log("Created fallback Checkpoint1")
	end
end

setupSystem()

return {
	GetPlayerService = function(player: Player)
		return activePlayers[player]
	end,
}
