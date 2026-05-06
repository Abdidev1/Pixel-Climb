--!strict
-- SpeedCoil.luau
-- LocalScript placed inside the Speed Coil tool.
-- Increases the player's walk speed while equipped.

local tool      = script.Parent
local character = nil
local humanoid  = nil

local BOOSTED_SPEED = 50
local DEFAULT_SPEED = 16

tool.Equipped:Connect(function()
	character = tool.Parent
	humanoid  = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = BOOSTED_SPEED
	end
end)

tool.Unequipped:Connect(function()
	if humanoid then
		humanoid.WalkSpeed = DEFAULT_SPEED
	end
end)
