-- Server Script (in ServerScriptService)
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PurchaseEvent = ReplicatedStorage:WaitForChild("PurchaseTeleport100")
local teleportPart = game.Workspace:WaitForChild("TeleportDestination100") -- Your destination part
local productId = 3339948781 -- Your developer product ID

PurchaseEvent.OnServerEvent:Connect(function(player)
	-- Process purchase attempt
	MarketplaceService:PromptProductPurchase(player, productId)
end)

-- Handle successful purchases
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, receivedProductId, wasPurchased)
	if wasPurchased and receivedProductId == productId then -- Compare receivedProductId with the defined productId
		local player = Players:GetPlayerByUserId(userId) -- Get the Player object from the userId
		if player then -- Check if the player still exists (they might have left the game)
			if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
				player.Character.HumanoidRootPart.CFrame = teleportPart.CFrame
			end
		end
	end
end)