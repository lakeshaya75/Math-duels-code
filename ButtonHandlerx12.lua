local SoundService = game:GetService("SoundService")

local function oneShot(id, parent, volume)
	local s = Instance.new("Sound")
	s.Name = "OneShot"
	s.SoundId = id:match("^rbxassetid://") and id or ("rbxassetid://"..id)
	s.Looped = false
	s.Volume = volume or 1
	s.RollOffMode = Enum.RollOffMode.Linear
	s.Parent = parent or SoundService
	if not s.IsLoaded then s.Loaded:Wait() end
	s:Play()
	s.Ended:Once(function() s:Destroy() end)
	return s
end

script.Parent.MouseButton1Click:Connect(function()
	oneShot("rbxassetid://9083627113", SoundService, 0.5)
end)
