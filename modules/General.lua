local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("General")

local BAG_BAR_FADE_SPEED = 0.1
local wasBagsBarHoverHooked = false

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(AddonName, "General", nil)

	-- Can be found through GetGameMessageInfo.
	Module.BlacklistedMessageTypes = {
		-- Cooldowns
		[LE_GAME_ERR_SPELL_COOLDOWN] = true,
		[LE_GAME_ERR_ABILITY_COOLDOWN] = true,

		-- Target needs to be in front of you.
		[LE_GAME_ERR_SPELL_FAILED_S] = true,

		-- Out of range.
		[LE_GAME_ERR_OUT_OF_RANGE] = true,
		[LE_GAME_ERR_SPELL_OUT_OF_RANGE] = true,

		[LE_GAME_ERR_NO_ATTACK_TARGET] = true,
		[LE_GAME_ERR_GENERIC_NO_TARGET] = true,

		[LE_GAME_ERR_NOT_WHILE_MOVING] = true,
		[LE_GAME_ERR_BADATTACKFACING] = true,
		[LE_GAME_ERR_BADATTACKPOS] = true
	}
	
	Module:Init()
end

function Module:OnInitialize(main)
	main:RegisterChatCommand("tweaks", function()
		InterfaceOptionsFrame_OpenToCategory(AddonName)
	end)
	
	main:RegisterChatCommand("edit", function()
		EditModeManagerFrame:Show()
	end)
end

function Module:UpdateDeleteConfirmations()
	StaticPopupDialogs.DELETE_GOOD_ITEM = StaticPopupDialogs.DELETE_ITEM
	StaticPopupDialogs.DELETE_QUEST_ITEM = StaticPopupDialogs.DELETE_ITEM
	StaticPopupDialogs.DELETE_GOOD_QUEST_ITEM = StaticPopupDialogs.DELETE_ITEM
end

function Module:UpdateEncounterBar() 
    EncounterBar:SetScale(Module.Settings.General.EncounterBarScale)
	ExtraAbilityContainer:SetScale(Module.Settings.General.ExtraAbilityContainerScale)
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:Init()
	Module:UpdateMicroBarState()
	Module:UpdateBagBarState()
	Module:UpdateXPBarState()
	Module:UpdateErrorTextState()
	Module:UpdateRestedXPIndicatorState()
	Module:UpdateDeleteConfirmations()
	Module:UpdateEncounterBar()

	if AchievementFrame == nil then
		WTweaks:HookEvent("ADDON_LOADED", function(addonName)
			if addonName == "Blizzard_AchievementUI" then
				AchievementFrame:HookScript("OnShow", Module.UpdateEmoteState)
				AchievementFrame:HookScript("OnHide", Module.UpdateEmoteState)
			end
		end)
	else
		AchievementFrame:HookScript("OnShow", Module.UpdateEmoteState)
		AchievementFrame:HookScript("OnHide", Module.UpdateEmoteState)
	end
	
	PVEFrame:HookScript("OnShow", Module.UpdateEmoteState)
	PVEFrame:HookScript("OnHide", Module.UpdateEmoteState)
end

function Module:UpdateEmoteState()
	local shouldBeReading = PVEFrame:IsShown() or (AchievementFrame ~= nil and AchievementFrame:IsShown())
	local shouldNotBeReading = PVEFrame:IsShown() == false and (AchievementFrame == nil or AchievementFrame:IsShown() == false)
	
	if shouldBeReading then
		DoEmote("Read")
	elseif shouldNotBeReading then
		DoEmote(nil)
	end
end

function Module:GetConfig()
    return {
        General = {
            type = "group",
            name = "General",
            order = 1,
            inline = true,
            args = {
                ShowXPBar = {
                    name = "Show XP bar",
                    desc = "This also affects the reputation bar.",
                    type = "toggle",
                    default = true,
					order = 1,
					width = 1.5
                },
                ShowMicroBar = {
                    name = "Show micro bar",
                    desc = "If unchecked, the micro bar will be hidden.",
                    type = "toggle",
                    default = true,
					order = 2,
					width = 1.5
                },
                BagBarVisibility = {
                    name = "Bag bar visibility",
                    desc = "If auto, it will appear if mouse is over the area.",
                    type = "select",
                    values = {
                        hidden = "Always Hidden",
                        auto = "Auto",
                        always = "Always Shown"
                    },
                    default = "always"
                },
                ShowRestedXP = {
                    name = "Show resting indicator",
                    desc = "If unchecked, the resting indicator will be hidden.",
                    type = "toggle",
                    default = true,
					order = 3,
					width = 1.5
                },
                ShowErrorText = {
                    name = "Show all error text",
                    desc = "If unchecked, red error text will be limited to less spammy stuff.",
                    type = "toggle",
                    default = true,
					order = 4,
					width = 1.5
                },
				EncounterBarScale = {
					name = "Encounter Bar Scale",
					desc = "Sets the size of the encounter bar. This bar, for example, shows vigor when you're dragon riding.",
					type = "range",
					default = 1.0,
					step = 0.05,
					min = 0.1,
					max = 2.0
				},
				ExtraAbilityContainerScale = {
					name = "Extra Ability Container Scale",
					desc = "Sets the size of the extra ability container. This container, for example, shows the garrison button or encounter-specific abilities.",
					type = "range",
					default = 1.0,
					step = 0.05,
					min = 0.1,
					max = 2.0
				},
				Description = {
					name = "+ Version: " .. WTweaks.Version,
					type = "description",
					width = full,
					order = 999
				}
            }
        }
    }
