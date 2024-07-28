local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("Typography")
Module.IsInitialized = false;
Module.IsTooltipOutdated = true;

function Module:OnModuleRegistered() 
	WTweaks:AddOptionPage(Module.Name, "Typography", AddonName)

	if (Module.Settings.Typography.IsEnabled ~= true) then
		return;
	end

    Module:UpdateChatTabs()
    Module:UpdateChatContents()
    Module:UpdateChatEditBox()
	Module:UpdateGuildChatText()
	Module:UpdatePrimaryUnitFrames()
	Module:UpdateSecondaryUnitFrames()
	Module:UpdateWindowTitlebars()
	Module:UpdateWindowText()
	Module:UpdateQuestFrame()
	Module:UpdateToolTip()

	EventRegistry:RegisterCallback("EditMode.Exit", Module.RepositionTargetFrame)
	WTweaks:HookEvent("PLAYER_ENTERING_WORLD", function() 
		
		hooksecurefunc(TargetFrame, "OnLoad", function()
			print("AAAAAAA");
		end)

	end)
	WTweaks:HookEvent("ADDON_LOADED", function(addonName) Module:OnAddonLoaded(addonName) end)

	Module.IsInitialized = true;
end

function Module:UpdateChatTabs()
    fontPath = WTweaks:GetFontFile(Module.Settings.Typography.Chat.Tabs.FontFile)
    
    for i = 1, NUM_CHAT_WINDOWS do
		local chatTab = _G["ChatFrame"..i.."Tab"];
		chatTab.Text:SetFont(fontPath, Module.Settings.Typography.Chat.Tabs.FontSize, Module.Settings.Typography.Chat.Tabs.FontOutline)
    end
end

function Module:UpdateChatContents()
	fontPath = WTweaks:GetFontFile(Module.Settings.Typography.Chat.Contents.FontFile)
	CHAT_FONT_HEIGHTS = { Module.Settings.Typography.Chat.Contents.FontSize }

	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame"..i];
		FCF_SetChatWindowFontSize(nil, chatFrame, Module.Settings.Typography.Chat.Contents.FontSize)
		_G["ChatFrame"..i]:SetFont(fontPath, Module.Settings.Typography.Chat.Contents.FontSize, Module.Settings.Typography.Chat.Contents.FontOutline)
	end
end

function Module:UpdateGuildChatText()
	fontPath = WTweaks:GetFontFile(Module.Settings.Typography.Chat.Contents.FontFile)
	CommunitiesFrame.Chat.MessageFrame:SetFont(fontPath, Module.Settings.Typography.Unit.Player.FontSize, Module.Settings.Typography.Unit.Player.FontOutline)
end

-- Blizzard target frame has messed up positioning. This fixes that.
function Module:RepositionTargetFrame()
	local point, relativeTo, relativePoint, xOfs, yOfs = TargetFrame:GetPoint(1);
	TargetFrame:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - 3);
end

function Module:SetTitleStyle(frame)
	local titleFontPath = WTweaks:GetFontFile(Module.Settings.Typography.General.Title.FontFile);
	frame:SetFont(titleFontPath, Module.Settings.Typography.General.Title.FontSize, Module.Settings.Typography.General.Title.FontOutline);
	frame:SetVertexColor(1, 1, 1, 0.9);
end

