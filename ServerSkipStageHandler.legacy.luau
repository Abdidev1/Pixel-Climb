-- ServerScriptService/SkipStageSystem.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

-- REQUIRE YOUR CHECKPOINT MODULE HERE
-- Assuming CheckpointSystem is in the same parent folder as this script.
local CheckpointModule = require(script.Parent:WaitForChild("CheckpointAndLeaderboard")) 

-- Configuration
local CONFIG = {
	CheckpointsFolder = workspace:WaitForChild("Checkpoints"),
	SpawnHeight = 3,
	DebugMode = true
}

local SkipEvent = ReplicatedStorage:FindFirstChild("SkipStage") or Instance.new("RemoteEvent")
if not SkipEvent.Parent then
	SkipEvent.Name = "SkipStage"
	SkipEvent.Parent = ReplicatedStorage
end

-- You should also create a SkipFailed event for feedback to the client
local SkipFailedEvent = ReplicatedStorage:FindFirstChild("SkipFailed") or Instance.new("RemoteEvent")
if not SkipFailedEvent.Parent then
	SkipFailedEvent.Name = "SkipFailed"
	SkipFailedEvent.Parent = ReplicatedStorage
end


local function debugPrint(...)
	if CONFIG.DebugMode then
		print("[SkipStage]", ...)
	end
end

local function teleportToCheckpoint(player, checkpointName)
	local checkpoint = CONFIG.CheckpointsFolder:FindFirstChild(checkpointName)
	if not checkpoint then
		debugPrint("Checkpoint part not found:", checkpointName)
		return false
	end

	local character = player.Character
	if not character then
		-- Wait briefly for character, but don't hang forever
		character = player.CharacterAdded:Wait()
	end

	local hrp = character:WaitForChild("HumanoidRootPart", 2)
	if not hrp then
		debugPrint("HRP not found for", player.Name)
		return false
	end

	hrp.CFrame = checkpoint.CFrame + Vector3.new(0, CONFIG.SpawnHeight, 0)
	return true
end

local function handleSkip(player)
	-- Get the player's active service object from the CheckpointModule
	local playerService = CheckpointModule.GetPlayerService(player)

	if not playerService or not playerService.loaded then
		debugPrint("Player service not fully loaded for", player.Name)
		SkipFailedEvent:FireClient(player, "Data is still loading. Please wait a moment.")
		return
	end

	-- Determine next checkpoint using the data object
	local currentObstacle = playerService.obstacles
	local nextCheckpoint = "Checkpoint"..(currentObstacle + 1)

	debugPrint("Attempting to skip to:", nextCheckpoint)

	-- 1. Attempt teleport first
	if teleportToCheckpoint(player, nextCheckpoint) then

		-- 2. If teleport successful, update the progress using the core function
		-- This function handles: updating .obstacles, .checkpoint, leaderstats, and saving data.
		playerService:reachedCheckpoint(nextCheckpoint)

		debugPrint("Successfully skipped", player.Name, "to", nextCheckpoint)

	else
		debugPrint("Skip failed for", player.Name, "- Teleport failed.")
		SkipFailedEvent:FireClient(player, "Failed to skip stage: Checkpoint part not found in workspace.")
	end
end

SkipEvent.OnServerEvent:Connect(function(player)
	debugPrint("Skip request from:", player.Name)

	-- ** Add payment verification logic here (e.g., check for GamePass or currency) **

	handleSkip(player)
end)