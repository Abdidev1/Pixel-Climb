-- Script in ServerScriptService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local BADGE_ID = 888930850133877 -- !! IMPORTANT: Replace 0 with your actual Badge ID from the Roblox website !!
-- You can find the ID in the URL of your badge's page (e.g., roblox.com/badges/1234567/...)

local RequestPrestigeConfirm = ReplicatedStorage:WaitForChild("RequestPrestigeConfirm")
print("Server: RequestPrestigeConfirm handler script initialized.")

-- Function to handle the prestige request from the client
local function onPrestigeRequested(player, wantsToPrestige)
	print("Server: Prestige request received from " .. player.Name .. ". Wants to prestige: " .. tostring(wantsToPrestige))

	if wantsToPrestige then
		-- 1. Perform all necessary server-side checks and actions here
		-- (e.g., checking if the player meets all prestige requirements, resetting stats, etc.)

		-- 2. Grant the Badge
		local success, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID)
		end)

		if success then
			if not hasBadge then
				local grantedSuccess, errorMessage = pcall(function()
					BadgeService:AwardBadge(player.UserId, BADGE_ID)
				end)

				if grantedSuccess then
					print("Server: Successfully awarded Badge ID " .. BADGE_ID .. " to " .. player.Name .. "!")
				else
					warn("Server: Failed to award badge to " .. player.Name .. ": " .. (errorMessage or "Unknown error"))
				end
			else
				print("Server: " .. player.Name .. " already has Badge ID " .. BADGE_ID .. ".")
			end
		else
			warn("Server: Failed to check if user has badge for " .. player.Name .. ".")
		end

		-- 3. Now you can disable the GUI for the player
		local playerGui = player:FindFirstChild("PlayerGui")
		local prestigeGui = playerGui and playerGui:FindFirstChild("PrestigeConfirmGui")

		if prestigeGui then
			prestigeGui.Enabled = false
			print("Server: Disabled PrestigeConfirmGui for " .. player.Name)
		end
	else
		-- Handle 'No' button logic (just disable the GUI)
		local playerGui = player:FindFirstChild("PlayerGui")
		local prestigeGui = playerGui and playerGui:FindFirstChild("PrestigeConfirmGui")

		if prestigeGui then
			prestigeGui.Enabled = false
			print("Server: Disabled PrestigeConfirmGui for " .. player.Name .. " (User declined).")
		end
	end
end

-- Connect the server function to the RemoteEvent
RequestPrestigeConfirm.OnServerEvent:Connect(onPrestigeRequested)