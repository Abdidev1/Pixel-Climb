--!strict
-- GravityCoil.luau
-- LocalScript placed inside the Gravity Coil tool.
-- Reduces the player's gravity while equipped.

local tool      = script.Parent
local character = nil
local humanoid  = nil

local GRAVITY_MULTIPLIER = 0.4 -- fraction of normal Roblox gravity (196.2)
local DEFAULT_GRAVITY    = workspace.Gravity

tool.Equipped:Connect(function()
	character = tool.Parent
	humanoid  = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.UseJumpPower   = true
		humanoid.JumpPower      = 75
		workspace.Gravity       = DEFAULT_GRAVITY * GRAVITY_MULTIPLIER
	end
end)

tool.Unequipped:Connect(function()
	workspace.Gravity = DEFAULT_GRAVITY
	if humanoid then
		humanoid.JumpPower = 50
	end
end)
