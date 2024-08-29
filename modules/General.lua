local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("General")
local BagBarFadeSpeed = 0.1
local WasBagsBarHoverHooked = false

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
		--DevTools_Dump(item);
		
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
		Module:UnhookFader(PlayerFrame, { PlayerFrame });
		PlayerFrame:Hide();
	elseif Module.Settings.General.PlayerUnitFrameVisibility == "always" then
		WTweaks:UnhookFader(PlayerFrame, { PlayerFrame });
		PlayerFrame:Show();
	else
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.HealthBarsContainer.HealthBar:SetPropagateMouseMotion(true);
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea:SetPropagateMouseMotion(true);
		PlayerFrame.PlayerFrameContent.PlayerFrameContentMain.ManaBarArea.ManaBar:SetPropagateMouseMotion(true);
		PlayerFrame:SetAlpha(0);
		WTweaks:HookFader(PlayerFrame, PlayerFrame, 0.1);
	end
	--
	--if Module.Settings.General.ShowTargetUnitFrame then
	--	TargetFrame:Show();
	--else
	--	TargetFrame.Show = function() end;
	--	TargetFrame:Hide();
	--end
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
		Module:UnhookBagBarFader()
		BagsBar:Hide()
	elseif Module.Settings.General.BagBarVisibility == "always" then
		Module:UnhookBagBarFader()
		BagsBar:Show()
	else
		UIFrameFadeOut(BagsBar, BagBarFadeSpeed, BagsBar:GetAlpha(), 0.0)
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

function Module:UnhookBagBarFader()
	if not WasBagsBarHoverHooked then
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
	
	WasBagsBarHoverHooked = false
end

function Module:HookBagBarFader()
	if WasBagsBarHoverHooked then
		return
	end

	for _, bagChild in pairs({ BagsBar:GetChildren() }) do
		bagChild:SetPropagateMouseMotion(true);
	end
	
	BagsBar:SetAlpha(0.0);
	WTweaks:HookFader(BagsBar, BagsBar, BagBarFadeSpeed);

	WasBagsBarHoverHooked = true
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
                ShowTargetUnitFrame = {
                    name = "Show target frame",
                    desc = "If unchecked, the target frame will be hidden.",
                    type = "toggle",
                    default = true,
                    order = 3,
                    width = 1.5,
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
