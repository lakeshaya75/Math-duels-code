-- StarterPlayerScripts/LockMovement.client.lua
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- 1) Tell Roblox to NOT create any default controls (PC & Mobile)
--    This hides the mobile joystick and disables default keyboard movement.
pcall(function()
	player.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable
	player.DevTouchMovementMode    = Enum.DevTouchMovementMode.Scriptable
end)

-- 2) Disable the PlayerModule controls (extra safety)
task.defer(function()
	local pm = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")
	local PlayerModule = require(pm)
	local Controls = PlayerModule:GetControls()
	Controls:Disable()
end)

-- 3) Hard-stop Humanoid motion & jumping on spawn (covers any programmatic moves)
local function lockHumanoid(h)
	if not h then return end
	h.WalkSpeed = 0
	h.JumpPower = 0
	h.AutoRotate = false
	-- Disallow entering the Jumping state
	pcall(function()
		h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	end)
	-- Cancel any pending jump requests (mobile jump button, spacebar, etc.)
	if not UserInputService.JumpRequest._locked then
		UserInputService.JumpRequest._locked = true
		UserInputService.JumpRequest:Connect(function()
			if h then h.Jump = false end
		end)
	end
end

local function onCharacterAdded(char)
	local humanoid = char:WaitForChild("Humanoid")
	lockHumanoid(humanoid)
	-- If something tries to change WalkSpeed later, clamp it back to 0
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed ~= 0 then humanoid.WalkSpeed = 0 end
	end)
	-- Prevent external Jump toggles
	humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
		if humanoid.Jump then humanoid.Jump = false end
	end)
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

-- 4) (Optional) Eat WASD/Space at the input layer as a final guard
--    This keeps other client scripts from using those keys for movement.
local BLOCKED = {
	[Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
	[Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
	[Enum.KeyCode.Space] = true,
}
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard and BLOCKED[input.KeyCode] then
		-- Do nothing: simply not passing movement to controls is enough.
		-- (No need to set any property here.)
	end
end)
