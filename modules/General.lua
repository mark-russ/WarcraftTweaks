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

function Module:OnProfileChanged()
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

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:Init()
	Module:UpdateMicroBarState()
	Module:UpdateBagBarState()
	Module:UpdateXPBarState()
	Module:UpdateErrorTextState()
	Module:UpdateRestedXPIndicatorState()
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
		QueueStatusButton:SetParent(UIParent)
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
	else
		MicroMenuContainer:Show()
		QueueStatusButton:SetParent(MicroMenuContainer)
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetPoint("BOTTOMLEFT", MicroMenuContainer, "BOTTOMLEFT", -45, 0)
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
	BagsBar:SetScript("OnEnter", function()
		UIFrameFadeIn(BagsBar, BAG_BAR_FADE_SPEED, BagsBar:GetAlpha(), 1.0)
	end)
	
	BagsBar:SetScript("OnLeave", function()
		UIFrameFadeOut(BagsBar, BAG_BAR_FADE_SPEED, BagsBar:GetAlpha(), 0.0)
	end)

	for i=1, select("#", BagsBar:GetChildren()) do
		local ChildFrame = select(i, BagsBar:GetChildren())
		
		ChildFrame:SetScript("OnEnter", function()
			UIFrameFadeIn(BagsBar, BAG_BAR_FADE_SPEED, BagsBar:GetAlpha(), 1.0)
		end)
		
		ChildFrame:SetScript("OnLeave", function()
			UIFrameFadeOut(BagsBar, BAG_BAR_FADE_SPEED, BagsBar:GetAlpha(), 0.0)
		end)
	end
	
	wasBagsBarHoverHooked = true
end
