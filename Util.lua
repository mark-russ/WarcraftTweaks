local AddonName, WTweaks = ...

function WTweaks:CreateFontOptions(defaultSize, minSize, maxSize, showOutline, onSetCallbackFunc)
	return {
		FontFile = {
			name = "Font",
			dialogControl = "LSM30_Font",
			order = 0,
			type = "select",
			values = function()
				return WTweaks.Options.Fonts
			end,
			set = onSetCallbackFunc
		},
		FontSize = {
			name = "Font Size",
			order = 1,
			type = "range",
			step = 1,
			default = defaultSize,
			min = minSize,
			max = maxSize,
			set = onSetCallbackFunc
		},
		FontOutline = {
			name = "Font Outline",
			order = 2,
			type = "select",
			values = {
				[""] = "Smooth",
				["OUTLINE"] = "Thin",
				["THICKOUTLINE"] = "Thick",
				["MONOCHROME"] = "Sharp"
			},
			default = "",
			set = onSetCallbackFunc
		}
	}
end

function WTweaks:NoOp() end

function WTweaks:GetFontFile(fontName)
    return WTweaks.Libs.SharedMedia:Fetch("font", fontName)
end

function WTweaks:IsFuncSaved(frame, funcName)
	if WTweaks.BlizzFuncs[frame] == nil then
		WTweaks.BlizzFuncs[frame] = {}
	end

	return WTweaks.BlizzFuncs[frame][funcName] ~= nil
end

function WTweaks:HookSecure(frame, funcName, func)
	-- Shift arguments
	if func == nil then
		func = funcName
		funcName = frame
		frame = _G
	end

	-- Ensure no duplicate hooks are created.
	if not WTweaks:IsFuncSaved(frame, funcName) then
		hooksecurefunc(frame, funcName, func)

		if WTweaks.BlizzFuncs[frame] == nil then
			WTweaks.BlizzFuncs[frame] = {}
		end

		WTweaks.BlizzFuncs[frame][funcName] = "secure"
	end
end

function WTweaks:GetNormalizedUnitFrame(frame)
    local normalized = {
        BFrame = frame,
        Unit = frame.unit,
        Portrait = frame.portrait,
		Content = nil,
        Text = {
            Name = frame.name,
            Level = frame.level,
            Health = nil,
            Mana = nil,
        },
        Bars = {
            Health = frame.healthbar,
            Mana = frame.manabar,
            HealthLoss = nil, -- Set only for player.
        }
    }

    if frame == PlayerFrame then
		normalized.Text.Name = PlayerName
        normalized.Text.Level = PlayerLevelText
        normalized.Bars.HealthLoss = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar.AnimatedLossBar
		normalized.Content = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
    elseif frame.TargetFrameContent ~= nil then
        normalized.Text.Level = frame.TargetFrameContent.TargetFrameContentMain.LevelText
		normalized.Content = frame.TargetFrameContent.TargetFrameContentMain
    end

    if frame.healthbar then
        normalized.Text.Health = frame.healthbar.TextString
    end

    if frame.manabar then
        normalized.Text.Mana = frame.manabar.TextString
    end

    return normalized
end

function WTweaks:HookEvent(eventName, callbackFunc)
	if WTweaks.NativeEvents[eventName] == nil then
		WTweaks.NativeEvents[eventName] = {}
		WTweaks.Frames.Main:RegisterEvent(eventName)
	end

	tinsert(WTweaks.NativeEvents[eventName], callbackFunc)
end

function WTweaks:HookFader(target, activator, time)
	activator:HookScript("OnEnter", function()
		UIFrameFadeIn(target, time, target:GetAlpha(), 1.0)
	end)

	activator:HookScript("OnLeave", function()
		UIFrameFadeOut(target, time, target:GetAlpha(), 0.0)
	end)
	
	if activator.DropDown ~= nil then
		EventRegistry:RegisterCallback("UIDropDownMenu.Hide", function()
			if UIDropDownMenu_GetCurrentDropDown() == activator.DropDown then
				if not WTweaks:IsMouseOverFrame(activator) then
				  UIFrameFadeOut(target, time, target:GetAlpha(), 0.0)
				end
			end
		end)
	end
end

function WTweaks:HookScript(eventName, callbackFunc)
	WTweaks.Frames.Main:HookScript(eventName, callbackFunc)
end

function WTweaks:DelayedCall(interval, callbackFunc)
	C_Timer.After(interval, callbackFunc);
end

function WTweaks:RepeatCall(interval, callbackFunc)
	C_Timer.NewTicker(interval, callbackFunc);
end

function WTweaks:IsMouseOverFrame(target)
	local focusedFrames = GetMouseFoci()
	
	for _, frameOfFocus in ipairs(focusedFrames) do
		if frameOfFocus == target then
			return true
		end
	end
	
    return false
end

function WTweaks:IsMouseOverAnyFrames(targets)
	local focused = GetMouseFoci()
	
	if focused then
		for _, ChildFrame in ipairs(targets) do
			if ChildFrame == focused or ChildFrame == focusedParent then
				return true
			end
		end
	end

    return false
end