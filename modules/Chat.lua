local WTweaks

local Module = {
    Name = "Chat"
}

table.insert(WTweaksModules, Module)

function Module:OnSettingsChanged(settings, groupName)
    Module.Settings = settings
    Module:Refresh()
end

function Module:OnSettingsLoaded(settings, groupName)
    Module.Settings = settings
end

function Module:OnModuleRegistered(main)
    WTweaks = main
    Module:Refresh()
end

function Module:Refresh()
	Module:UpdateChatHistory()
	Module:UpdateChatSettings()
end

function Module:GetConfig()
    return {
		chat = {
			type = "group",
			name = "Chat",
			order = 2,
			inline = true,
			args = {
				ChatFont = {
					name = "Font",
					desc = "Changes the font of all chat frames.",
					order = 0,
					type = "select",
					values = function()
						return WTweaks.Options.Fonts
					end
				},
				ShowChatOutline = {
					name = "Font Outline",
					desc = "If checked, adds an outline to the chat window text.",
					order = 1,
					type = "toggle",
					default = false
				},
				UseChatShortChannels = {
					name = "Shorten channel names",
					desc = "Uses only the channel number instead of the whole channel name",
					order = 2,
					type = "toggle",
					default = false
				}
			}
		}
    }
end

function Module:UpdateChatHistory()
	
end

function Module:UpdateChatSettings()
	local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.ChatFont)

	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame"..i]
		local fontHeight = select(2, chatFrame:GetFont());
		chatFrame:SetFont(fontFile, fontHeight, Module.Settings.ShowChatOutline and "OUTLINE" or "")
	end
end

-- Function copied from Blizzard's ChatFrame.lua
local function GetPFlag(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17)
	-- Renaming for clarity:
	local specialFlag = arg6;
	local zoneChannelID = arg7;
	local localChannelID = arg8;

	if specialFlag ~= "" then
		if specialFlag == "GM" or specialFlag == "DEV" then
			-- Add Blizzard Icon if  this was sent by a GM/DEV
			return "|TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t ";
		elseif specialFlag == "GUIDE" then
			if ChatFrame_GetMentorChannelStatus(Enum.PlayerMentorshipStatus.Mentor, C_ChatInfo.GetChannelRulesetForChannelID(zoneChannelID)) == Enum.PlayerMentorshipStatus.Mentor then
				return NPEV2_CHAT_USER_TAG_GUIDE .. " "; -- possibly unable to save global string with trailing whitespace...
			end
		elseif specialFlag == "NEWCOMER" then
			if ChatFrame_GetMentorChannelStatus(Enum.PlayerMentorshipStatus.Newcomer, C_ChatInfo.GetChannelRulesetForChannelID(zoneChannelID)) == Enum.PlayerMentorshipStatus.Newcomer then
				return NPEV2_CHAT_USER_TAG_NEWCOMER;
			end
		else
			return _G["CHAT_FLAG_"..specialFlag];
		end
	end

	return "";
end

