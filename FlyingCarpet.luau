--!strict
-- FlyingCarpet.luau
-- LocalScript placed inside the Flying Carpet tool.
-- Grants smooth flight to the player while the tool is equipped.

local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local tool      = script.Parent
local character = nil
local humanoid  = nil
local hrp       = nil
local equipped  = false

local FLY_SPEED   = 40
local LIFT_FORCE  = 0
local bodyVelocity: BodyVelocity = nil
local bodyGyro:     BodyGyro     = nil

local function createForces()
	bodyVelocity              = Instance.new("BodyVelocity")
	bodyVelocity.Velocity     = Vector3.zero
	bodyVelocity.MaxForce     = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Parent       = hrp

	bodyGyro                  = Instance.new("BodyGyro")
	bodyGyro.MaxTorque        = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.D                = 100
	bodyGyro.Parent           = hrp
end

local function removeForces()
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro     then bodyGyro:Destroy()     end
end

tool.Equipped:Connect(function()
	character = tool.Parent
	humanoid  = character:FindFirstChildOfClass("Humanoid")
	hrp       = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	equipped = true
	humanoid.PlatformStand = true
	createForces()

	RunService.Heartbeat:Connect(function()
		if not equipped or not hrp then return end

		local camera    = workspace.CurrentCamera
		local moveDir   = humanoid.MoveDirection
		local velocity  = moveDir * FLY_SPEED

		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
			velocity = velocity + Vector3.new(0, FLY_SPEED / 2, 0)
		elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
			velocity = velocity + Vector3.new(0, -FLY_SPEED / 2, 0)
		end

		bodyVelocity.Velocity = velocity
		if velocity.Magnitude > 0.1 then
			bodyGyro.CFrame = CFrame.lookAt(Vector3.zero, velocity)
		end
	end)
end)

tool.Unequipped:Connect(function()
	equipped = false
	if humanoid then humanoid.PlatformStand = false end
	removeForces()
end)
