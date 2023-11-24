local TOTP = require(game.ReplicatedStorage.totp)

local RobloxAuthenticator = script.Parent
local Body = RobloxAuthenticator.Body
local List = Body.List
local Head = RobloxAuthenticator.Head

local NavTitle = Head.NavTitle
local NavTitleHamburger = NavTitle.TextButton
local Settings = Head.Settings
local Options = Settings.Options

local OTPEntryTemplate = script.OTPEntry

local PFP = RobloxAuthenticator.Head.ImageLabel
PFP.Image = game:GetService("Players"):GetUserThumbnailAsync(game.Players.LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)

local OTPEntries = {}

--[[

	destroyOTPEntry(secret)
		Ensures proper deletion and eventual garbage collection for OTP entry

]]

local function destroyOTPEntry(secret)
	if not OTPEntries[secret] then return end

	task.cancel(OTPEntries[secret]["tasks"]["updateTimer"])
	task.cancel(OTPEntries[secret]["tasks"]["updateCode"])
	task.cancel(OTPEntries[secret]["tasks"]["closeToExpire"])

	OTPEntries[secret]["instance"]:Destroy()

	OTPEntries[secret] = nil
end

--[[

	setupOTPEntry(secret)
		Creates OTP entry instance
		Sets up loops to update code and timer
		Parents entry to player's ui
		
]]

local function setupOTPEntry(secret, provider, name)
	name = name or "Unnamed"
	
	if OTPEntries[secret] then
		destroyOTPEntry(secret)
	end
	
	local newOTPEntry = OTPEntryTemplate:Clone()
	newOTPEntry.ServiceName.Text = provider and ("%s: %s"):format(provider, name) or ("%s"):format(name)
	OTPEntries[secret] = {}
	OTPEntries[secret]["instance"] = newOTPEntry
	OTPEntries[secret]["tasks"] = {}
	OTPEntries[secret]["tasks"]["updateTimer"] = task.spawn(function()
		while true do
			newOTPEntry.TimerHolder.TimerText.Text = 30 - os.time() % 30
			task.wait(1)
		end
	end)
	OTPEntries[secret]["tasks"]["updateCode"] = task.spawn(function()
		while true do
			local code = TOTP.generate(secret, 0)
			newOTPEntry.ServiceCode.Text = ("%06s"):format(code):gsub("(%w%w%w)", "%1 "):gsub("%s$","")
			task.wait(1)
		end
	end)
	OTPEntries[secret]["tasks"]["closeToExpire"] = task.spawn(function()
		-- i am aware this code is a bunch of nested garbage, i was getting tired ok shut up ill fix it later
		while true do
			if 30 - os.time() % 30 <= 5 then
				newOTPEntry.ServiceCode.TextColor3 = Color3.fromHex("#dc8990")
				newOTPEntry.TimerHolder.TimerText.TextColor3 = Color3.fromHex("#dc8990")
				if os.time() % 2 == 0 then -- flashing effect
					newOTPEntry.ServiceCode.TextTransparency = 0.35
					newOTPEntry.TimerHolder.TimerText.TextTransparency = 0.35
				else
					newOTPEntry.ServiceCode.TextTransparency = 0
					newOTPEntry.TimerHolder.TimerText.TextTransparency = 0
				end
			else
				newOTPEntry.ServiceCode.TextColor3 = Color3.fromHex("#8ab4f8")
				newOTPEntry.TimerHolder.TimerText.TextColor3 = Color3.fromHex("#8ab4f8")
				newOTPEntry.ServiceCode.TextTransparency = 0
				newOTPEntry.TimerHolder.TimerText.TextTransparency = 0
			end
			task.wait(1)
		end
	end)
	newOTPEntry.Parent = List
end

local isSettingsOpen = false	
local settingTweenData = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)
local optionsTweenData = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0)

Options.Position = UDim2.new(-1, 0, 0, 0) -- set closed here as want to keep settngs accessible when editing in studio
Settings.BackgroundTransparency = 1
Settings.Visible = false

NavTitleHamburger.MouseButton1Click:Connect(function() -- afaik tweens garbage collect automatically
	if isSettingsOpen then
		isSettingsOpen = false
		
		local tween = game:GetService("TweenService"):Create(Options, optionsTweenData, {
			Position = UDim2.new(-1, 0, 0, 0)
		}) -- throw settings panel off screen
		tween:Play()
		
		local tween = game:GetService("TweenService"):Create(Settings, settingTweenData, {
			BackgroundTransparency = 1
		}) -- fade out background
		tween:Play()
		tween.Completed:Wait()
		
		Settings.Visible = false
	else
		isSettingsOpen = true
		
		Settings.Visible = true
		
		local tween = game:GetService("TweenService"):Create(Settings, settingTweenData, {
			BackgroundTransparency = 0.75
		}) -- fade in background
		tween:Play()
		
		local tween = game:GetService("TweenService"):Create(Options, optionsTweenData, {
			Position = UDim2.new(0, 0, 0, 0)
		}) -- throw settings panel on screen
		tween:Play()
		tween.Completed:Wait()
	end
end)

setupOTPEntry("XPXWBXUORWN5CJMZUYQQ5NPDKVRGFZSZ", "Roblox", "Demo") -- test entry
