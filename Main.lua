local AddonName, WTweaks = ...
local LibAddon = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0")
WTweaks.Version = GetAddOnMetadata(AddonName, "Version")

local DBName = AddonName
WTweaks.NativeEvents = {}
WTweaks.Modules = {}

function WTweaks:RegisterModule(moduleName)
	local module = {
		Name = moduleName,
		Settings = nil,
		OnProfileChanged = function() end,
		GetConfig = function()
			return {}
		end
	}

	tinsert(WTweaks.Modules, module)
	return module
end

function LibAddon:OnInitialize()
	for _, module in ipairs(WTweaks.Modules) do
		if module.OnInitialize then
			module:OnInitialize(self)
		end
	end
	
	WTweaks.Libs = {
		AceGUI = LibStub("AceGUI-3.0"),
		AceDB = LibStub("AceDB-3.0"),
		AceDBOptions = LibStub("AceDBOptions-3.0"),
		AceConfig = LibStub("AceConfig-3.0"),
		AceCfgDialog = LibStub("AceConfigDialog-3.0"),
		SharedMedia = LibStub("LibSharedMedia-3.0")
	}

	WTweaks.Frames = {
		Main = CreateFrame("FRAME", AddonName)
	}
	
	WTweaks.BlizzFuncs = {}
	WTweaks:LoadSharedMedia()
	WTweaks:InitConfig()
	
	-- Notify each module that everything's good.
	for _, mod in ipairs(WTweaks.Modules) do
		mod:OnModuleRegistered()
	end
	
    WTweaks:HookEvent("PLAYER_LOGIN", function()
		for _, module in ipairs(WTweaks.Modules) do
			if module.OnStarted then
				module:OnStarted(self)
			end
		end
	end)
	
    WTweaks:HookEvent("PLAYER_ENTERING_WORLD", function()
		for _, module in ipairs(WTweaks.Modules) do
			if module.OnPlayerEnteringWorld then
				module:OnPlayerEnteringWorld(self)
			end
		end
	end)
	
	-- As events happen, notify.
	WTweaks.Frames.Main:SetScript("OnEvent", function(self, event, ...)
		for _, callback in pairs(WTweaks.NativeEvents[event]) do
			callback(...)
		end
	end)
end

function WTweaks:LoadSharedMedia()
	WTweaks.Options = {
		Fonts = WTweaks.Libs.SharedMedia:HashTable("font"),
		Bars = WTweaks.Libs.SharedMedia:HashTable("statusbar")
	}
end

function WTweaks:GetConfig()
	WTweaks.ModuleConfigMap = {}
	
	WTweaks.Configuration = {
		type = "group",
		args = {}
	}

	-- Merge configuration groups into one group.
	for _, module in pairs(WTweaks.Modules) do
		local moduleConfig = module:GetConfig()

		for groupName, group in pairs(moduleConfig) do
			WTweaks.ModuleConfigMap[group] = module

			if group.parent then
				-- Reparent the group and remove the key to not break AceConfigDialog
				WTweaks.Configuration.args[group.parent].args[groupName] = group
				group.parent = nil
			else
				WTweaks.Configuration.args[groupName] = group
			end
		end
	end
	
	WTweaks.Defaults = {
		profile = {}
	}
	-- Populate defaults from our merged root.
	WTweaks:ExtractDefaultConfig(WTweaks.Configuration, WTweaks.Defaults.profile, nil)
end

function WTweaks:ExtractDefaultConfig(group, defaults, groupName)
	for optionName, option in pairs(group.args) do
		if option.type == "group" then
			defaults[optionName] = {}
			WTweaks:ExtractDefaultConfig(option, defaults[optionName], optionName)
		else
			-- Copy default over and remove it to not break AceConfigDialog
			local defaultValue = option.default
			defaults[optionName] = defaultValue
			option.default = nil
		end
	end
end

