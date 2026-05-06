--!strict
-- ServerSkipStageHandler.luau
-- Validates and processes stage-skip requests from clients (e.g. VIP/gamepass).
-- All authority stays on the server; the client only sends a request.
-- Runs in ServerScriptService.

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CheckpointSystem = require(script.Parent:WaitForChild("CheckpointAndLeaderboard"))

-- Gamepass IDs that grant skip access. Add as needed.
local SKIP_GAMEPASSES: { [string]: number } = {
	Stage50  = 0, -- replace with actual gamepass IDs
	Stage100 = 0,
	Stage150 = 0,
	Stage200 = 0,
}

-- Remote event the client fires to request a skip
local SkipStageEvent: RemoteEvent = ReplicatedStorage:FindFirstChild("RequestSkipStage")
	or (function()
		local e    = Instance.new("RemoteEvent")
		e.Name     = "RequestSkipStage"
		e.Parent   = ReplicatedStorage
		return e
	end)()

local function playerOwnsPass(player: Player, passId: number): boolean
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
	end)
	return ok and owns == true
end

local function teleportToStage(player: Player, stageNumber: number)
	local checkpointName = "Checkpoint" .. stageNumber
	local folder = workspace:FindFirstChild("Checkpoints")
	if not folder then
		warn("[SkipStage] Checkpoints folder not found.")
		return
	end

	local part = folder:FindFirstChild(checkpointName)
	if not part or not part:IsA("BasePart") then
		warn("[SkipStage] Checkpoint part not found:", checkpointName)
		return
	end

	local character = player.Character
	local hrp       = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Only advance progress, never move the player backwards
	local service = CheckpointSystem.GetPlayerService(player)
	if service then
		service:reachedCheckpoint(checkpointName)
	end

	hrp.CFrame = part.CFrame * CFrame.new(0, 3, 0)
end

SkipStageEvent.OnServerEvent:Connect(function(player: Player, targetStage: number)
	-- Validate input type
	if type(targetStage) ~= "number" then return end

	local stageKey = "Stage" .. targetStage
	local passId   = SKIP_GAMEPASSES[stageKey]

	if not passId or passId == 0 then
		warn("[SkipStage] No gamepass configured for stage", targetStage)
		return
	end

	if not playerOwnsPass(player, passId) then
		warn("[SkipStage] Player", player.Name, "does not own pass for stage", targetStage)
		return
	end

	teleportToStage(player, targetStage)
end)
