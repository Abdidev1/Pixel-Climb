--!strict
-- PlayerRole.luau
-- Assigns in-game roles to players based on their Roblox group rank.
-- Runs in ServerScriptService.

local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")

-- Configuration
local GROUP_ID = 0  -- replace with your Roblox group ID

-- Map minimum group rank -> role name
-- Evaluated top-down; the first matching rank is assigned.
local RANK_ROLES: { { rank: number, role: string } } = {
	{ rank = 255, role = "Owner"     },
	{ rank = 200, role = "Developer" },
	{ rank = 100, role = "Moderator" },
	{ rank = 10,  role = "Member"    },
	{ rank = 1,   role = "Guest"     },
}

local function assignRole(player: Player)
	local ok, rank = pcall(function()
		return player:GetRankInGroup(GROUP_ID)
	end)

	if not ok then
		warn("[PlayerRole] Could not fetch group rank for", player.Name, ":", rank)
		return
	end

	local assignedRole = "Guest"
	for _, entry in ipairs(RANK_ROLES) do
		if rank >= entry.rank then
			assignedRole = entry.role
			break
		end
	end

	-- Store the role as a StringValue under the player for other scripts to read
	local roleValue       = Instance.new("StringValue")
	roleValue.Name        = "Role"
	roleValue.Value       = assignedRole
	roleValue.Parent      = player

	print(("[PlayerRole] %s assigned role: %s (rank %d)"):format(player.Name, assignedRole, rank))
end

Players.PlayerAdded:Connect(assignRole)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(assignRole, player)
end
