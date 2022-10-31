local AddonName, Vars = ...
local WTweaks = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0")
local DBName = "WarcraftTweaks"

WTweaksModules = {}

function WTweaks:GetConfig()
	local configuration = {}
	local defaults = {}
	
	for _, module in pairs(WTweaksModules) do
		local moduleConfig = module:GetConfig()
		
		for groupName, group in pairs(moduleConfig) do
			group["module"] = module
			configuration[groupName] = group
		end
	end
	
	-- Remove the "default" value from the options since AceConfig doesn't understand them.
	for groupName, optionGroup in pairs(configuration) do
		defaults[groupName] = {}

		if not optionGroup.set then
			local module = optionGroup["module"]
			optionGroup.set = function(info, value)
				WTweaks.DB.profile[groupName][info[#info]] = value

				module:OnSettingsChanged(WTweaks.DB.profile[groupName], groupName)
				WTweaks:OnSettingsChanged(WTweaks.DB.profile[groupName], groupName)
			end
			
			optionGroup.get = function(info)
				return WTweaks.DB.profile[groupName][info[#info]]
			end
		end

		optionGroup["module"] = nil

		for name, option in pairs(optionGroup.args) do
			defaults[groupName][name] = option.default
			option.default = nil
		end
	end

	WTweaks.Config = {
		profile = defaults
	}

	return {
		type = "group",
	  	args = configuration
	} 
end

function WTweaks:OnSettingsChanged(settings, groupName)
end

function WTweaks:LoadSharedMedia()
	local fonts = WTweaks.Libs.SharedMedia:List("font")

	WTweaks.Options = {
		Fonts = {}
	}
	
	for _, fontName in ipairs(fonts) do
		WTweaks.Options.Fonts[fontName] = fontName
	end
end

function WTweaks:InitConfig()
	WTweaks.NativeEvents = {
		-- MERCHANT_SHOW = WTweaks.OnMerchantOpened
	}
	
	local configuration = WTweaks:GetConfig()
	WTweaks.DB = WTweaks.Libs.AceDB:New(DBName, WTweaks.Config)
	WTweaks.Libs.AceConfig:RegisterOptionsTable(AddonName, configuration)
	WTweaks.Libs.AceCfgDialog:AddToBlizOptions(AddonName, AddonName, nil)

	
	for _, module in pairs(WTweaksModules) do
		for groupName, group in pairs(module:GetConfig()) do
			module:OnSettingsLoaded(WTweaks.DB.profile[groupName])
		end
	end
end

function WTweaks:OnInitialize()
	WTweaks:RegisterChatCommand("edit",  "OpenEditMode")
	WTweaks:RegisterChatCommand("tweaks", "OpenConfig")

	WTweaks.Libs = {
		AceGUI = LibStub("AceGUI-3.0"),
		AceDB = LibStub("AceDB-3.0"),
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
	WTweaks:InitModules()
end

function WTweaks:InitModules()	
	for _, mod in pairs(WTweaksModules) do
		mod:OnModuleRegistered(WTweaks)
	end
end

function WTweaks:OpenEditMode()
	EditModeManagerFrame:Show()
end

function WTweaks:OpenConfig(input)
	InterfaceOptionsFrame_OpenToCategory(AddonName)
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
	-- frame:SetSize(select(1, unpack(WTweaks.DB.profile.Frames[frameName].Size)))
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

function WTweaks:NoOp() end