function Module:UpdateToolTip()
	local headerFontPath = WTweaks:GetFontFile(Module.Settings.Typography.Tooltip.Header.FontFile);
	GameTooltipHeaderText:SetFont(headerFontPath, Module.Settings.Typography.Tooltip.Header.FontSize, Module.Settings.Typography.Tooltip.Header.FontOutline );
	
	local normalFontPath = WTweaks:GetFontFile(Module.Settings.Typography.Tooltip.Normal.FontFile);
	GameTooltipText:SetFont(normalFontPath, Module.Settings.Typography.Tooltip.Normal.FontSize, Module.Settings.Typography.Tooltip.Normal.FontOutline);

	if (Module.IsInitialized) then
		Module.IsTooltipOutdated = true;
	else
		hooksecurefunc("MoneyFrame_SetType", function(moneyFrame, moneyType)
			if (moneyFrame.PrefixText and (moneyFrame.IsStyled ~= true or Module.IsTooltipOutdated == true)) then
				local smallFontPath = WTweaks:GetFontFile(Module.Settings.Typography.Tooltip.Small.FontFile);	
				moneyFrame.PrefixText:SetFont(smallFontPath, Module.Settings.Typography.Tooltip.Small.FontSize, Module.Settings.Typography.Tooltip.Small.FontOutline);
				moneyFrame.SuffixText:SetFont(smallFontPath, Module.Settings.Typography.Tooltip.Small.FontSize, Module.Settings.Typography.Tooltip.Small.FontOutline);
				moneyFrame.GoldButton.Text:SetFont(smallFontPath, Module.Settings.Typography.Tooltip.Small.FontSize, Module.Settings.Typography.Tooltip.Small.FontOutline)
				moneyFrame.SilverButton.Text:SetFont(smallFontPath, Module.Settings.Typography.Tooltip.Small.FontSize, Module.Settings.Typography.Tooltip.Small.FontOutline)
				moneyFrame.CopperButton.Text:SetFont(smallFontPath, Module.Settings.Typography.Tooltip.Small.FontSize, Module.Settings.Typography.Tooltip.Small.FontOutline)
				moneyFrame.IsStyled = true;
				Module.IsTooltipOutdated = false;
			end
		end)
	end
end

function Module:UpdatePrimaryUnitFrames()
	local xMargin = 3;
	local yOffset = -29;
	
	local pendingFrames = {
		PlayerFrame,
		TargetFrame,
		FocusFrame
	}

	PlayerFrame_UpdatePlayerNameTextAnchor = WTweaks.NoOp;

	local fontPath = WTweaks:GetFontFile(Module.Settings.Typography.Unit.Player.FontFile)
	for _, pendingFrame in pairs(pendingFrames) do
		local frame = WTweaks:GetNormalizedUnitFrame(pendingFrame)
		
		frame.Text.Name:SetFont(fontPath, Module.Settings.Typography.Unit.Player.FontSize, Module.Settings.Typography.Unit.Player.FontOutline)
		frame.Text.Name:ClearAllPoints()
		frame.Text.Name:SetWidth(105-(xMargin*2));
		frame.Text.Name:SetHeight(10);
		frame.Text.Name:SetJustifyV("BOTTOM")

		frame.Text.Level:SetFont(fontPath, Module.Settings.Typography.Unit.Player.FontSize, Module.Settings.Typography.Unit.Player.FontOutline)
		frame.Text.Level:ClearAllPoints()
		frame.Text.Level:SetWidth(0);
		frame.Text.Level:SetHeight(10);
		frame.Text.Level:SetJustifyV("BOTTOM")

		frame.Text.Health:SetFont(fontPath, Module.Settings.Typography.Unit.Player.FontSize, Module.Settings.Typography.Unit.Player.FontOutline)
		frame.Text.Mana:SetFont(fontPath, Module.Settings.Typography.Unit.Player.FontSize, Module.Settings.Typography.Unit.Player.FontOutline)

		if frame.BFrame == PlayerFrame then
			frame.Text.Name:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 85 + xMargin, yOffset);
			frame.Text.Level:SetPoint("TOPRIGHT", frame.Content, "TOPRIGHT", -20 - xMargin, yOffset);
		else
			frame.Text.Name:SetPoint("TOPLEFT", frame.Content, "TOPLEFT", 23 + xMargin, yOffset+1);
			frame.Text.Level:SetPoint("TOPRIGHT", frame.Content, "TOPRIGHT", -79 - xMargin, yOffset+1);
		end
	end
end

function Module:UpdateSecondaryUnitFrames()
	local fontPath = WTweaks:GetFontFile(Module.Settings.Typography.Unit.Secondary.FontFile);

	local pendingFrames = {
		TargetFrameToT,
		FocusFrameToT,
		PetFrame
	}
	
	for _, pendingFrame in pairs(pendingFrames) do
		local frame = WTweaks:GetNormalizedUnitFrame(pendingFrame)
		frame.Text.Name:SetFont(fontPath, Module.Settings.Typography.Unit.Secondary.FontSize, Module.Settings.Typography.Unit.Secondary.FontOutline)
	end
end

