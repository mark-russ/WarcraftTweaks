local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("Chat")

function Module:GetConfig()
    return {
		Chat = {
			name = "Chat",
			type = "group",
			order = 2,
			inline = true,
			args = {
                IsEnabled = {
                    name = "Enable Module",
                    desc = "If checked, chat will become adjustable.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full"
                },
				UseChatShortChannels = {
					name = "Shorten channel names",
					desc = "Uses only the channel number instead of the whole channel name",
					order = 2,
					type = "toggle",
					default = false,
					width = "full"
				},
				MaxHistoryCount = {
					name = "Maximum message history",
					desc = "Maximum amount of messages to keep in history.",
					order = 3,
					type = "range",
					default = 0,
					step = 100,
					min = 0,
					max = 1000,
					width = 1.5
				},
				ClearHistory = {
					name = "Clear History",
					desc = "Clears both the chat history and all chat windows.",
					order = 4,
					type = "execute",
					width = 1.5,
					confirm = function()
						return "Are you sure you want to clear the history (including chat window)?"
					end,
					func = function()
						for i = 1, NUM_CHAT_WINDOWS do
							_G["ChatFrame"..i]:Clear()
							Module.Settings.Chat.History[i] = {}
						end
					end
				},
				EditBox = {
					name = "",
					hidden = true,
					inline = true,
					type = "group",
					args = {
						ChannelTarget = {
							name = "",
							hidden = true,
							type = "input"
						},
						ChatType = {
							name = "",
							hidden = true,
							type = "input"
						},
						StickyType = {
							name = "",
							hidden = true,
							type = "input"
						},
						TellTarget = {
							name = "",
							hidden = true,
							type = "input"
						},
					}
				},
				LastTellTarget = {
					name = "",
					hidden = true,
					type = "input"
				},
				LastTellType = {
					name = "",
					hidden = true,
					type = "input"
				}
			}
		}
    }
end

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "Chat", AddonName)
	if Module.Settings.Chat.History == nil then
		Module.Settings.Chat.History = {}
	end
	
	Module:InitShortNameResolver()
	Module:LoadHistory()
	Module:InitChatRecorder()

	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame"..i];

		if (IsCombatLog(chatFrame)) then
			chatFrame:Hide()
			chatFrame.isDocked = false
			chatFrame.isTemporary = true
			FCF_Close(chatFrame)
		end
	end
end

function Module:LoadHistory()
	Module.IsHistoryLoaded = false;

	-- Populate the chat windows with the chat history.
	for i = 1, NUM_CHAT_WINDOWS do
		if Module.Settings.Chat.History[i] == nil then
			Module.Settings.Chat.History[i] = {}
		end

		-- Add history messages to chat frame.
		if Module.Settings.Chat.MaxHistoryCount > 0 then
			local chatFrame = _G["ChatFrame"..i]
			chatFrame:Clear()

			if Module.Settings.Chat.MaxHistoryCount > 128 then
				chatFrame:SetMaxLines(Module.Settings.Chat.MaxHistoryCount)
			end
			
			for _, messageEvent in pairs(Module.Settings.Chat.History[i]) do
				local chatMsg = messageEvent[1];
				local eventType = messageEvent[8];
				
				if (eventType == "CHAT_MSG_BN_WHISPER_INFORM" or eventType == "CHAT_MSG_BN_WHISPER") then
					local senderBattleTag = messageEvent[9];
					local foundKString = Module:FindFriendDisplayNameByBattleTag(senderBattleTag);

					if (foundKString ~= nil) then
						local mutatedMessage = Module:ReplaceMessageKStrings(chatMsg, foundKString);
						chatFrame:AddMessage(mutatedMessage, select(2, unpack(messageEvent)));
					end
				else -- Forward message normally.
					chatFrame:AddMessage(unpack(messageEvent));
				end
			end
		end
	end

	Module.IsHistoryLoaded = true
end

-- Blizzard encodes Battle NET friend links as KStrings to protect the name of BNET friends.
-- They come out as something like:
-- 	  To |HBNplayer:|Kq9|k:21:2:BN_WHISPER:|Kq9|k|h[|Kq9|k]|h: Test
function Module:ReplaceMessageKStrings(chatMsg, newKString)
	local explodedMsg = { strsplit(":", chatMsg) }
	return string.gsub(chatMsg, "|K.-|.", newKString)
end

function Module:FindFriendDisplayNameByBattleTag(battleTag)
	local friendCount = BNGetNumFriends();

	for i = 1, friendCount do
		local friendDetails = C_BattleNet.GetAccountInfoByID(i);
		
		if (friendDetails == nil) then
			return "UNKNOWN";
		end

		if (friendDetails ~= nil and friendDetails.battleTag == battleTag) then
			return friendDetails.accountName;
		end
	end

	return nil;
end

function Module:InitChatRecorder()
	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame"..i]
        
		if Module.Settings.Chat.MaxHistoryCount > 0 then
			WTweaks:HookSecure(chatFrame, "AddMessage", function(frame, ...)
				if Module.IsHistoryLoaded then
					local payload =  { ... };
					local eventType = payload[8];

					if (eventType == "CHAT_MSG_BN_WHISPER_INFORM" or eventType == "CHAT_MSG_BN_WHISPER") then
						local message = payload[1];
						local explodedMsg = { strsplit(":", message) }
						local accountId = explodedMsg[3];
						local friendDetails = C_BattleNet.GetAccountInfoByID(accountId);
						payload[9] = friendDetails.battleTag; -- Attach battleTag to message.
					end
					
					tinsert(Module.Settings.Chat.History[i], payload);
				end
			end)
		end
	end

	WTweaks:HookEvent("PLAYER_LEAVING_WORLD", function()
		Module:TrimChatHistory()
	end)
end

function Module:InitShortNameResolver()
	if Module.Settings.Chat.UseChatShortChannels then
		-- If UseChatShortChannels is being set for the first time...
		if Module.BlizzResolvePrefixedChannelName == nil then
			-- Back up the function and overload with our implementation.
			Module.BlizzResolvePrefixedChannelName = _G.ChatFrame_ResolvePrefixedChannelName
			_G.ChatFrame_ResolvePrefixedChannelName = function (communityChannel)
				return communityChannel:match("%d+");
			end
		end
	elseif Module.BlizzResolvePrefixedChannelName ~= nil then
		-- If UseChatShortChannels is being toggled off, restore original function.
		_G.ChatFrame_ResolvePrefixedChannelName = Module.BlizzResolvePrefixedChannelName
		Module.BlizzResolvePrefixedChannelName = nil
	end
end

function Module:TrimChatHistory()
	-- If there are more saved messages in the history table than allowed, purge them.
	for i = 1, NUM_CHAT_WINDOWS do
		local messageCount = getn(Module.Settings.Chat.History[i])

		if messageCount > Module.Settings.Chat.MaxHistoryCount then
			local amountToDelete = messageCount - Module.Settings.Chat.MaxHistoryCount
			Module.Settings.Chat.History[i] = { unpack(Module.Settings.Chat.History[i], amountToDelete + 1) }
		end
	end
end