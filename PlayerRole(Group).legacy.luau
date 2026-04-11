local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

-- The ID of your Roblox group
local GROUP_ID = 36084878 

-- A dictionary to map group rank IDs to badge IDs
-- You can find your group's rank IDs by going to your group's "Configure" page, then "Roles"
-- The number next to each role name is its rank ID.
-- Replace the placeholder numbers with your actual Rank IDs and Badge IDs.
local rankBadges = {
	[255] = 2505322608908039,  
	[254] = 2622950078850162, 
	[250] = 2860826206496381, 
	[200] = 3487839104087062, 
	[1] = 2413034055308546, 
}

local function awardGroupBadge(player)
	-- Get the player's current rank in the group
	local playerRank = player:GetRankInGroup(GROUP_ID)

	-- Check if the player's rank is in our `rankBadges` table
	if rankBadges[playerRank] then
		local badgeId = rankBadges[playerRank]

		-- Check if the player already has the badge to avoid awarding it again
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)

		if success and not hasBadge then
			-- Award the badge
			local awarded, errorMessage = pcall(function()
				return BadgeService:AwardBadge(player.UserId, badgeId)
			end)

			if not awarded then
				warn("Error awarding badge:", errorMessage)
			else
				print("Successfully awarded badge " .. badgeId .. " to " .. player.Name)
			end
		end
	end
end

-- Connect the function to fire when a player joins the game
Players.PlayerAdded:Connect(awardGroupBadge)