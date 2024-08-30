local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("General")
local FadeSpeed = 0.1

-- Can be found through GetGameMessageInfo.
local BlacklistedMessageTypes = {
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

function Module:OnModuleRegistered() 
	WTweaks:AddOptionPage(AddonName, "General")

	Module:UpdateUnitFrameState();
	Module:UpdateMicroBarState();
	Module:UpdateErrorTextState();
	Module:UpdateRestedXPIndicatorState();
	Module:UpdateBagBarState();
	Module:UpdateConfirmationsState();

	for _, enum in pairs(Enum.TooltipDataType) do
		TooltipDataProcessor.AddTooltipPostCall(enum, function(self, thing)
			if IsShiftKeyDown() then
				if enum == Enum.TooltipDataType.Unit then
					local unitID = tonumber(string.match(thing.guid, "Creature%-.-%-.-%-.-%-.-%-(.-)%-"));

					if (unitID) then
						self:AddLine("ID: " .. unitID, 0, 1, 0);
					end
				elseif thing.id then
					self:AddLine("ID: " .. thing.id, 0, 1, 0);
				end
			end
		end)
	end
end

function Module:UpdateUnitFrameState()
	if Module.Settings.General.PlayerUnitFrameVisibility == "hidden" then
		PlayerFrame:Hide();
	elseif Module.Settings.General.PlayerUnitFrameVisibility == "always" then
		PlayerFrame:Show();
	else
		PlayerFrame:Show();
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetPropagateMouseMotion(true);
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar:SetPropagateMouseMotion(true);
		PlayerFrame:SetAlpha(0);
		WTweaks:HookFader(PlayerFrame, PlayerFrame, FadeSpeed, function()
			return Module.Settings.General.PlayerUnitFrameVisibility == "auto";
		end);
	end
	
	if Module.Settings.General.TargetUnitFrameVisibility == "hidden" then
		TargetFrame:EnableMouse(false);
		TargetFrame:SetAlpha(0);
	elseif Module.Settings.General.TargetUnitFrameVisibility == "always" then
		TargetFrame:EnableMouse(true);
		TargetFrame:SetAlpha(1);
	else
		TargetFrame.TargetFrameContent.TargetFrameContentMain.HealthBarsContainer.HealthBar:SetPropagateMouseMotion(true);
		TargetFrame.TargetFrameContent.TargetFrameContentMain.ManaBar:SetPropagateMouseMotion(true);
		TargetFrame:SetAlpha(0);
		WTweaks:HookFader(TargetFrame, TargetFrame, FadeSpeed, function()
			return Module.Settings.General.TargetUnitFrameVisibility == "auto";
		end);
	end
end

function Module:UpdateMicroBarState()
	if not Module.Settings.General.ShowMicroBar then
		MicroMenuContainer:Hide()
	else
		MicroMenuContainer:Show()
	end
end

function Module:UpdateErrorTextState()
	-- Backup original function.
	if not Module.Settings.General.ShowErrorText and not Module.BlizzardShouldDisplayMessageTypeFunc then
		Module.BlizzardShouldDisplayMessageTypeFunc = UIErrorsFrame.ShouldDisplayMessageType

		UIErrorsFrame.ShouldDisplayMessageType = function(self, messageType, message)
			if BlacklistedMessageTypes[messageType] then
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
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
            .PlayerRestLoop:SetAlpha(0)
    else
        PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual
            .PlayerRestLoop:SetAlpha(1)
    end
end

function Module:UpdateBagBarState()
	if Module.Settings.General.BagBarVisibility == "hidden" then
		BagsBar:Hide()
	elseif Module.Settings.General.BagBarVisibility == "always" then
		BagsBar:Show()
	else
		BagsBar:Show()
		BagsBar:SetAlpha(0);
		Module:HookBagBarFader()
	end
end

function Module:UpdateConfirmationsState()
	--StaticPopupDialogs["DELETE_AZERITE_SCRAPPABLE_ITEM"] = StaticPopupDialogs["DELETE_ITEM"];
	if Module.Settings.General.UseSimpleConfirmations == true then
		-- Save backups.
		if Module.OriginalDeleteItemConfirmation == nil then
			Module.OriginalDeleteItemConfirmation = StaticPopupDialogs["DELETE_GOOD_ITEM"];
			Module.OriginalDeleteQuestItemConfirmation = StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"];
		end

		StaticPopupDialogs["DELETE_GOOD_ITEM"] = StaticPopupDialogs["DELETE_ITEM"];
		StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"] = StaticPopupDialogs["DELETE_QUEST_ITEM"];
	else
		StaticPopupDialogs["DELETE_GOOD_ITEM"] = Module.OriginalDeleteItemConfirmation;
		StaticPopupDialogs["DELETE_GOOD_QUEST_ITEM"] = Module.OriginalDeleteQuestItemConfirmation;
	end
end

function Module:HookBagBarFader()
	for _, bagChild in pairs({ BagsBar:GetChildren() }) do
		bagChild:SetPropagateMouseMotion(true);
	end
	
	BagsBar:SetAlpha(0.0);
	WTweaks:HookFader(BagsBar, BagsBar, FadeSpeed, function()
		return Module.Settings.General.BagBarVisibility == "auto";
	end);
end

function Module:GetConfig()
    return {
        General = {
            type = "group",
            name = "General",
            order = 1,
            inline = true,
            args = {
                ShowMicroBar = {
                    name = "Show micro bar",
                    desc = "If unchecked, the micro bar will be hidden.",
                    type = "toggle",
                    default = true,
                    order = 2,
                    width = 1.5,
					set = Module.UpdateMicroBarState
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
                    default = "always",
					set = Module.UpdateBagBarState
                },
                PlayerUnitFrameVisibility = {
                    name = "Player unit frame visibility",
                    desc = "If auto, it will appear if mouse is over the area.",
                    type = "select",
                    values = {
                        hidden = "Always Hidden",
                        auto = "Auto",
                        always = "Always Shown"
                    },
                    default = "always",
					set = Module.UpdateUnitFrameState
                },
                TargetUnitFrameVisibility = {
                    name = "Target unit frame visibility",
                    desc = "If auto, it will appear if mouse is over the area.",
                    type = "select",
                    values = {
                        hidden = "Always Hidden",
                        auto = "Auto",
                        always = "Always Shown"
                    },
                    default = "always",
					set = Module.UpdateUnitFrameState
                },
                ShowRestedXP = {
                    name = "Show resting indicator",
                    desc = "If unchecked, the resting indicator will be hidden.",
                    type = "toggle",
                    default = true,
                    order = 3,
                    width = 1.5,
					set = Module.UpdateRestedXPIndicatorState
                },
                ShowErrorText = {
                    name = "Show all error text",
                    desc = "If unchecked, red error text will be limited to less spammy stuff.",
                    type = "toggle",
                    default = true,
                    order = 4,
                    width = 1.5,
					set = Module.UpdateErrorTextState
                },
				UseSimpleConfirmations = {
					name = "Use simple confirmations",
					desc = "If checked, deletion confirmations which require names to be entered will be simple yes/no questions instead.",
					type = "toggle",
					default = false,
					order = 5,
					width = 1.5,
					set = Module.UpdateConfirmationsState
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