-- Function copied from Blizzard's ChatFrame.lua
local function ChatFrame_CheckAddChannel(chatFrame, eventType, channelID)
	-- This is called in the event that a user receives chat events for a channel that isn't enabled for any chat frames.
	-- Minor hack, because chat channel filtering is backed by the client, but driven entirely from Lua.
	-- This solves the issue of Guides abdicating their status, and then re-applying in the same game session, unless ChatFrame_AddChannel
	-- is called, the channel filter will be off even though it's still enabled in the client, since abdication removes the chat channel and its config.

	-- Only add to default (since multiple chat frames receive the event and we don't want to add to others)
	if chatFrame ~= DEFAULT_CHAT_FRAME then
		return false;
	end

	-- Only add if the user is joining a channel
	if eventType ~= "YOU_CHANGED" then
		return false;
	end

	-- Only add regional channels
	 if not C_ChatInfo.IsChannelRegionalForChannelID(channelID) then
	 	return false;
	 end

	return ChatFrame_AddChannel(chatFrame, C_ChatInfo.GetChannelShortcutForChannelID(channelID)) ~= nil;
end

-- Function copied from Blizzard's ChatFrame.lua
function ChatFrame_MessageEventHandler(self, event, ...)
	if ( TextToSpeechFrame_MessageEventHandler ~= nil ) then
		TextToSpeechFrame_MessageEventHandler(self, event, ...)
	end

	if ( strsub(event, 1, 8) == "CHAT_MSG" ) then
		local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17 = ...;
		if (arg16) then
			-- hiding sender in letterbox: do NOT even show in chat window (only shows in cinematic frame)
			return true;
		end

		local type = strsub(event, 10);
		local info = ChatTypeInfo[type];

		--If it was a GM whisper, dispatch it to the GMChat addon.
		if arg6 == "GM" and type == "WHISPER" then
			return;
		end

		local filter = false;
		local chatFilters = ChatFrame_GetMessageEventFilters(event)
		
		if ( chatFilters and chatFilters[event] ) then
			local newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14;
			for _, filterFunc in next, chatFilters[event] do
				filter, newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14 = filterFunc(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);
				if ( filter ) then
					return true;
				elseif ( newarg1 ) then
					arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14 = newarg1, newarg2, newarg3, newarg4, newarg5, newarg6, newarg7, newarg8, newarg9, newarg10, newarg11, newarg12, newarg13, newarg14;
				end
			end
		end

		local coloredName = GetColoredName(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14);

		local channelLength = strlen(arg4);
		local infoType = type;

		if type == "VOICE_TEXT" and not GetCVarBool("speechToText") then
			return;

		elseif ( (type == "COMMUNITIES_CHANNEL") or ((strsub(type, 1, 7) == "CHANNEL") and (type ~= "CHANNEL_LIST") and ((arg1 ~= "INVITE") or (type ~= "CHANNEL_NOTICE_USER"))) ) then
			if ( arg1 == "WRONG_PASSWORD" ) then
				local staticPopup = _G[StaticPopup_Visible("CHAT_CHANNEL_PASSWORD") or ""];
				if ( staticPopup and strupper(staticPopup.data) == strupper(arg9) ) then
					-- Don't display invalid password messages if we're going to prompt for a password (bug 102312)
					return;
				end
			end

			local found = false;
			for index, value in pairs(self.channelList) do
				if ( channelLength > strlen(value) ) then
					-- arg9 is the channel name without the number in front...
					if ( ((arg7 > 0) and (self.zoneChannelList[index] == arg7)) or (strupper(value) == strupper(arg9)) ) then
						found = true;
						infoType = "CHANNEL"..arg8;
						info = ChatTypeInfo[infoType];
						if ( (type == "CHANNEL_NOTICE") and (arg1 == "YOU_LEFT") ) then
							self.channelList[index] = nil;
							self.zoneChannelList[index] = nil;
						end
						break;
					end
				end
			end
			if not found or not info then
				local eventType, channelID = arg1, arg7;
				if not ChatFrame_CheckAddChannel(self, eventType, channelID) then
					return true;
				end
			end
		end

		local chatGroup = Chat_GetChatCategory(type);
		local chatTarget = FCFManager_GetChatTarget(chatGroup, arg2, arg8);

		if ( FCFManager_ShouldSuppressMessage(self, chatGroup, chatTarget) ) then
			return true;
		end

		if ( chatGroup == "WHISPER" or chatGroup == "BN_WHISPER" ) then
			if ( self.privateMessageList and not self.privateMessageList[strlower(arg2)] ) then
				return true;
			elseif ( self.excludePrivateMessageList and self.excludePrivateMessageList[strlower(arg2)]
				and ( (chatGroup == "WHISPER" and GetCVar("whisperMode") ~= "popout_and_inline") or (chatGroup == "BN_WHISPER" and GetCVar("whisperMode") ~= "popout_and_inline") ) ) then
				return true;
			end
		end

		if (self.privateMessageList) then
			-- Dedicated BN whisper windows need online/offline messages for only that player
			if ( (chatGroup == "BN_INLINE_TOAST_ALERT" or chatGroup == "BN_WHISPER_PLAYER_OFFLINE") and not self.privateMessageList[strlower(arg2)] ) then
				return true;
			end

			-- HACK to put certain system messages into dedicated whisper windows
			if ( chatGroup == "SYSTEM") then
				local matchFound = false;
				local message = strlower(arg1);
				for playerName, _ in pairs(self.privateMessageList) do
					local playerNotFoundMsg = strlower(format(ERR_CHAT_PLAYER_NOT_FOUND_S, playerName));
					local charOnlineMsg = strlower(format(ERR_FRIEND_ONLINE_SS, playerName, playerName));
					local charOfflineMsg = strlower(format(ERR_FRIEND_OFFLINE_S, playerName));
					if ( message == playerNotFoundMsg or message == charOnlineMsg or message == charOfflineMsg) then
						matchFound = true;
						break;
					end
				end

				if (not matchFound) then
					return true;
				end
			end
		end

		if ( type == "SYSTEM" or type == "SKILL" or type == "CURRENCY" or type == "MONEY" or
			 type == "OPENING" or type == "TRADESKILLS" or type == "PET_INFO" or type == "TARGETICONS" or type == "BN_WHISPER_PLAYER_OFFLINE") then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id);
		elseif (type == "LOOT") then
			-- Append [Share] hyperlink if this is a valid social item and you are the looter.
			if (C_Social.IsSocialEnabled() and UnitGUID("player") == arg12) then
				-- Because it is being placed inside another hyperlink (the shareitem link created below), we have to strip off the hyperlink markup
				-- The item link markup will be added back in when the shareitem link is clicked (in ItemRef.lua) and then passed to the social panel
				local itemID, strippedItemLink = GetItemInfoFromHyperlink(arg1);
				if (itemID and C_Social.GetLastItem() == itemID) then
					arg1 = arg1 .. " " .. Social_GetShareItemLink(strippedItemLink, true);
				end
			end
			self:AddMessage(arg1, info.r, info.g, info.b, info.id);
		elseif ( strsub(type,1,7) == "COMBAT_" ) then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id);
		elseif ( strsub(type,1,6) == "SPELL_" ) then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id);
		elseif ( strsub(type,1,10) == "BG_SYSTEM_" ) then
			self:AddMessage(arg1, info.r, info.g, info.b, info.id);
		elseif ( strsub(type,1,11) == "ACHIEVEMENT" ) then
			-- Append [Share] hyperlink
			if (arg12 == UnitGUID("player") and C_Social.IsSocialEnabled()) then
				local achieveID = GetAchievementInfoFromHyperlink(arg1);
				if (achieveID) then
					arg1 = arg1 .. " " .. Social_GetShareAchievementLink(achieveID, true);
				end
			end
			self:AddMessage(arg1:format(GetPlayerLink(arg2, ("[%s]"):format(coloredName))), info.r, info.g, info.b, info.id);
		elseif ( strsub(type,1,18) == "GUILD_ACHIEVEMENT" ) then
			local message = arg1:format(GetPlayerLink(arg2, ("[%s]"):format(coloredName)));
			if (C_Social.IsSocialEnabled()) then
				local achieveID = GetAchievementInfoFromHyperlink(arg1);
				if (achieveID) then
					local isGuildAchievement = select(12, GetAchievementInfo(achieveID));
					if (isGuildAchievement) then
						message = message .. " " .. Social_GetShareAchievementLink(achieveID, true);
					end
				end
			end
			self:AddMessage(message, info.r, info.g, info.b, info.id);
		elseif ( type == "IGNORED" ) then
			self:AddMessage(format(CHAT_IGNORED, arg2), info.r, info.g, info.b, info.id);
		elseif ( type == "FILTERED" ) then
			self:AddMessage(format(CHAT_FILTERED, arg2), info.r, info.g, info.b, info.id);
		elseif ( type == "RESTRICTED" ) then
			self:AddMessage(CHAT_RESTRICTED_TRIAL, info.r, info.g, info.b, info.id);
		elseif ( type == "CHANNEL_LIST") then
			if(channelLength > 0) then
				self:AddMessage(format(_G["CHAT_"..type.."_GET"]..arg1, tonumber(arg8), arg4), info.r, info.g, info.b, info.id);
			else
				self:AddMessage(arg1, info.r, info.g, info.b, info.id);
			end
		elseif (type == "CHANNEL_NOTICE_USER") then
			local globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"];
			if ( not globalstring ) then
				globalstring = _G["CHAT_"..arg1.."_NOTICE"];
			end
			if not globalstring then
				GMError(("Missing global string for %q"):format("CHAT_"..arg1.."_NOTICE_BN"));
				return;
			end
			if(arg5 ~= "") then
				-- TWO users in this notice (E.G. x kicked y)
				self:AddMessage(format(globalstring, arg8, arg4, arg2, arg5), info.r, info.g, info.b, info.id);
			elseif ( arg1 == "INVITE" ) then
				local playerLink = GetPlayerLink(arg2, ("[%s]"):format(arg2), arg11);
				local accessID = ChatHistory_GetAccessID(chatGroup, chatTarget);
				local typeID = ChatHistory_GetAccessID(infoType, chatTarget, arg12);
				self:AddMessage(format(globalstring, arg4, playerLink), info.r, info.g, info.b, info.id, accessID, typeID);
			else
				self:AddMessage(format(globalstring, arg8, arg4, arg2), info.r, info.g, info.b, info.id);
			end
			if ( arg1 == "INVITE" and GetCVarBool("blockChannelInvites") ) then
				self:AddMessage(CHAT_MSG_BLOCK_CHAT_CHANNEL_INVITE, info.r, info.g, info.b, info.id);
			end
		elseif (type == "CHANNEL_NOTICE") then
			local accessID = ChatHistory_GetAccessID(Chat_GetChatCategory(type), arg8);
			local typeID = ChatHistory_GetAccessID(infoType, arg8, arg12);

			if arg1 == "YOU_CHANGED" and C_ChatInfo.GetChannelRuleset(arg8) == Enum.ChatChannelRuleset.Mentor then
				ChatFrame_UpdateDefaultChatTarget(self);
				ChatEdit_UpdateNewcomerEditBoxHint(self.editBox);
			else
				if arg1 == "YOU_LEFT" then
					ChatEdit_UpdateNewcomerEditBoxHint(self.editBox, arg8);
				end

				local globalstring;
				if ( arg1 == "TRIAL_RESTRICTED" ) then
					globalstring = CHAT_TRIAL_RESTRICTED_NOTICE_TRIAL;
				else
					globalstring = _G["CHAT_"..arg1.."_NOTICE_BN"];
					if ( not globalstring ) then
						globalstring = _G["CHAT_"..arg1.."_NOTICE"];
						if not globalstring then
							GMError(("Missing global string for %q"):format("CHAT_"..arg1.."_NOTICE"));
							return;
						end
					end
				end

				self:AddMessage(format(globalstring, arg8, ChatFrame_ResolvePrefixedChannelName(arg4)), info.r, info.g, info.b, info.id, accessID, typeID);
			end
		elseif ( type == "BN_INLINE_TOAST_ALERT" ) then
			local globalstring = _G["BN_INLINE_TOAST_"..arg1];
			if not globalstring then
				GMError(("Missing global string for %q"):format("BN_INLINE_TOAST_"..arg1));
				return;
			end
			local message;
			if ( arg1 == "FRIEND_REQUEST" ) then
				message = globalstring;
			elseif ( arg1 == "FRIEND_PENDING" ) then
				message = format(BN_INLINE_TOAST_FRIEND_PENDING, BNGetNumFriendInvites());
			elseif ( arg1 == "FRIEND_REMOVED" or arg1 == "BATTLETAG_FRIEND_REMOVED" ) then
				message = format(globalstring, arg2);
			elseif ( arg1 == "FRIEND_ONLINE" or arg1 == "FRIEND_OFFLINE") then
				local accountInfo = C_BattleNet.GetAccountInfoByID(arg13);
				if accountInfo and accountInfo.gameAccountInfo.clientProgram ~= "" then
					local characterName = BNet_GetValidatedCharacterNameWithClientEmbeddedAtlas(accountInfo.gameAccountInfo.characterName, accountInfo.battleTag, accountInfo.gameAccountInfo.clientProgram, 14);
					local linkDisplayText = ("[%s] (%s)"):format(arg2, characterName);
					local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, Chat_GetChatCategory(type), 0);
					message = format(globalstring, playerLink);
				else
					local linkDisplayText = ("[%s]"):format(arg2);
					local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, Chat_GetChatCategory(type), 0);
					message = format(globalstring, playerLink);
				end
			else
				local linkDisplayText = ("[%s]"):format(arg2);
				local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, Chat_GetChatCategory(type), 0);
				message = format(globalstring, playerLink);
			end
			self:AddMessage(message, info.r, info.g, info.b, info.id);
		elseif ( type == "BN_INLINE_TOAST_BROADCAST" ) then
			if ( arg1 ~= "" ) then
				arg1 = RemoveNewlines(RemoveExtraSpaces(arg1));
				local linkDisplayText = ("[%s]"):format(arg2);
				local playerLink = GetBNPlayerLink(arg2, linkDisplayText, arg13, arg11, Chat_GetChatCategory(type), 0);
				self:AddMessage(format(BN_INLINE_TOAST_BROADCAST, playerLink, arg1), info.r, info.g, info.b, info.id);
			end
		elseif ( type == "BN_INLINE_TOAST_BROADCAST_INFORM" ) then
			if ( arg1 ~= "" ) then
				arg1 = RemoveExtraSpaces(arg1);
				self:AddMessage(BN_INLINE_TOAST_BROADCAST_INFORM, info.r, info.g, info.b, info.id);
			end
		else
			local body;

			local _, fontHeight = FCF_GetChatWindowInfo(self:GetID());

			if ( fontHeight == 0 ) then
				--fontHeight will be 0 if it's still at the default (14)
				fontHeight = 14;
			end

			-- Add AFK/DND flags
			local pflag = GetPFlag(...);

			if ( type == "WHISPER_INFORM" and GMChatFrame_IsGM and GMChatFrame_IsGM(arg2) ) then
				return;
			end

			local showLink = 1;
			if ( strsub(type, 1, 7) == "MONSTER" or strsub(type, 1, 9) == "RAID_BOSS") then
				showLink = nil;
			else
				arg1 = gsub(arg1, "%%", "%%%%");
			end

			-- Search for icon links and replace them with texture links.
			arg1 = C_ChatInfo.ReplaceIconAndGroupExpressions(arg1, arg17, not ChatFrame_CanChatGroupPerformExpressionExpansion(chatGroup)); -- If arg17 is true, don't convert to raid icons

			--Remove groups of many spaces
			arg1 = RemoveExtraSpaces(arg1);

			local playerLink;
			local playerLinkDisplayText = coloredName;
			local relevantDefaultLanguage = self.defaultLanguage;
			if ( (type == "SAY") or (type == "YELL") ) then
				relevantDefaultLanguage = self.alternativeDefaultLanguage;
			end
			local usingDifferentLanguage = (arg3 ~= "") and (arg3 ~= relevantDefaultLanguage);
			local usingEmote = (type == "EMOTE") or (type == "TEXT_EMOTE");

			if ( usingDifferentLanguage or not usingEmote ) then
				playerLinkDisplayText = ("[%s]"):format(coloredName);
			end

			local isCommunityType = type == "COMMUNITIES_CHANNEL";
			local playerName, lineID, bnetIDAccount = arg2, arg11, arg13;
			if ( isCommunityType ) then
				local isBattleNetCommunity = bnetIDAccount ~= nil and bnetIDAccount ~= 0;
				local messageInfo, clubId, streamId, clubType = C_Club.GetInfoFromLastCommunityChatLine();
				if (messageInfo ~= nil) then
					if ( isBattleNetCommunity ) then
						playerLink = GetBNPlayerCommunityLink(playerName, playerLinkDisplayText, bnetIDAccount, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position);
					else
						playerLink = GetPlayerCommunityLink(playerName, playerLinkDisplayText, clubId, streamId, messageInfo.messageId.epoch, messageInfo.messageId.position);
					end
				else
					playerLink = playerLinkDisplayText;
				end
			else
				if ( type == "BN_WHISPER" or type == "BN_WHISPER_INFORM" ) then
					playerLink = GetBNPlayerLink(playerName, playerLinkDisplayText, bnetIDAccount, lineID, chatGroup, chatTarget);
				else
					playerLink = GetPlayerLink(playerName, playerLinkDisplayText, lineID, chatGroup, chatTarget);
				end
			end

			local message = arg1;
			if ( arg14 ) then	--isMobile
				message = ChatFrame_GetMobileEmbeddedTexture(info.r, info.g, info.b)..message;
			end

			if ( usingDifferentLanguage ) then
				local languageHeader = "["..arg3.."] ";
				if ( showLink and (arg2 ~= "") ) then
					body = format(_G["CHAT_"..type.."_GET"]..languageHeader..message, pflag..playerLink);
				else
					body = format(_G["CHAT_"..type.."_GET"]..languageHeader..message, pflag..arg2);
				end
			else
				if ( not showLink or arg2 == "" ) then
					if ( type == "TEXT_EMOTE" ) then
						body = message;
					else
						body = format(_G["CHAT_"..type.."_GET"]..message, pflag..arg2, arg2);
					end
				else
					if ( type == "EMOTE" ) then
						body = format(_G["CHAT_"..type.."_GET"]..message, pflag..playerLink);
					elseif ( type == "TEXT_EMOTE") then
						body = string.gsub(message, arg2, pflag..playerLink, 1);
					elseif (type == "GUILD_ITEM_LOOTED") then
						body = string.gsub(message, "$s", GetPlayerLink(arg2, playerLinkDisplayText));
					else
						body = format(_G["CHAT_"..type.."_GET"]..message, pflag..playerLink);
					end
				end
			end

			-- Add Channel
			if (channelLength > 0) then
				if Module.Settings.UseChatShortChannels then
					body = "|Hchannel:channel:"..arg8.."|h["..arg8.."]|h "..body;
				else
					body = "|Hchannel:channel:"..arg8.."|h["..ChatFrame_ResolvePrefixedChannelName(arg4).."]|h "..body;
				end
			end

			--Add Timestamps
			local chatTimestampFmt = GetChatTimestampFormat();
			if ( chatTimestampFmt ) then
				body = BetterDate(chatTimestampFmt, time())..body;
			end

			local accessID = ChatHistory_GetAccessID(chatGroup, chatTarget);
			local typeID = ChatHistory_GetAccessID(infoType, chatTarget, arg12 or arg13);
			self:AddMessage(body, info.r, info.g, info.b, info.id, accessID, typeID);
		end

		if ( type == "WHISPER" or type == "BN_WHISPER" ) then
			--BN_WHISPER FIXME
			ChatEdit_SetLastTellTarget(arg2, type);

			if ( not self.tellTimer or (GetTime() > self.tellTimer) ) then
				PlaySound(SOUNDKIT.TELL_MESSAGE);
			end
			self.tellTimer = GetTime() + CHAT_TELL_ALERT_TIME;
			--FCF_FlashTab(self);
			FlashClientIcon();
		end

		if ( not self:IsShown() ) then
			if ( (self == DEFAULT_CHAT_FRAME and info.flashTabOnGeneral) or (self ~= DEFAULT_CHAT_FRAME and info.flashTab) ) then
				if ( not CHAT_OPTIONS.HIDE_FRAME_ALERTS or type == "WHISPER" or type == "BN_WHISPER" ) then	--BN_WHISPER FIXME
					if (not FCFManager_ShouldSuppressMessageFlash(self, chatGroup, chatTarget) ) then
						FCF_StartAlertFlash(self);
					end
				end
			end
		end

		return true;
	elseif ( event == "VOICE_CHAT_CHANNEL_TRANSCRIBING_CHANGED" ) then
		local _, isNowTranscribing = ...
		if ( not self.isTranscribing and isNowTranscribing ) then
			ChatFrame_DisplaySystemMessage(self, SPEECH_TO_TEXT_STARTED);
		end
		self.isTranscribing = isNowTranscribing;
	end
end

-- Function copied from Blizzard's ChatFrame.lua
function ChatFrame_AddMessageEventFilter (event, filter)
	assert(event and filter);

	if ( chatFilters[event] ) then
		-- Only allow a filter to be added once
		for index, filterFunc in next, chatFilters[event] do
			if ( filterFunc == filter ) then
				return;
			end
		end
	else
		chatFilters[event] = {};
	end

	tinsert(chatFilters[event], filter);
end