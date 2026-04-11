local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration often used as a barrier in leaderboarfd
local CONFIG = {
	Checkpoints = {
		Folder = workspace:WaitForChild("Checkpoints"),
		SpawnHeight = 3,
		DataStore = DataStoreService:GetDataStore("CheckpointData")
	},
	Prestige = {
		DataStore = DataStoreService:GetDataStore("PrestigeData")
	}
}

-- Variable to store the total number of checkpoints its usually essential for maintaininf the tasks or any part of file
local TOTAL_CHECKPOINTS = 0

-- Create communication events
local Events = {
	CheckpointReached = Instance.new("RemoteEvent"),
	PrestigeEvent = Instance.new("RemoteEvent"),
	InitProgress = Instance.new("RemoteEvent") -- Event to send the total stage count to the client
}
Events.CheckpointReached.Name = "CheckpointReached"
Events.PrestigeEvent.Name = "PrestigeEvent"
Events.InitProgress.Name = "InitProgress"
Events.CheckpointReached.Parent = ReplicatedStorage
Events.PrestigeEvent.Parent = ReplicatedStorage
Events.InitProgress.Parent = ReplicatedStorage

local function debugPrint(...)
	print("[CheckpointSystem]", ...)
end

-----------[ CORE FUNCTIONALITY ]-----------

local PlayerService = {}

function PlayerService.new(player)
	local self = {
		player = player,
		userId = player.UserId,
		obstacles = 0,
		prestigeLevel = 0,
		checkpoint = nil,
		loaded = false
	}

	-- Initialize leaderstats
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	self.obstaclesStat = Instance.new("IntValue")
	self.obstaclesStat.Name = "ObstaclesCompleted"
	self.obstaclesStat.Value = 0
	self.obstaclesStat.Parent = leaderstats

	self.prestigeStat = Instance.new("IntValue")
	self.prestigeStat.Name = "Prestige"
	self.prestigeStat.Value = 0
	self.prestigeStat.Parent = leaderstats

	return setmetatable(self, {__index = PlayerService})
end

function PlayerService:loadData()
	-- Load checkpoint data
	local success, checkpoint = pcall(function()
		return CONFIG.Checkpoints.DataStore:GetAsync("player_"..self.userId)
	end)

	if success and checkpoint then
		self.checkpoint = checkpoint
		self.obstacles = tonumber(checkpoint:match("%d+$")) or 0
	else
		self.checkpoint = nil
		self.obstacles = 0
		if not success then warn("[CheckpointSystem] Error loading checkpoint data:", checkpoint) end
	end

	-- Load prestige data
	local success2, prestigeValue = pcall(function()
		return CONFIG.Prestige.DataStore:GetAsync("player_"..self.userId)
	end)

	if success2 and prestigeValue and type(prestigeValue) == "number" then
		self.prestigeLevel = prestigeValue
	else
		self.prestigeLevel = 0
		if not success2 then warn("[CheckpointSystem] Error loading prestige data:", prestigeValue) end
	end

	-- Update visuals
	self.obstaclesStat.Value = self.obstacles
	self.prestigeStat.Value = self.prestigeLevel
	self.loaded = true
	debugPrint("Loaded data for", self.player.Name, "| Obstacles:", self.obstacles, "| Checkpoint:", self.checkpoint, "| Prestige:", self.prestigeLevel)
end

function PlayerService:saveData()
	-- Save checkpoint
	local success1, err1 = pcall(function()
		if self.checkpoint then
			CONFIG.Checkpoints.DataStore:SetAsync("player_"..self.userId, self.checkpoint)
		else
			CONFIG.Checkpoints.DataStore:RemoveAsync("player_"..self.userId)
		end
	end)
	if not success1 then warn("[CheckpointSystem] Error saving checkpoint data for", self.player.Name, ":", err1) end

	-- Save prestige
	local success2, err2 = pcall(function()
		CONFIG.Prestige.DataStore:SetAsync("player_"..self.userId, self.prestigeLevel)
	end)
	if not success2 then warn("[CheckpointSystem] Error saving prestige data for", self.player.Name, ":", err2) end
	debugPrint("Saved data for", self.player.Name)
end

function PlayerService:reachedCheckpoint(checkpointName)
	local checkpointNum = tonumber(checkpointName:match("%d+$")) or 0

	if checkpointNum > self.obstacles then
		self.obstacles = checkpointNum
		self.checkpoint = checkpointName

		self.obstaclesStat.Value = self.obstacles

		-- Fire the name of the checkpoint (e.g., "Checkpoint10")
		Events.CheckpointReached:FireClient(self.player, checkpointName)

		-- Async save for performance
		task.spawn(function()
			local success, err = pcall(function()
				CONFIG.Checkpoints.DataStore:SetAsync("player_"..self.userId, checkpointName)
			end)
			if not success then
				warn("[CheckpointSystem] Error saving checkpoint async for", self.player.Name, ":", err)
			end
		end)

		debugPrint(self.player.Name, "reached", checkpointName, "Obstacles now:", self.obstacles)
		return true
	end
	return false
