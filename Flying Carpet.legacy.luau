-- Server Script to check for gamepass ownership and give the carpet

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage") -- Use ServerStorage to store the flying carpet model

-- IMPORTANT: Replace this with your actual Gamepass ID
local GAMEPASS_ID = 1448227936 

-- Make sure your flying carpet model is stored in ServerStorage and named "FlyingCarpet"
local flyingCarpet = ServerStorage:WaitForChild("FlyingCarpet")

local function giveFlyingCarpet(player)
	local carpetClone = flyingCarpet:Clone()
	carpetClone.Parent = player.Backpack
	print(player.Name .. " has received their flying carpet!")
end

-- This function gives the item to a player who just completed a purchase
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, purchasedGamepassID, wasPurchased)
	if wasPurchased and purchasedGamepassID == GAMEPASS_ID then
		giveFlyingCarpet(player)
	end
end)

-- This function gives the item to players who already own it when they join AND every time they respawn
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local success, ownsGamepass = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, GAMEPASS_ID)
		end)

		if success and ownsGamepass then
			giveFlyingCarpet(player)
		end
	end)
end)