local tweenService = game:GetService("TweenService")
local matchmakingEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes").Matchmaking
local tpEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes").TP
local getDataFunc = game:GetService("ReplicatedStorage"):WaitForChild("Remotes").GetData
local updDataEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes").UpdData

local frame = script.Parent

local playButton = frame.PlayButton
local shopButton = frame.ShopButton
local invButton = frame.InventoryButton
local helpButton = frame.HelpButton
local gpButton = frame.GamepassButton

local mmbar = frame.MMBar
local mmclose = mmbar.CloseButton
local timer = mmbar.Timer

local modebackdrop = frame.ModeBackdrop
local classic = modebackdrop.Classic
local survival = modebackdrop.Survival
local modeclose = modebackdrop.CloseButton

local shopFrame = frame.ShopBG
local invFrame = frame.InventoryBG
local helpFrame = frame.HelpBG
local gpFrame = frame.GamepassBG
local levelFrame = frame.LevelBG


local driftConnections = {}
local currentTweens = {}

local timerConnection = nil

local currentBanner = frame.Banner
local currentAvatar = frame.Avatar
local currentEmote1 = frame.Emote1
local currentEmote2 = frame.Emote2
local currentEmote3 = frame.Emote3
local currentCredits = frame.Credits
local currentXP = frame.XP

local data = getDataFunc:InvokeServer()

currentBanner.Value = data.banner
currentAvatar.Value = data.avatar
currentEmote1.Value = data.currEmotes[1] or ""
currentEmote2.Value = data.currEmotes[2] or ""
currentEmote3.Value = data.currEmotes[3] or ""
currentCredits.Value = data.credits
currentXP.Value = data.xp

for i, v in pairs(invFrame.BannerScroll:GetChildren()) do
	if v:IsA("ImageLabel") then
		if table.find(data.banners, v.Name) then
			v.Visible = true
		end
	end
end

for i, v in pairs(shopFrame.BannerScroll:GetChildren()) do
	if v:IsA("ImageLabel") then
		if table.find(data.banners, v.Name) then
			v.Button.Text.Text = "OWNED"
			v.Button.Image = "rbxassetid://92391409868014"
			v.Button.Interactable = false
		end
	end
end

for i, v in pairs(invFrame.AvatarScroll:GetChildren()) do
	if v:IsA("ImageLabel") then
		if table.find(data.avatars, v.Name) then
			v.Visible = true
		end
	end
end

for i, v in pairs(shopFrame.AvatarScroll:GetChildren()) do
	if v:IsA("ImageLabel") then
		if table.find(data.avatars, v.Name) then
			v.Button.Text.Text = "OWNED"
			v.Button.Image = "rbxassetid://92391409868014"
			v.Button.Interactable = false
		end
	end
end

for i, v in pairs(invFrame.EmoteScroll:GetChildren()) do
	if v:IsA("ImageLabel") then
		if table.find(data.emotes, v.Name) then
			v.Visible = true
		end
	end
end

for i, v in pairs(shopFrame.EmoteScroll:GetChildren()) do
	if v:IsA("ImageLabel") then
		if table.find(data.emotes, v.Name) then
			v.Button.Text.Text = "OWNED"
			v.Button.Image = "rbxassetid://92391409868014"
			v.Button.Interactable = false
		end
	end
end

shopFrame.CreditBG.CreditCount.Text = currentCredits.Value
local x = 0
local t = 0
while x <= currentXP.Value do
	x += (50 + t * 10)
	t += 1
end
levelFrame.Level.Text = "Level " .. t - 1
print(t-1)
levelFrame.XP.Text = "XP: " .. (currentXP.Value - (x - (50 + (t - 1) * 10))) .. "/" .. (50 + (t - 1) * 10)
print((currentXP.Value - (x - (50 + (t - 1) * 10))))
print((50 + (t - 1) * 10))

for i, v in pairs(invFrame.BannerScroll:GetChildren()) do
	if v:IsA("ImageLabel") and v.Visible == true then
		if v.Name == currentBanner.Value then
			v.Button.Text.Text = "EQUIPPED"
			v.Button.Image = "rbxassetid://92391409868014"
		else
			v.Button.Text.Text = "EQUIP"
			v.Button.Image = "rbxassetid://72507673176959"
		end
	end
end

