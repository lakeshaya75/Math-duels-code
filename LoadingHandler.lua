local frame = script.Parent

local background = frame.Background
local backdrop = frame.Backdrop
local fill = backdrop.Fill

local mainFrame = frame.Parent.MainFrame
local logo = mainFrame.Logo
local play = mainFrame.PlayButton
local shop = mainFrame.ShopButton
local inv = mainFrame.InventoryButton
local help = mainFrame.HelpButton
local gp = mainFrame.GamepassButton

local tweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

fill.Size = UDim2.new(0, 0, 1, 0)
fill.Position = UDim2.new(0, 0, 0.5, 0)

local targetSize = UDim2.new(1, 0, 1, 0)
local targetPos = UDim2.new(0.5, 0, 0.5, 0)

local steps = 10
local duration = 0.15
local stepDelay = 1

local running = true

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

task.spawn(function()
	while running do
		local tweenRight = tweenService:Create(background, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0.52, 0, 0.5, 0)
		})
		tweenRight:Play()
		tweenRight.Completed:Wait()

		local tweenLeft = tweenService:Create(background, TweenInfo.new(8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Position = UDim2.new(0.48, 0, 0.5, 0)
		})
		tweenLeft:Play()
		tweenLeft.Completed:Wait()
	end
end)

for i = 1, steps do
	local progress = i / steps
	local randomOffset = math.random() * 0.1
	
	local newSize = UDim2.new(progress + randomOffset, 0, 1, 0)
	local newPos = UDim2.new((progress / 2) + (randomOffset / 2), 0, 0.5, 0)
	
	if newSize.X.Scale > 1 then newSize = targetSize end
	if newPos.X.Scale > 0.5 then newPos = targetPos end

	local tween = tweenService:Create(fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = newSize,
		Position = newPos
	})
	tween:Play()

	tween.Completed:Wait()
	task.wait(stepDelay * math.random())
end

running = false

local mainTween = tweenService:Create(mainFrame, TweenInfo.new(3, Enum.EasingStyle.Quart), {BackgroundTransparency = 0})
mainTween:Play()
mainTween.Completed:Wait(2)

frame.Visible = false

play.Interactable = false
shop.Interactable = false
inv.Interactable = false
help.Interactable = false
gp.Interactable = true

wait(1)

local logoTween = tweenService:Create(logo, TweenInfo.new(3, Enum.EasingStyle.Quart), {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.3, 0)})
logoTween:Play()
oneShot("rbxassetid://9044783668")
logoTween.Completed:Wait(1)

oneShot("rbxassetid://80281677741848")

play:TweenSize(UDim2.new(1, 0, 0.6, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.4)
shop:TweenSize(UDim2.new(0.5, 0, 0.3, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.4)
inv:TweenSize(UDim2.new(0.5, 0, 0.3, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.4)
help:TweenSize(UDim2.new(0.2, 0, 0.15, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.4)
gp:TweenSize(UDim2.new(0.2, 0, 0.15, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quart, 0.4)

wait(1)

play.Interactable = true
shop.Interactable = true
inv.Interactable = true
help.Interactable = true
gp.Interactable = true
mainFrame.LevelBG:TweenPosition(UDim2.new(0.075, 0, 0.1, 0))