end

function Module:UpdateXPBarState()
	WTweaks:LoadFrame(StatusTrackingBarManager)
	WTweaks:MakeFrameDraggable(StatusTrackingBarManager)

	if Module.Settings.General.ShowXPBar then
		StatusTrackingBarManager:Show()
	else
		StatusTrackingBarManager:Hide()
	end
end

function Module:UpdateMicroBarState()
	-- Repositions the bag frames to appear in the bottom-right corner.
	WTweaks:HookSecure("UpdateContainerFrameAnchors", function()
		if not Module.Settings.General.ShowMicroBar then
			local bagFrame = WTweaks:GetBagFrame()
			
			bagFrame:ClearAllPoints()
			bagFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
		end
	end)

	if not Module.Settings.General.ShowMicroBar then
		MicroMenuContainer:Hide()
		--QueueStatusButton:SetParent(UIParent)
		--QueueStatusButton:ClearAllPoints()
		--QueueStatusButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
	else
		MicroMenuContainer:Show()
		--QueueStatusButton:SetParent(MicroMenuContainer)
		--QueueStatusButton:ClearAllPoints()
		--QueueStatusButton:SetPoint("BOTTOMLEFT", MicroMenuContainer, "BOTTOMLEFT", -45, 0)
	end
end

function Module:UpdateBagBarState()
	if Module.Settings.General.BagBarVisibility == "hidden" then
		Module:UnhookBagBarFader()
		BagsBar:Hide()
	elseif Module.Settings.General.BagBarVisibility == "always" then
		Module:UnhookBagBarFader()
		BagsBar:Show()
	else
		UIFrameFadeOut(BagsBar, BAG_BAR_FADE_SPEED, BagsBar:GetAlpha(), 0.0)
		Module:HookBagBarFader()
	end
end

function Module:UpdateErrorTextState()
	-- Backup original function.
	if not Module.Settings.General.ShowErrorText and not Module.BlizzardShouldDisplayMessageTypeFunc then
		Module.BlizzardShouldDisplayMessageTypeFunc = UIErrorsFrame.ShouldDisplayMessageType

		UIErrorsFrame.ShouldDisplayMessageType = function(self, messageType, message)
			if Module.BlacklistedMessageTypes[messageType] then
				return false
			end

			---- If it's allowed through our implementation, forward to Blizzard's implementation.
			return Module.BlizzardShouldDisplayMessageTypeFunc(self, messageType, message)
		end
	-- Restore original function.
	elseif Module.Settings.General.ShowErrorText and Module.BlizzardShouldDisplayMessageTypeFunc then
		UIErrorsFrame.ShouldDisplayMessageType = Module.BlizzardShouldDisplayMessageTypeFunc
		Module.BlizzardShouldDisplayMessageTypeFunc = nil
	end
end

function Module:UpdateRestedXPIndicatorState()
	if not Module.Settings.General.ShowRestedXP then
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetAlpha(0)
	else
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetAlpha(1)
	end
end

function Module:UnhookBagBarFader()
	if not wasBagsBarHoverHooked then
		return
	end

	BagsBar:SetAlpha(1.0)
	BagsBar:SetScript("OnEnter", nil)
	BagsBar:SetScript("OnLeave", nil)

	for i=1, select("#", BagsBar:GetChildren()) do
		local ChildFrame = select(i, BagsBar:GetChildren())
		ChildFrame:SetScript("OnEnter", nil)
		ChildFrame:SetScript("OnLeave", nil)
	end
	
	wasBagsBarHoverHooked = false
end

function Module:HookBagBarFader()
	if wasBagsBarHoverHooked then
		return
	end

	BagsBar:SetAlpha(0.0)
	WTweaks:HookFader(BagsBar, { BagsBar, unpack({ BagsBar:GetChildren() }) }, BAG_BAR_FADE_SPEED)

	wasBagsBarHoverHooked = true
end