for i, v in pairs(invFrame.AvatarScroll:GetChildren()) do
	if v:IsA("ImageLabel") and v.Visible == true then
		if v.Name == currentAvatar.Value then
			v.Button.Text.Text = "EQUIPPED"
			v.Button.Image = "rbxassetid://92391409868014"
		else
			v.Button.Text.Text = "EQUIP"
			v.Button.Image = "rbxassetid://72507673176959"
		end
	end
end

for i, v in pairs(invFrame.EmoteScroll:GetChildren()) do
	if v:IsA("ImageLabel") and v.Visible == true then
		if v.Name == currentEmote1.Value or v.Name == currentEmote2.Value or v.Name == currentEmote3.Value then
			v.Button.Text.Text = "EQUIPPED"
			v.Button.Image = "rbxassetid://92391409868014"
		else
			v.Button.Text.Text = "EQUIP"
			v.Button.Image = "rbxassetid://72507673176959"
		end
	end
end

local function startDrift(button)
	local drifting = true
	local origPos = button.Position

	local function driftLoop()
		while drifting do
			local offsetX = math.random(-2, 2) / 100 -- -0.05 to 0.05
			local offsetY = math.random(-2, 2) / 100
			local targetPos = origPos + UDim2.new(offsetX, 0, offsetY, 0)

			button:TweenPosition(targetPos, Enum.EasingDirection.InOut, Enum.EasingStyle.Quad, 5, true)
			wait(1.5)
		end
	end

	local thread = task.spawn(driftLoop)
	driftConnections[button] = function()
		drifting = false
		task.wait(0.1)
		button:TweenPosition(origPos, Enum.EasingDirection.InOut, Enum.EasingStyle.Sine, 0.4, true)
	end
end


local function onEnter(button, color)
	if currentTweens[button] then
		currentTweens[button]:Cancel()
	end
	
	local goalSize = UDim2.new(button.Size.X.Scale * 1.1, 0, button.Size.Y.Scale * 1.1, 0)
	local tween = tweenService:Create(button, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = goalSize, ImageColor3 = color})
	currentTweens[button] = tween
	tween:Play()
	tween.Completed:Wait()
end

local function onLeave(button, originalSize)
	if currentTweens[button] then
		currentTweens[button]:Cancel()
	end

	local tween = tweenService:Create(button, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = originalSize, ImageColor3 = Color3.fromRGB(255, 255, 255)})
	currentTweens[button] = tween
	tween:Play()
	tween.Completed:Wait()
end

playButton.MouseEnter:Connect(function() onEnter(playButton, Color3.fromRGB(0, 200, 0)) end)
shopButton.MouseEnter:Connect(function() onEnter(shopButton, Color3.fromRGB(0, 200, 0)) end)
invButton.MouseEnter:Connect(function() onEnter(invButton, Color3.fromRGB(0, 200, 0)) end)
helpButton.MouseEnter:Connect(function() onEnter(helpButton, Color3.fromRGB(0, 200, 0)) end)
gpButton.MouseEnter:Connect(function() onEnter(gpButton, Color3.fromRGB(0, 200, 0)) end)
mmclose.MouseEnter:Connect(function() onEnter(mmclose, Color3.fromRGB(255, 255, 255)) end)
classic.MouseEnter:Connect(function() onEnter(classic, Color3.fromRGB(200, 200, 0)) end)
survival.MouseEnter:Connect(function() onEnter(survival, Color3.fromRGB(200, 200, 0)) end)
modeclose.MouseEnter:Connect(function() onEnter(modeclose, Color3.fromRGB(255, 255, 255)) end)
shopFrame.CloseButton.MouseEnter:Connect(function() onEnter(modeclose, Color3.fromRGB(255, 255, 255)) end)
invFrame.CloseButton.MouseEnter:Connect(function() onEnter(modeclose, Color3.fromRGB(255, 255, 255)) end)
gpFrame.CloseButton.MouseEnter:Connect(function() onEnter(modeclose, Color3.fromRGB(255, 255, 255)) end)