end

function PlayerService:spawn()
	local character = self.player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	character:WaitForChild("Humanoid").CameraOffset = Vector3.new(0, 0, 0)

	if self.checkpoint then
		local checkpointPart = CONFIG.Checkpoints.Folder:FindFirstChild(self.checkpoint)
		if checkpointPart then
			hrp.CFrame = checkpointPart.CFrame * CFrame.new(0, CONFIG.Checkpoints.SpawnHeight, 0)
			debugPrint("Spawned at checkpoint:", self.checkpoint, "for", self.player.Name)
			return
		end
	end

	local spawnLocation = workspace:FindFirstChildOfClass("SpawnLocation")
	if spawnLocation then
		hrp.CFrame = spawnLocation.CFrame * CFrame.new(0, CONFIG.Checkpoints.SpawnHeight, 0)
		debugPrint("Spawned at default SpawnLocation for", self.player.Name)
	else
		warn("No SpawnLocation found in workspace! Player might not spawn correctly for", self.player.Name)
	end
end

function PlayerService:prestige()
	debugPrint(self.player.Name, "initiating prestige process.")

	-- Reset stats
	self.obstacles = 0
	self.checkpoint = nil
	self.obstaclesStat.Value = 0
	self.prestigeLevel += 1
	self.prestigeStat.Value = self.prestigeLevel

	-- Asynchronously save the prestige change and remove checkpoint data
	task.spawn(function()
		local successP, errP = pcall(function()
			CONFIG.Prestige.DataStore:SetAsync("player_"..self.userId, self.prestigeLevel)
		end)
		if not successP then warn("[CheckpointSystem] Error saving prestige data async for", self.player.Name, ":", errP) end

		local successC, errC = pcall(function()
			CONFIG.Checkpoints.DataStore:RemoveAsync("player_"..self.userId)
		end)
		if not successC then warn("[CheckpointSystem] Error removing checkpoint data async for", self.player.Name, ":", errC) end
	end)

	-- 1. Fire the total checkpoint count. The client will use the 'ObstaclesCompleted' stat which is now 0.
	Events.InitProgress:FireClient(self.player, TOTAL_CHECKPOINTS)

	-- 2. Give the client a tiny moment to process the event BEFORE we destroy their GUI
	task.wait(0.1)

	-- 3. Load the character (This forces the LocalScript to stop and reload)
	self.player:LoadCharacter()

	debugPrint(self.player.Name, "prestiged to level", self.prestigeLevel)
	return true
end

-----------[ SYSTEM INITIALIZATION ]-----------

local activePlayers = {}

local function setupSystem()
	-- Calculate the total number of checkpoints once at setup
	for _, checkpoint in ipairs(CONFIG.Checkpoints.Folder:GetChildren()) do
		if checkpoint:IsA("BasePart") and checkpoint.Name:match("^Checkpoint%d+$") then
			TOTAL_CHECKPOINTS += 1
		end
	end
	debugPrint("Total checkpoints found:", TOTAL_CHECKPOINTS)

	-- Set up checkpoint triggers
	for _, checkpoint in ipairs(CONFIG.Checkpoints.Folder:GetDescendants()) do
		if checkpoint:IsA("BasePart") and checkpoint.Name:match("^Checkpoint%d+$") then
			checkpoint.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and activePlayers[player] then
					activePlayers[player]:reachedCheckpoint(checkpoint.Name)
				end
			end)
		end
	end
	debugPrint("Checkpoint triggers initialized.")

	-- Player joining
	Players.PlayerAdded:Connect(function(player)
		local service = PlayerService.new(player)
		activePlayers[player] = service

		task.spawn(function()
			service:loadData()

			-- Fire the total checkpoint count after data loads
			Events.InitProgress:FireClient(player, TOTAL_CHECKPOINTS)

			player.CharacterAdded:Connect(function()
				service:spawn()
			end)

			if player.Character then
				service:spawn()
			end
		end)
	end)

	-- Player leaving
	Players.PlayerRemoving:Connect(function(player)
		if activePlayers[player] then
			activePlayers[player]:saveData()
			activePlayers[player] = nil
		end
	end)

	-- Auto-create default checkpoint if none exists
	if #CONFIG.Checkpoints.Folder:GetChildren() == 0 then
		local checkpoint = Instance.new("Part")
		checkpoint.Name = "Checkpoint1"
		checkpoint.Anchored = true
		checkpoint.Size = Vector3.new(10, 2, 10)
		checkpoint.Position = Vector3.new(0, 5, 0)
		checkpoint.BrickColor = BrickColor.new("Bright blue")
		checkpoint.Transparency = 0.5
		checkpoint.Parent = CONFIG.Checkpoints.Folder
		debugPrint("Created default checkpoint: Checkpoint1")

		-- Update the total count if we create a default one
		TOTAL_CHECKPOINTS = 1
	end
end

setupSystem()

return {
	GetPlayerService = function(player)
		return activePlayers[player]
	end
}