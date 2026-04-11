--[[
    GROUP ROLE PROMOTER SCRIPT
    Place this script in ServerScriptService.
    
    CRITICAL NOTE: Due to Roblox API limitations, it is NOT possible to automatically 
    detect *every* single Robux purchase (Game Pass or Developer Product) ever made in 
    the game without knowing the specific IDs of those items. 
    
    This script is the REQUIRED structure: you MUST list the IDs of the items that 
    qualify for the role.
    
    This version has been updated to specifically target players at Rank ID 1 and promote 
    them to Rank ID 200.
]]

-- SERVICES
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

-- CONFIGURATION (!!! EDIT THESE VALUES !!!)
local GROUP_ID = 36084878     -- Replace with your Group ID
local SOURCE_RANK_ID = 1     -- NEW: Only players at this exact Rank ID will be promoted.
local TARGET_RANK_ID = 200   -- Updated: The Rank ID of the new, higher role (e.g., 'Premium Buyer')

-- List all Product IDs and Game Pass IDs that grant this specific role. (REQUIRED)
-- For Developer Products, these are the IDs you created in the Creator Hub.
-- For Game Passes, these are the IDs of the passes.
local QUALIFYING_PRODUCT_IDS = {
	3335111685, -- Example Dev Product ID
	3339975706, -- Example Dev Product ID
	3339969250, -- Example Dev Product ID
	3339948781, -- Example Dev Product ID
	3407856358, -- Example Dev Product ID
	3355449735, -- Example Dev Product ID
	3297361021, -- Example Dev Product ID
	3395970789, -- Example Dev Product ID
	3355525790, -- Example Dev Product ID
	3355517841, -- Example Dev Product ID
	3355525195, -- Example Dev Product ID
	3355517288, -- Example Dev Product ID
	3355522852, -- Example Dev Product ID
	3355515128, -- Example Dev Product ID
	3355520012, -- Example Dev Product ID
	3355514448, -- Example Dev Product ID
	3355518928, -- Example Dev Product ID
	3355501269, -- Example Dev Product ID
	3392552660, -- Example Dev Product ID
}

local QUALIFYING_GAMEPASS_IDS = {
	1448227936, -- Example Game Pass ID
	1506468753, -- Example Game Pass ID
}

-- FUNCTIONS

-- Function to safely promote the player and handle checks
local function promotePlayer(player)
	-- Check if the player is in the group first
	local rank = player:GetRankInGroup(GROUP_ID)

	-- Promotion Logic: Promote ONLY if player is at the exact SOURCE_RANK_ID (1)
	if rank == SOURCE_RANK_ID then

		-- Attempt to set the new rank
		local success, result = pcall(function()
			return MarketplaceService:SetRankInGroup(player, GROUP_ID, TARGET_RANK_ID)
		end)

		if success then
			if result == true then
				print(`Player {player.Name} successfully promoted to Rank ID {TARGET_RANK_ID} in group {GROUP_ID}.`)
			else
				-- This usually means the rank was successfully set, but the API returns nil/false for some reason.
				warn(`Promotion attempt for {player.Name} returned non-true value. Check group settings.`)
			end
		else
			-- This handles permission issues, API throttling, or invalid group/rank IDs.
			warn(`Failed to promote player {player.Name}: {result}`)
		end

	elseif rank >= TARGET_RANK_ID then
		print(`Player {player.Name} is already at or above the target rank. No action needed.`)
	elseif rank == 0 then
		-- Player is not in the group. No promotion is possible.
		print(`Player {player.Name} is not in the group {GROUP_ID}. Skipping promotion.`)
	else
		-- Player is in the group but not at the required SOURCE_RANK_ID (1)
		print(`Player {player.Name} is in the group at Rank ID {rank}, which is not the required source rank {SOURCE_RANK_ID}. Skipping promotion.`)
	end
end

-- Function to check ownership of qualifying items on player join
local function checkExistingOwnership(player)
	-- Check Game Passes first
	for _, gamePassId in QUALIFYING_GAMEPASS_IDS do
		local ownsPass = MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamePassId)
		if ownsPass then
			print(`{player.Name} already owns Game Pass ID {gamePassId}. Checking for promotion...`)
			promotePlayer(player)
			return -- Exit once one qualifying item is found and promotion check is initiated
		end
	end

	-- Note: Checking ownership for Developer Products is complicated as they are consumable.
	-- We rely on the promotion logic within ProcessReceipt (below) to handle the initial
	-- purchase for Developer Products, and the group rank itself to prevent re-promotion.
end

-- MARKETPLACE SERVICE: PROCESS RECEIPT HANDLER
-- This runs whenever a player successfully purchases a Developer Product.
local function handleReceipt(receiptInfo)
	local productId = receiptInfo.ProductId
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)

	-- Check if the purchased product is one of the qualifying items
	local isQualifyingProduct = false
	for _, id in QUALIFYING_PRODUCT_IDS do
		if productId == id then
			isQualifyingProduct = true
			break
		end
	end

	if isQualifyingProduct and player then
		print(`Qualifying Developer Product ID {productId} purchased by {player.Name}. Attempting promotion...`)

		-- Promote the player immediately
		promotePlayer(player)

		-- Since the item grants a role, we consider the purchase granted.
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		-- Handle products not in our list, or if the player disconnected
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

-- MAIN SETUP

-- 1. Connect the purchase handler for Developer Products
MarketplaceService.ProcessReceipt = handleReceipt
print("MarketplaceService.ProcessReceipt is active for group promotion.")

-- 2. Connect the player join handler
Players.PlayerAdded:Connect(function(player)
	-- Give the player a short moment to fully load group data
	task.wait(1) 
	checkExistingOwnership(player)
end)

-- Handle any players already in the game when the script starts
for _, player in Players:GetPlayers() do
	checkExistingOwnership(player)
end