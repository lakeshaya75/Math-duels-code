local SoundService  = game:GetService("SoundService")
local TweenService  = game:GetService("TweenService")

local MUSIC_ID      = "rbxassetid://134960058966518"
local TARGET_VOLUME = 0.2
local FADE_TIME     = 5.0

local music = SoundService:FindFirstChild("LobbyMusic")
if not music then
	music = Instance.new("Sound")
	music.Name = "LobbyMusic"
	music.SoundId = MUSIC_ID
	music.Looped = true
	music.Volume = 0  
	music.PlaybackSpeed = 1
	music.RollOffMode = Enum.RollOffMode.Linear 
	music.Parent = SoundService
end

if not music.Playing then
	if not music.IsLoaded then music.Loaded:Wait() end
	music:Play()
end

TweenService:Create(music, TweenInfo.new(FADE_TIME), { Volume = TARGET_VOLUME }):Play()