playButton.MouseLeave:Connect(function() onLeave(playButton, UDim2.new(1, 0, 0.6, 0)) end)
shopButton.MouseLeave:Connect(function() onLeave(shopButton, UDim2.new(0.5, 0, 0.3, 0)) end)
invButton.MouseLeave:Connect(function() onLeave(invButton, UDim2.new(0.5, 0, 0.3, 0)) end)
helpButton.MouseLeave:Connect(function() onLeave(helpButton, UDim2.new(0.2, 0, 0.15, 0)) end)
gpButton.MouseLeave:Connect(function() onLeave(gpButton, UDim2.new(0.2, 0, 0.15, 0)) end)
mmclose.MouseLeave:Connect(function() onLeave(mmclose, UDim2.new(0.5, 0, 0.5, 0)) end)
classic.MouseLeave:Connect(function() onLeave(classic, UDim2.new(0.5, 0, 0.8, 0)) end)
survival.MouseLeave:Connect(function() onLeave(survival, UDim2.new(0.5, 0, 0.8, 0)) end)
modeclose.MouseLeave:Connect(function() onLeave(modeclose, UDim2.new(0.25, 0, 0.25, 0)) end)
shopFrame.CloseButton.MouseLeave:Connect(function() onLeave(modeclose, UDim2.new(0.15, 0, 0.15, 0)) end)
invFrame.CloseButton.MouseLeave:Connect(function() onLeave(modeclose, UDim2.new(0.15, 0, 0.15, 0)) end)
gpFrame.CloseButton.MouseLeave:Connect(function() onLeave(modeclose, UDim2.new(0.15, 0, 0.15, 0)) end)


playButton.MouseButton1Click:Connect(function()
	playButton.Interactable = false
	shopButton.Interactable = false
	invButton.Interactable = false
	
	modebackdrop:TweenSize(UDim2.new(0.7, 0, 0.7, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1)
end)

modeclose.MouseButton1Click:Connect(function()
	modebackdrop:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 1)
	
	wait(1)
	playButton.Interactable = true
	invButton.Interactable = true
	shopButton.Interactable = true
end)

classic.MouseButton1Click:Connect(function()
	matchmakingEvent:FireServer("Classic", true, frame.Banner.Value, frame.Avatar.Value, {frame.Emote1.Value, frame.Emote2.Value, frame.Emote3.Value})
	mmbar:TweenPosition(UDim2.new(0.5, 0, 0.15, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1)
	
	if timerConnection then
		timerConnection:Disconnect()
	end
	
	wait(0.5)
	modebackdrop:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 1)
	
	local elapsed = 0
	timer.Text = "0:00"

	-- Start a new timer
	timerConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		elapsed += dt
		local totalSeconds = math.floor(elapsed + 0.5)
		local minutes = math.floor(totalSeconds / 60)
		local seconds = totalSeconds % 60
		timer.Text = string.format("%d:%02d", minutes, seconds)
	end)
end)

survival.MouseButton1Click:Connect(function()
	matchmakingEvent:FireServer("Survival", true, frame.Banner.Value, frame.Avatar.Value, {frame.Emote1.Value, frame.Emote2.Value, frame.Emote3.Value})
	mmbar:TweenPosition(UDim2.new(0.5, 0, 0.15, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 1)
	
	if timerConnection then
		timerConnection:Disconnect()
	end
	
	wait(0.5)
	modebackdrop:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 1)
	
	local elapsed = 0
	timer.Text = "0:00"

	-- Start a new timer
	timerConnection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		elapsed += dt
		local totalSeconds = math.floor(elapsed + 0.5)
		local minutes = math.floor(totalSeconds / 60)
		local seconds = totalSeconds % 60
		timer.Text = string.format("%d:%02d", minutes, seconds)
	end)
end)

