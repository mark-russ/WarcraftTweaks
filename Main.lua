local AddonName, Vars = ...
local WTweaks = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0")
local DBName = "WarcraftTweaks"

function WTweaks:NoOp() end

function WTweaks:GetConfig()
	return {
		type = "group",
	  	args = {
	   		general = {
				type = "group",
				inline = true,
				name = "General",
				args = {
		  			ShowXPBar = {
						name = "Show XP bar",
						desc = "This also affects the reputation bar.",
						type = "select",
						values = {
							hidden = "Always Hidden",
							smart = "Hide when max level",
							shown = "Always Shown"
						},
						set = WTweaks.Events.SetConfig,
						get = WTweaks.Events.GetConfig
		  			},
		  			ShowMicroBar = {
						name = "Show micro bar",
						desc = "If unchecked, the micro bar will be hidden.",
						type = "toggle",
						set = WTweaks.Events.SetConfig,
						get = WTweaks.Events.GetConfig
		  			},
					ShowRestedXP = {
						name = "Show resting indicator",
						desc = "If unchecked, the resting indicator will be hidden.",
						type = "toggle",
						set = WTweaks.Events.SetConfig,
						get = WTweaks.Events.GetConfig
					},
					ShowErrorText = {
						name = "Show red error text",
						desc = "If unchecked, the red error text will be hidden.",
						type = "toggle",
						set = WTweaks.Events.SetConfig,
						get = WTweaks.Events.GetConfig
					}
				},
			}
	  	}
	} 
end

function WTweaks:OnEnable()
	WTweaks:Main()
end

function WTweaks:InitConfig()
	WTweaks.NativeEvents = {
		PLAYER_LEVEL_UP = WTweaks.OnPlayerLevelUp
	}

	WTweaks.Events = {
		SetConfig = function(info, value)
			WTweaks.DB.profile[info[#info]] = value
			WTweaks:Main()
		end,
		GetConfig = function(info)
			return WTweaks.DB.profile[info[#info]]
		end
	}

	WTweaks.Config = {
		profile = {
			ShowXPBar = "smart",
			ShowMicroBar = false,
			ShowRestedXP = false,
			ShowErrorText = false
		}
	}
		
	WTweaks.DB = WTweaks.Libs.AceDB:New(DBName, WTweaks.Config)
	WTweaks.Libs.AceConfig:RegisterOptionsTable(AddonName, WTweaks:GetConfig())
	WTweaks.Frames.Config = WTweaks.Libs.AceCfgDialog:AddToBlizOptions(AddonName, AddonName, nil, "general")
end

function WTweaks:OnInitialize()
	WTweaks:RegisterChatCommand("edit",  "OpenEditMode")
	WTweaks:RegisterChatCommand("tweaks", "OpenConfig")
	
	WTweaks.Libs = {
		AceDB = LibStub("AceDB-3.0"),
		AceConfig = LibStub("AceConfig-3.0"),
		AceCfgDialog = LibStub("AceConfigDialog-3.0")
	}

	WTweaks.BlizzFuncs = {}
	WTweaks.Frames = {
		Main = CreateFrame("FRAME", AddonName)
	}
	WTweaks.Player = {
		Level = UnitLevel("player"),
		MaxLevel = GetMaxLevelForPlayerExpansion(),
		IsMaxLevel = function()
			return WTweaks.Player.Level == WTweaks.Player.MaxLevel 
		end
	}

	WTweaks:InitConfig()

	for eventName in pairs(WTweaks.NativeEvents) do
		WTweaks.Frames.Main:RegisterEvent(eventName);
	end
	
	WTweaks.Frames.Main:SetScript("OnEvent", function(frame, event, ...)
		WTweaks.NativeEvents[event](...)
	end)
end

function WTweaks:Main()
	WTweaks:UpdateMicroBarState()
	WTweaks:UpdateXPBarState()
	WTweaks:UpdateErrorTextState()

	if not self.DB.profile.ShowRestedXP then
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:Hide()
		WTweaks:RemoveFunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop, "Show")
	else
		WTweaks:RestoreFunc(PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop, "Show")

		if IsResting() then
			PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:Show()
		end
	end
end

function WTweaks.OnPlayerLevelUp(level)
	WTweaks.Player.Level = level
	WTweaks:UpdateXPBarState()
end

function WTweaks:UpdateXPBarState()
	if self.DB.profile.ShowXPBar == "shown" then
		StatusTrackingBarManager:Show()
	elseif self.DB.profile.ShowXPBar == "smart" then
		if WTweaks.Player.IsMaxLevel() then
			StatusTrackingBarManager:Hide()
		else
			StatusTrackingBarManager:Show()
		end
	elseif self.DB.profile.ShowXPBar == "hidden" then	
		StatusTrackingBarManager:Hide()
	else
		error("Unexpected XP bar setting: " .. tostring(self.DB.profile.ShowXPBar))
	end
end

function WTweaks:UpdateMicroBarState()
	local isHidden = not self.DB.profile.ShowMicroBar

	if isHidden then
		MicroButtonAndBagsBar:Hide()

		WTweaks:AnchorToBottomRight(ContainerFrameCombinedBags) 
		WTweaks:RemoveFunc(ContainerFrameCombinedBags, "SetPoint")

		WTweaks:AnchorToBottomRight(ContainerFrame1) 
		WTweaks:RemoveFunc(ContainerFrame1, "SetPoint")
		
		-- Reposition the Queue indicator button.
		QueueStatusButton:SetParent(UIParent)
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
	else
		MicroButtonAndBagsBar:Show()
		
		WTweaks:RestoreFunc(ContainerFrameCombinedBags, "SetPoint")
		WTweaks:RestoreFunc(ContainerFrame1, "SetPoint")
		
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetParent(MicroButtonAndBagsBar)
		QueueStatusButton:SetPoint("BOTTOMLEFT", MicroButtonAndBagsBar, "BOTTOMLEFT", -45, 0)
	end
end

function WTweaks:UpdateErrorTextState()
	if self.DB.profile.ShowErrorText then
		UIErrorsFrame:Show()
	else
		UIErrorsFrame:Hide()
	end
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

function WTweaks:AnchorToBottomRight(frame)
	frame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
end

function WTweaks:OpenEditMode()
	EditModeManagerFrame:Show()
end

function WTweaks:OpenConfig(input)
	InterfaceOptionsFrame_OpenToCategory(AddonName)
end
