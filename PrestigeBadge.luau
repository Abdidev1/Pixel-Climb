--!strict
-- PrestigeBadge.luau
-- Awards badges to players when they reach prestige milestones.
-- Runs in ServerScriptService alongside PrestigeScript.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Map prestige level -> badge ID. Add or remove entries as needed.
local PRESTIGE_BADGES: { [number]: number } = {
	[1]  = 0000000001, -- replace with your actual badge IDs
	[5]  = 0000000002,
	[10] = 0000000003,
}

local PrestigeEvent: RemoteEvent = ReplicatedStorage:WaitForChild("PrestigeEvent")

PrestigeEvent.OnServerEvent:Connect(function(player: Player, prestigeLevel: number)
	local badgeId = PRESTIGE_BADGES[prestigeLevel]
	if not badgeId then return end

	local ok, alreadyHas = pcall(function()
		return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	if ok and not alreadyHas then
		local awarded, err = pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)
		if not awarded then
			warn("[PrestigeBadge] Failed to award badge", badgeId, "to", player.Name, ":", err)
		end
	end
end)