mmclose.MouseButton1Click:Connect(function()
	matchmakingEvent:FireServer("Any", false, frame.Banner.Value, frame.Avatar.Value, {frame.Emote1.Value, frame.Emote2.Value, frame.Emote3.Value})
	mmbar:TweenPosition(UDim2.new(0.5, 0, -0.3, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 1)
	
	wait(0.5)
	modebackdrop:TweenSize(UDim2.new(0.7, 0, 0.7, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 1)
	
	if timerConnection then
		timerConnection:Disconnect()
		timerConnection = nil
	end
end)

helpButton.MouseButton1Click:Connect(function()
	invButton.Interactable = false
	shopButton.Interactable = false
	playButton.Interactable = false
	helpButton.Interactable = false
	gpButton.Interactable = false
	helpFrame.CloseButton.Interactable = false
	helpFrame:TweenSize(UDim2.new(0.6, 0, 0.6, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	wait(0.5)
	helpFrame.CloseButton.Interactable = true
end)

helpFrame.CloseButton.MouseButton1Click:Connect(function()
	helpFrame.CloseButton.Interactable = false
	helpFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	wait(0.5)
	invButton.Interactable = true
	shopButton.Interactable = true
	playButton.Interactable = true
	helpButton.Interactable = true
	gpButton.Interactable = true
	helpFrame.CloseButton.Interactable = true
end)

gpButton.MouseButton1Click:Connect(function()
	invButton.Interactable = false
	shopButton.Interactable = false
	playButton.Interactable = false
	helpButton.Interactable = false
	gpButton.Interactable = false
	gpFrame.CloseButton.Interactable = false
	gpFrame:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	wait(0.6)
	gpFrame.CloseButton.Interactable = true
end)

gpFrame.CloseButton.MouseButton1Click:Connect(function()
	gpFrame.CloseButton.Interactable = false
	gpFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	wait(0.5)
	invButton.Interactable = true
	shopButton.Interactable = true
	playButton.Interactable = true
	helpButton.Interactable = true
	gpButton.Interactable = true
	gpFrame.CloseButton.Interactable = true
end)

shopButton.MouseButton1Click:Connect(function()
	invButton.Interactable = false
	shopButton.Interactable = false
	playButton.Interactable = false
	helpButton.Interactable = false
	gpButton.Interactable = false
	shopFrame.CreditBG.Visible = false
	
	shopFrame:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	shopFrame.CloseButton:TweenSize(UDim2.new(0.15, 0, 0.15, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	wait(0.5)
	
	local btnTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	
	local btween = tweenService:Create(shopFrame.BannerButton, btnTweenInfo, {Position = UDim2.new(0.2, 0, 0.87, 0)})
	local atween = tweenService:Create(shopFrame.AvatarButton, btnTweenInfo, {Position = UDim2.new(0.5, 0, 0.87, 0)})
	local etween = tweenService:Create(shopFrame.EmoteButton, btnTweenInfo, {Position = UDim2.new(0.8, 0, 0.87, 0)})
	
	shopFrame.BannerButton.Visible = true
	shopFrame.AvatarButton.Visible = true
	shopFrame.EmoteButton.Visible = true
	
	btween:Play()
	wait(0.1)
	atween:Play()
	wait(0.1)
	etween:Play()

	shopFrame.CreditBG.Visible = true
	shopFrame.CreditBG:TweenPosition(UDim2.new(0.5, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3)
	
	shopFrame.BannerScroll.Visible = true
	shopFrame.AvatarScroll.Visible = false
	shopFrame.EmoteScroll.Visible = false
end)

shopFrame.CloseButton.MouseButton1Click:Connect(function()
	shopFrame.CloseButton.Interactable = false
	shopFrame.CloseButton:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	
	shopFrame.CreditBG:TweenPosition(UDim2.new(0.5, 0, -0.3, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3)
	shopFrame.CreditBG.Visible = false
	
	local btnTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	
	local btween = tweenService:Create(shopFrame.BannerButton, btnTweenInfo, {Position = UDim2.new(0.2, 0, 1.87, 0)})
	local atween = tweenService:Create(shopFrame.AvatarButton, btnTweenInfo, {Position = UDim2.new(0.5, 0, 1.87, 0)})
	local etween = tweenService:Create(shopFrame.EmoteButton, btnTweenInfo, {Position = UDim2.new(0.8, 0, 1.87, 0)})
	
	btween:Play()
	wait(0.2)
	atween:Play()
	wait(0.2)
	etween:Play()
	wait(0.2)
	
	shopFrame.BannerButton.Visible = false
	shopFrame.AvatarButton.Visible = false
	shopFrame.EmoteButton.Visible = false
	
	shopFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	
	shopFrame.CloseButton.Interactable = true
	invButton.Interactable = true
	shopButton.Interactable = true
	playButton.Interactable = true
	helpButton.Interactable = true
	gpButton.Interactable = true
end)

invButton.MouseButton1Click:Connect(function()
	invButton.Interactable = false
	shopButton.Interactable = false
	playButton.Interactable = false
	helpButton.Interactable = false
	gpButton.Interactable = false
	
	invFrame:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	invFrame.CloseButton:TweenSize(UDim2.new(0.15, 0, 0.15, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	wait(1)

	local btnTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)

	local btween = tweenService:Create(invFrame.BannerButton, btnTweenInfo, {Position = UDim2.new(0.2, 0, 0.87, 0)})
	local atween = tweenService:Create(invFrame.AvatarButton, btnTweenInfo, {Position = UDim2.new(0.5, 0, 0.87, 0)})
	local etween = tweenService:Create(invFrame.EmoteButton, btnTweenInfo, {Position = UDim2.new(0.8, 0, 0.87, 0)})

	invFrame.BannerButton.Visible = true
	invFrame.AvatarButton.Visible = true
	invFrame.EmoteButton.Visible = true

	btween:Play()
	wait(0.2)
	atween:Play()
	wait(0.2)
	etween:Play()

	invFrame.BannerScroll.Visible = true
	invFrame.AvatarScroll.Visible = false
	invFrame.EmoteScroll.Visible = false
end)

invFrame.CloseButton.MouseButton1Click:Connect(function()
	invFrame.CloseButton.Interactable = false
	invFrame.CloseButton:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)
	
	local btnTweenInfo = TweenInfo.new(.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

	local btween = tweenService:Create(invFrame.BannerButton, btnTweenInfo, {Position = UDim2.new(0.2, 0, 1.87, 0)})
	local atween = tweenService:Create(invFrame.AvatarButton, btnTweenInfo, {Position = UDim2.new(0.5, 0, 1.87, 0)})
	local etween = tweenService:Create(invFrame.EmoteButton, btnTweenInfo, {Position = UDim2.new(0.8, 0, 1.87, 0)})

	btween:Play()
	wait(0.2)
	atween:Play()
	wait(0.2)
	etween:Play()
	wait(0.2)
	
	invFrame.BannerButton.Visible = false
	invFrame.AvatarButton.Visible = false
	invFrame.EmoteButton.Visible = false

	invFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.5)

	invFrame.CloseButton.Interactable = true
	invButton.Interactable = true
	shopButton.Interactable = true
	playButton.Interactable = true
	helpButton.Interactable = true
	gpButton.Interactable = true
end)

shopFrame.BannerButton.MouseButton1Click:Connect(function()
	shopFrame.BannerScroll.Visible = true
	shopFrame.AvatarScroll.Visible = false
	shopFrame.EmoteScroll.Visible = false
end)
shopFrame.AvatarButton.MouseButton1Click:Connect(function()
	shopFrame.BannerScroll.Visible = false
	shopFrame.AvatarScroll.Visible = true
	shopFrame.EmoteScroll.Visible = false
end)
shopFrame.EmoteButton.MouseButton1Click:Connect(function()
	shopFrame.BannerScroll.Visible = false
	shopFrame.AvatarScroll.Visible = false
	shopFrame.EmoteScroll.Visible = true	
end)

invFrame.BannerButton.MouseButton1Click:Connect(function()
	invFrame.BannerScroll.Visible = true
	invFrame.AvatarScroll.Visible = false
	invFrame.EmoteScroll.Visible = false
end)
invFrame.AvatarButton.MouseButton1Click:Connect(function()
	invFrame.BannerScroll.Visible = false
	invFrame.AvatarScroll.Visible = true
	invFrame.EmoteScroll.Visible = false
end)
invFrame.EmoteButton.MouseButton1Click:Connect(function()
	invFrame.BannerScroll.Visible = false
	invFrame.AvatarScroll.Visible = false
	invFrame.EmoteScroll.Visible = true	
end)

matchmakingEvent.OnClientEvent:Connect(function()
	print("received")
	if timerConnection then
		timerConnection:Disconnect()
	end
	
	mmclose.Interactable = false
	shopButton.Interactable = false
	invButton.Interactable = false
	
	timer.TextColor3 = Color3.fromRGB(0, 255, 0)
	mmbar.Text.TextColor3 = Color3.fromRGB(0, 255, 0)
	mmbar.Text.Text = "MATCH FOUND!"
end)

currentCredits:GetPropertyChangedSignal("Value"):Connect(function()
	shopFrame.CreditBG.CreditCount.Text = currentCredits.Value
	updDataEvent:FireServer({credits = currentCredits.Value})
end)

currentXP:GetPropertyChangedSignal("Value"):Connect(function()
	local sum = 0
	local i = 0
	while sum <= currentXP.Value do
		sum += (50 + i * 10)
		i += 1
	end
	levelFrame.Level.Text = "Level " .. i - 1
	levelFrame.XP.Text = "XP: " .. (currentXP.Value - (sum - (50 + (i - 1) * 10))) .. "/" .. (50 + (i - 1) * 10)
	updDataEvent:FireServer({xp = currentXP.Value})
	updDataEvent:FireServer({lvl = i - 1})
end)

currentBanner:GetPropertyChangedSignal("Value"):Connect(function()
	for i, v in pairs(invFrame.BannerScroll:GetChildren()) do
		if v:IsA("ImageLabel") and v.Visible == true then
			if v.Name == currentBanner.Value then
				v.Button.Text.Text = "EQUIPPED"
				v.Button.Image = "rbxassetid://92391409868014"
			else
				v.Button.Text.Text = "EQUIP"
				v.Button.Image = "rbxassetid://72507673176959"
			end
		end
	end
	updDataEvent:FireServer({banner = currentBanner.Value or ""})
end)

currentAvatar:GetPropertyChangedSignal("Value"):Connect(function()
	for i, v in pairs(invFrame.AvatarScroll:GetChildren()) do
		if v:IsA("ImageLabel") and v.Visible == true then
			if v.Name == currentAvatar.Value then
				v.Button.Text.Text = "EQUIPPED"
				v.Button.Image = "rbxassetid://92391409868014"
			else
				v.Button.Text.Text = "EQUIP"
				v.Button.Image = "rbxassetid://72507673176959"
			end
		end
	end
	updDataEvent:FireServer({avatar = currentAvatar.Value or ""})
end)

currentEmote1:GetPropertyChangedSignal("Value"):Connect(function()
	for i, v in pairs(invFrame.EmoteScroll:GetChildren()) do
		if v:IsA("ImageLabel") and v.Visible == true then
			if v.Name == currentEmote1.Value or v.Name == currentEmote2.Value or v.Name == currentEmote3.Value then
				v.Button.Text.Text = "EQUIPPED"
				v.Button.Image = "rbxassetid://92391409868014"
			else
				v.Button.Text.Text = "EQUIP"
				v.Button.Image = "rbxassetid://72507673176959"
			end
		end
	end
	updDataEvent:FireServer({currEmotes = {currentEmote1.Value, currentEmote2.Value, currentEmote3.Value} or {}})
end)

currentEmote2:GetPropertyChangedSignal("Value"):Connect(function()
	for i, v in pairs(invFrame.EmoteScroll:GetChildren()) do
		if v:IsA("ImageLabel") and v.Visible == true then
			if v.Name == currentEmote1.Value or v.Name == currentEmote2.Value or v.Name == currentEmote3.Value then
				v.Button.Text.Text = "EQUIPPED"
				v.Button.Image = "rbxassetid://92391409868014"
			else
				v.Button.Text.Text = "EQUIP"
				v.Button.Image = "rbxassetid://72507673176959"
			end
		end
	end
	updDataEvent:FireServer({currEmotes = {currentEmote1.Value, currentEmote2.Value, currentEmote3.Value} or {}})
end)

currentEmote3:GetPropertyChangedSignal("Value"):Connect(function()
	for i, v in pairs(invFrame.EmoteScroll:GetChildren()) do
		if v:IsA("ImageLabel") and v.Visible == true then
			if v.Name == currentEmote1.Value or v.Name == currentEmote2.Value or v.Name == currentEmote3.Value then
				v.Button.Text.Text = "EQUIPPED"
				v.Button.Image = "rbxassetid://92391409868014"
			else
				v.Button.Text.Text = "EQUIP"
				v.Button.Image = "rbxassetid://72507673176959"
			end
		end
	end
	updDataEvent:FireServer({currEmotes = {currentEmote1.Value, currentEmote2.Value, currentEmote3.Value} or {}})
end)

tpEvent.OnClientEvent:Connect(function(data)
	currentXP.Value += data["xp"]
	currentCredits.Value += data["credits"]
end)