function Module:UpdateChatEditBox()
	fontPath = WTweaks:GetFontFile(Module.Settings.Typography.Chat.EditBox.FontFile)

	for i = 1, NUM_CHAT_WINDOWS do
	    _G["ChatFrame"..i.."EditBox"].header:SetFont(fontPath, Module.Settings.Typography.Chat.EditBox.FontSize, Module.Settings.Typography.Chat.EditBox.FontOutline)
	    _G["ChatFrame"..i.."EditBox"]:SetFont(fontPath, Module.Settings.Typography.Chat.EditBox.FontSize, Module.Settings.Typography.Chat.EditBox.FontOutline)
	end
end

function Module:UpdateWindowTitlebars()
	local titles = {
		PingSystemTutorialTitleText,
		StableFrameTitleText,
		SpellBookFrameTitleText,
		PetitionFrameTitleText,
		HelpFrameTitleText,
		RaidParentFrameTitleText,
		GossipFrameTitleText,
		TabardFrameTitleText,
		TimeManagerFrameTitleText,
		PVEFrameTitleText,
		TicketStatusTitleText,
		AddonListTitleText,
		ItemTextFrameTitleText,
		QuestProgressTitleText,
		DressUpFrameTitleText,
		MailFrameTitleText,
		WorldMapFrameTitleText,
		ChannelFrameTitleText,
		FriendsFrameTitleText,
		QuestLogPopupDetailFrameTitleText,
		QuestFrameTitleText,
		OpenMailFrameTitleText,
		BankFrameTitleText,
		LootFrameTitleText,
		ContainerFrameCombinedBagsTitleText,
		TradeFrameTitleText,
		MerchantFrameTitleText,
		GroupLootHistoryFrameTitleText,
		CharacterFrameTitleText,
		ModelPreviewFrameTitleText,
		ContainerFrame1TitleText,
		ContainerFrame2TitleText,
		ContainerFrame3TitleText,
		ContainerFrame4TitleText,
		ContainerFrame5TitleText,
		ContainerFrame6TitleText,
		ContainerFrame7TitleText,
		ContainerFrame8TitleText,
		ContainerFrame9TitleText,
		ContainerFrame10TitleText,
		ContainerFrame11TitleText,
		ContainerFrame12TitleText,
		ContainerFrame13TitleText,
		GameMenuFrame.Header.Text,
		-- These below may not be loaded.
		CommunitiesFrameTitleText,
		ClassTalentFrameTitleText,
		CollectionsJournalTitleText,
		EncounterJournalTitleText
	}
	
	for _, titleText in pairs(titles) do
		Module:SetTitleStyle(titleText);
	end

	if AchievementFrame then
		Module:SetTitleStyle(AchievementFrame.Header.Title);
	end

	if SettingsPanel then
		Module:SetTitleStyle(SettingsPanel.NineSlice.Text);
	end
end

function Module:UpdateWindowText()
	local primaryFontPath = WTweaks:GetFontFile(Module.Settings.Typography.General.Primary.FontFile);
	GameFontNormal:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
	
	local secondaryFontPath = WTweaks:GetFontFile(Module.Settings.Typography.General.Secondary.FontFile);
	GameFontNormalSmall:SetFont(secondaryFontPath, Module.Settings.Typography.General.Secondary.FontSize, Module.Settings.Typography.General.Secondary.FontOutline);
	
	CharacterLevelText:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
	CharacterStatsPane.ItemLevelFrame.Value:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize + 3, Module.Settings.Typography.General.Primary.FontOutline);

	GameFont_Gigantic:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
	GameFontNormalHuge4:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
	GameFontBlack:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
	GameFontHighlightLarge:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
	GameFontNormalSmall2:SetFont(primaryFontPath, Module.Settings.Typography.General.Primary.FontSize, Module.Settings.Typography.General.Primary.FontOutline);
end

function Module:UpdateQuestFrame()
	local titleFontPath = WTweaks:GetFontFile(Module.Settings.Typography.Dialogue.Title.FontFile);
	QuestTitleFont:SetFont(titleFontPath, Module.Settings.Typography.Dialogue.Title.FontSize, Module.Settings.Typography.Dialogue.Title.FontOutline)
	QuestTitleFontBlackShadow:SetFont(titleFontPath, Module.Settings.Typography.Dialogue.Title.FontSize, Module.Settings.Typography.Dialogue.Title.FontOutline)

	local contentFontPath = WTweaks:GetFontFile(Module.Settings.Typography.Dialogue.Regular.FontFile);
	QuestFont:SetFont(contentFontPath, Module.Settings.Typography.Dialogue.Regular.FontSize, Module.Settings.Typography.Dialogue.Regular.FontOutline)
