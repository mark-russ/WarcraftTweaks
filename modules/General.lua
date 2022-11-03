local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("General")

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "General", nil)
    Module:Init()
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:Init()
	Module:UpdateMicroBarState()
	Module:UpdateXPBarState()
	Module:UpdateErrorTextState()
	Module:UpdateRestedXPIndicatorState()
end

function Module:GetConfig()
    return {
        General = {
            type = "group",
            name = "General",
            order = 0,
            inline = true,
            args = {
                ShowXPBar = {
                    name = "Show XP bar",
                    desc = "This also affects the reputation bar.",
                    type = "toggle",
                    default = true
                },
                ShowMicroBar = {
                    name = "Show micro bar",
                    desc = "If unchecked, the micro bar will be hidden.",
                    type = "toggle",
                    default = true
                },
                ShowRestedXP = {
                    name = "Show resting indicator",
                    desc = "If unchecked, the resting indicator will be hidden.",
                    type = "toggle",
                    default = true
                },
                ShowErrorText = {
                    name = "Show red error text",
                    desc = "If unchecked, the red error text will be hidden.",
                    type = "toggle",
                    default = true
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
		MicroButtonAndBagsBar:Hide()
		QueueStatusButton:SetParent(UIParent)
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
	else
		MicroButtonAndBagsBar:Show()
		QueueStatusButton:SetParent(MicroButtonAndBagsBar)
		QueueStatusButton:ClearAllPoints()
		QueueStatusButton:SetPoint("BOTTOMLEFT", MicroButtonAndBagsBar, "BOTTOMLEFT", -45, 0)
	end
end

function Module:UpdateErrorTextState()
	if not Module.Settings.General.ShowErrorText then
		UIErrorsFrame:Hide()
	else
		UIErrorsFrame:Show()
	end
end

function Module:UpdateRestedXPIndicatorState()
	if not Module.Settings.General.ShowRestedXP then
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetAlpha(0)
	else
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetAlpha(1)
	end
end