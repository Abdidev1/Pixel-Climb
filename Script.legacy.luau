local Players = game:GetService("Players")

local GroupId = 36084878 -- Replace with your Roblox Group ID

local function updateGroupStatus(player)
	local success, result = pcall(function()
		return player:GetRankInGroup(GroupId)
	end)

	if success then
		player:SetAttribute("GroupRank", result)
	else
		warn("Group rank check failed for", player.Name)
		player:SetAttribute("GroupRank", 0)
	end
end

Players.PlayerAdded:Connect(function(player)
	updateGroupStatus(player)

	while player.Parent do
		task.wait(1) -- How often the system checks to see if the player has the gamepass
		updateGroupStatus(player)
	end
end)