end

function Module:OnAddonLoaded(addonName)
	if addonName == "Blizzard_Communities" then
		Module:SetTitleStyle(CommunitiesFrameTitleText);
	elseif addonName == "Blizzard_ClassTalentUI" then
		Module:SetTitleStyle(ClassTalentFrameTitleText);
	elseif addonName == "Blizzard_Collections" then
		Module:SetTitleStyle(CollectionsJournalTitleText);
	elseif addonName == "Blizzard_EncounterJournal" then
		Module:SetTitleStyle(EncounterJournalTitleText);
	elseif addonName == "Blizzard_AchievementUI" then
		Module:SetTitleStyle(AchievementFrame.Header.Title);
	elseif addonName == "Blizzard_Settings" then
		Module:SetTitleStyle(SettingsPanel.NineSlice.Text);
	end
end

function Module:GetConfig()
    return {
		Typography = {
			name = "Typography",
			type = "group",
			order = 0,
			inline = true,
			args = {
                IsEnabled = {
                    name = "Enable Module",
                    desc = "If checked, various fonts will become adjustable.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full",
					set = ReloadUI
                },
				General = {
					name = "General",
					desc = "These settings apply to general graphical components.",
					type = "group",
					order = 1,
					args = {
						Title = {
							name = "Window Titlebar",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateWindowTitlebars)
						},
						Primary = {
							name = "Primary",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateWindowText)
						},
						Secondary = {
							name = "Secondary",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateWindowText)
						}
					}
				},
				Tooltip = {
					name = "Tooltips",
					type = "group",
					order = 2,
					args = {
						Header = {
							name = "Header",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(14, 8, 20, false, Module.UpdateToolTip)
						},
						Normal = {
							name = "Normal",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateToolTip)
						},
						Small = {
							name = "Small",
							type = "group",
							order = 2,
							inline = true,
							args = WTweaks:CreateFontOptions(11, 8, 20, false, Module.UpdateToolTip)
						}
					}
				},
				Chat = {
					name = "Chat",
					type = "group",
					order = 3,
					args = {
						Tabs = {
							name = "Tabs",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(11, 8, 20, false, Module.UpdateChatTabs),
						},
						Contents = {
							name = "Contents",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(11, 8, 20, false, Module.UpdateChatContents)
						},
						EditBox = {
							name = "Edit Box",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(11, 8, 20, false, Module.UpdateChatEditBox)
						}
					}
				},
				Unit = {
					name = "Unit Frames",
					type = "group",
					order = 4,
					args = {
						Player = {
							name = "Player | Target",
							type = "group",
							order = 1,
							inline = false,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdatePrimaryUnitFrames),
						},
						Secondary = {
							name = "Secondary",
							type = "group",
							order = 2,
							inline = false,
							desc = "This includes Target of Target frames.",
							args = WTweaks:CreateFontOptions(8, 6, 14, false, Module.UpdateSecondaryUnitFrames),
						},
						Party = {
							name = "Party",
							type = "group",
							order = 3,
							inline = false,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateChatTabs),
						},
						Raid = {
							name = "Raid",
							type = "group",
							order = 4,
							inline = false,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateChatTabs),
						},
					}
				},
				Minimap = {
					name = "Minimap",
					type = "group",
					order = 5,
					args = {
						Name = {
							name = "Zone Name",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						},
						Time = {
							name = "Time",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						}
					}
				},
				Dialogue = {
					name = "Dialogue",
					desc = "This changes the text in the conversation window with NPCs.",
					type = "group",
					order = 6,
					args = {
						Title = {
							name = "Title",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateQuestFrame)
						},
						Regular = {
							name = "Regular",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20, false, Module.UpdateQuestFrame)
						}
					}
				},
				Zone = {
					name = "Zone",
					type = "group",
					order = 7,
					args = {
						Main = {
							name = "Main name",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(32, 10, 60, true)
						},
						Subzone = {
							name = "Subzone name",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(24, 10, 60, true)
						}
					}
				}
			}
		}
    }
end