function WTweaks:SetupConfigWatchers(group, config, groupName, module)
	-- This is added by the profile manager. Do not watch.
	if groupName == "profile" then
		return
	end

	if groupName ~= nil and module == nil then
		module = WTweaks.ModuleConfigMap[group]
	end

	for optionName, option in pairs(group.args) do
		if option.type == "group" then
			local submodule = WTweaks.ModuleConfigMap[option]
			WTweaks:SetupConfigWatchers(option, config[optionName], optionName, submodule or module)
		else
			-- Colors are a special structure, so we give them a special vararg getter/setter.
			if (option.type == "color") then
				option.set = function(info, ...)
					local name = info[#info]
					config[name] = { ... }
	
					module:OnSettingChanged(config, name)
				end
				
				option.get = function(info)
					local name = info[#info]
					return unpack(config[name])
				end
			else
				local originalSetter = option.set
				option.set = function(info, ...)
					local name = info[#info]
					config[name] = ...

					if module.OnSettingChanged then
						module:OnSettingChanged(config, name)
					end
					
					if originalSetter ~= nil then
						originalSetter(info, config[name])
					end
				end
				
				local originalGetter = option.get
				option.get = function(info)
					local name = info[#info]

					if originalGetter ~= nil then
						return originalGetter(info)
					end

					return config[name]
				end
			end
		end
	end
end

function WTweaks:InitConfig()
	WTweaks:GetConfig()
	WTweaks.DB = WTweaks.Libs.AceDB:New(DBName, WTweaks.Defaults, true)
	WTweaks.DB:RegisterDefaults(WTweaks.Defaults)
	WTweaks:SetupConfigWatchers(WTweaks.Configuration, WTweaks.DB.profile, nil, nil)

 	for _, module in pairs(WTweaks.Modules) do
		module.Settings = WTweaks.DB.profile
 	end
	
	WTweaks.Libs.AceConfig:RegisterOptionsTable(AddonName, WTweaks.Configuration)
end

function WTweaks:HookEvent(eventName, callbackFunc)
	if WTweaks.NativeEvents[eventName] == nil then
		WTweaks.NativeEvents[eventName] = {}
		WTweaks.Frames.Main:RegisterEvent(eventName)
	end

	tinsert(WTweaks.NativeEvents[eventName], callbackFunc)
end

function WTweaks:HookScript(eventName, callbackFunc)
	WTweaks.Frames.Main:HookScript(eventName, callbackFunc)
end

function WTweaks:Repeat(interval, callbackFunc)
	local startTime = 0

	WTweaks:HookScript("OnUpdate", function(self, elapsed)
		startTime = startTime + elapsed

		if startTime > interval then
			startTime = startTime - interval
			callbackFunc()
		end
	end)
end

function WTweaks:IsFuncSaved(frame, funcName)
	if WTweaks.BlizzFuncs[frame] == nil then
		WTweaks.BlizzFuncs[frame] = {}
	end

	return WTweaks.BlizzFuncs[frame][funcName] ~= nil
end

function WTweaks:RemoveFunc(frame, funcName)
	-- Back the function up.
	if not WTweaks:IsFuncSaved(frame, funcName) then
		WTweaks.BlizzFuncs[frame][funcName] = frame[funcName]
	end

	-- Replace the original with no-op.
	frame[funcName] = WTweaks.NoOp
end

function WTweaks:RestoreFunc(frame, funcName)
	-- If the function was saved.
	if WTweaks:IsFuncSaved(frame, funcName) then
		frame[funcName] = WTweaks.BlizzFuncs[frame][funcName]
		WTweaks.BlizzFuncs[frame][funcName] = nil
	end
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

function WTweaks:LoadFrame(frame)
	local frameName = frame:GetName()

	if WTweaks.DB.profile.Frames == nil or WTweaks.DB.profile.Frames[frameName] == nil then
		return
	end

	frame:ClearAllPoints()
	frame:SetPoint(unpack(WTweaks.DB.profile.Frames[frameName].Point))
end

function WTweaks:SaveFrame(frame)
	if WTweaks.DB.profile.Frames == nil then
		WTweaks.DB.profile.Frames = {}
	end

	local frameName = frame:GetName()

	WTweaks.DB.profile.Frames[frameName] = { 
		Size = { frame:GetSize() },
		Point = { frame:GetPoint() }
	}
end

function WTweaks:MakeFrameDraggable(frame, draggerFrame)
	if draggerFrame == nil then
		draggerFrame = frame
	end

	frame:SetMovable(true)

	draggerFrame:EnableMouse(true)
	draggerFrame:RegisterForDrag("LeftButton")

	draggerFrame:HookScript("OnDragStart", function()
		frame:StartMoving()
	end)

	draggerFrame:HookScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		WTweaks:SaveFrame(frame)
	end)
end

function WTweaks:ShowButtonTooltip(frame, title, text)
	GameTooltip:SetOwner(frame)
	GameTooltip_SetTitle(GameTooltip, title)
	GameTooltip_AddNormalLine(GameTooltip, text)
	GameTooltip:Show()
end

function WTweaks:CreateButton(parent, normalTexture, pushTexture, hoverTexture, width, height, title, text)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")

	if normalTexture ~= nil then
		btn:SetNormalTexture(normalTexture)
	end

	btn:SetPushedTexture(pushTexture and pushTexture or normalTexture)
	btn:SetHighlightTexture(hoverTexture and hoverTexture or "Interface/Buttons/ButtonHilight-Square", "ADD")

	btn:SetSize(width, height)
	
	btn:SetScript("OnEnter", function(self)
		WTweaks:ShowButtonTooltip(self, title, text)
	end)

	btn:SetScript("OnLeave", GameTooltip_Hide)
	return btn
end

function WTweaks:GetBagFrame()
	return ContainerFrameSettingsManager:IsUsingCombinedBags() and ContainerFrameCombinedBags or ContainerFrame1
end

function WTweaks:Ternary(condition, trueResult, falseResult)
	if condition then
		return trueResult
	else
		return falseResult
	end
end

function WTweaks:GetStatusBar(frame)
    local statusBar = frame:GetStatusBarTexture()

    return {
        texture = statusBar:GetTexture(),
        atlas = statusBar:GetAtlas(),
		color = WTweaks:ColorArrayToRGBA({ frame:GetStatusBarColor() })
    }
end

function WTweaks:SetStatusBar(frame, statusBar)
    frame:SetStatusBarTexture(statusBar.texture)
    frame:GetStatusBarTexture():SetAtlas(statusBar.atlas, TextureKitConstants.UseAtlasSize)
	frame:SetStatusBarColor(statusBar.color.r, statusBar.color.g, statusBar.color.b, statusBar.color.a)
end

function WTweaks:ColorArrayToRGBA(color)
    return {
        r = color[1],
        g = color[2],
        b = color[3],
        a = color[4] or 1
    }
end

function WTweaks:IsMouseOverAnyFrames(targets)
	local focused = GetMouseFocus()
	
	if focused then
		for _, ChildFrame in ipairs(targets) do
			if ChildFrame == focused or ChildFrame == focusedParent then
				return true
			end
		end
	end

    return false
end

function WTweaks:HookFader(target, frames, time)
    for _, ChildFrame in ipairs(frames) do
        ChildFrame:HookScript("OnEnter", function()
            UIFrameFadeIn(target, time, target:GetAlpha(), 1.0)
        end)

        ChildFrame:HookScript("OnLeave", function()
            if not WTweaks:IsMouseOverAnyFrames(frames) then
              UIFrameFadeOut(target, time, target:GetAlpha(), 0.0)
            end
        end)
        
        if ChildFrame.DropDown ~= nil then
            EventRegistry:RegisterCallback("UIDropDownMenu.Hide", function()
                if UIDropDownMenu_GetCurrentDropDown() == ChildFrame.DropDown then
                    if not WTweaks:IsMouseOverAnyFrames(frames) then
                      UIFrameFadeOut(target, time, target:GetAlpha(), 0.0)
                    end
                end
            end)
        end
    end
end

function WTweaks:PrintTable(table, depth)
	local depth = (depth or -5) + 5 
	local indentation = string.rep(" ", depth)
	for elementName, element in pairs(table) do
		local elementType = type(element)

		if elementType == "table" then
			print(indentation .. elementName .. " {")
			WTweaks:PrintTable(element, depth)
			print(indentation .. "}")
		else
			local elementValue = WTweaks:Ternary(elementType == "string", "\"" .. tostring(element) .. "\"", tostring(element))
			print(indentation .. elementName .. " = " .. elementValue)
		end
	end
end

function WTweaks:AddOptionPage(label, path, parent)
	WTweaks.Libs.AceCfgDialog:AddToBlizOptions(AddonName, label, parent, path)
end

function WTweaks:GetFontOptions(path)
	for k, v in pairs(path) do
		print(k)
	end
	
	return {
		path.FontFile,
		path.FontSize,
		path.ShowFontOutline and "OUTLINE" or "" 
	}
end

function WTweaks:CreateFontOptions(defaultSize, minSize, maxSize, showOutline)
	return {
		FontFile = {
			name = "Font",
			dialogControl = "LSM30_Font",
			order = 0,
			type = "select",
			values = function()
				return WTweaks.Options.Fonts
			end
		},
		FontSize = {
			name = "Font Size",
			order = 1,
			type = "range",
			step = 1,
			default = defaultSize,
			min = minSize,
			max = maxSize
		},
		ShowFontOutline = {
			name = "Font Outline",
			order = 2,
			type = "toggle",
			default = showOutline
		}
	}
end

function WTweaks:Merge(source, destination)
	for k, v in pairs(source) do
		destination[k] = v
	end
end

function WTweaks:NoOp() end