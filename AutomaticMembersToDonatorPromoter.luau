--!strict
-- AutomaticMembersToDonatorPromoter.luau
-- Automatically promotes group members to the Donator rank when they join,
-- provided they meet the configured criteria. Runs in ServerScriptService.

local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

local CONFIG = {
	GroupId          = 0,    -- replace with your Roblox group ID
	DonatorRankId    = 0,    -- rank number to promote to
	RequiredRankMin  = 1,    -- minimum current rank to be eligible
}

local function promoteIfEligible(player: Player)
	local ok, rank = pcall(function()
		return player:GetRankInGroup(CONFIG.GroupId)
	end)

	if not ok then
		warn("[DonatorPromoter] Could not fetch rank for", player.Name, ":", rank)
		return
	end

	if rank < CONFIG.RequiredRankMin or rank >= CONFIG.DonatorRankId then
		return -- already at or above target, or not a group member
	end

	-- GroupService:PromoteAsync is a premium API feature — guard with pcall
	local promoted, err = pcall(function()
		GroupService:PromoteAsync(CONFIG.GroupId, player.UserId)
	end)

	if not promoted then
		warn("[DonatorPromoter] Promotion failed for", player.Name, ":", err)
	else
		print("[DonatorPromoter] Promoted", player.Name, "to Donator.")
	end
end

Players.PlayerAdded:Connect(promoteIfEligible)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(promoteIfEligible, player)
end
