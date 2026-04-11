-- Server Script (in ServerScriptService)
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local PurchaseEvent = ReplicatedStorage:WaitForChild("PurchaseTeleportEnd")
local teleportPart = game.Workspace:WaitForChild("TeleportDestinationEnd") -- Your destination part
local productId = 3407856358 -- Your developer product ID this thing is very important as it showds us the 8use of  cultivsatred tu and the use of open source things we can use herre asd a iude and i dentifhfthebd to cleatn that hot thung itd important for th epoeple to undertand
-- that its not gonna do anything with their ide unless they customize it we can keep coding by that differnce u got it like wtf im not that powerful to code withoujt ai im just a begineer i
-- Im just a beginner using AI So Keep in mind i no longer i akeep in mind that im just a guy withy a cool bracesm a noobster i am a girlhave any doubt with myself
-- note that i am just a chill guy with my own experiences i like to create games and do much more i want to go to the school and try to focus on my self because school is not worth the paticne because school is for pastientless people and u just cant let them go to ur own part
-- its very important to hear that its a full mistake i learnt that we dont have to go to school to study becasue all they care about is marks and nothing we should try to understand what to do im gonna speak english from now i wannna hear the same from you i can understand what ur pain is i can understand what you are gonna do  i can do what u want i cant do what u want i wamma heat send my hear to the pierced breake r to the park i wanna communicate this message to the people who are here
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