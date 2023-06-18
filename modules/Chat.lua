local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Chat")

function Module:OnModuleRegistered()
    Module:Init(false)
	WTweaks:AddOptionPage(Module.Name, "Chat", AddonName)
	WTweaks:HookEvent("PLAYER_LEAVING_WORLD", Module.OnPlayerDisconnect)
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init(true)
end

function Module:Init(isRefreshing)
	if not Module.Settings.Chat.IsEnabled then
		-- If module is being unloaded then reload the UI.
		if Module.IsLoaded then
			ReloadUI()
		end

		return
	end
	Module.IsLoaded = true

	if not isRefreshing then
		Module.IsHistoryLoaded = false
		Module.IsEnabled = false
		Module:LoadChatHistory()
	end

	Module.ChatOutline = Module.Settings.Chat.ShowChatOutline and "OUTLINE" or ""

	-- Apply chat styling.
	local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.Chat.ChatFont)

	ChatBubbleFont:SetFont(fontFile, Module.Settings.Chat.ChatFontSize, Module.ChatOutline)

	-- Chat edit box.
	ChatFontNormal:SetFont(fontFile, Module.Settings.Chat.ChatFontSize, Module.ChatOutline)

	for i = 1, NUM_CHAT_WINDOWS do
		local chatFrame = _G["ChatFrame"..i]
		chatFrame:SetFont(fontFile, select(2, chatFrame:GetFont()), Module.ChatOutline)

		if Module.Settings.Chat.MaxHistoryCount > 0 then
			WTweaks:HookSecure(chatFrame, "AddMessage", function(frame, ...)
				if Module.IsHistoryLoaded then
					tinsert(Module.Settings.Chat.History[i], { ... })
				end
			end)
		end
	end

	Module:SetupShortNameResolver()
	Module:RestoreEditBoxState()
end

function Module:OnPlayerDisconnect()
	Module:SaveEditBoxState()

	-- If there are more saved messages in the history table than allowed, purge them.
	for i = 1, NUM_CHAT_WINDOWS do
		local messageCount = getn(Module.Settings.Chat.History[i])

		if messageCount > Module.Settings.Chat.MaxHistoryCount then
			local amountToDelete = messageCount - Module.Settings.Chat.MaxHistoryCount
			Module.Settings.Chat.History[i] = { unpack(Module.Settings.Chat.History[i], amountToDelete + 1) }
		end
	end
end

function Module:SaveEditBoxState()
	Module.Settings.Chat.LastTellTarget, Module.Settings.Chat.LastTellType = ChatEdit_GetLastTellTarget()
	Module.Settings.Chat.EditBox.TellTarget = DEFAULT_CHAT_FRAME.editBox:GetAttribute("tellTarget")
	Module.Settings.Chat.EditBox.ChannelTarget = DEFAULT_CHAT_FRAME.editBox:GetAttribute("channelTarget")
	Module.Settings.Chat.EditBox.ChatType = DEFAULT_CHAT_FRAME.editBox:GetAttribute("chatType")
	Module.Settings.Chat.EditBox.StickyType = DEFAULT_CHAT_FRAME.editBox:GetAttribute("stickyType")
end

function Module:RestoreEditBoxState()
	if Module.Settings.Chat.LastTellType then
		ChatEdit_SetLastTellTarget(Module.Settings.Chat.LastTellTarget, Module.Settings.Chat.LastTellType)
	end
	
	if Module.Settings.Chat.EditBox.TellTarget then
		DEFAULT_CHAT_FRAME.editBox:SetAttribute("tellTarget", 		Module.Settings.Chat.EditBox.TellTarget)
	end

	if Module.Settings.Chat.EditBox.ChannelTarget then
		DEFAULT_CHAT_FRAME.editBox:SetAttribute("channelTarget", 	Module.Settings.Chat.EditBox.ChannelTarget)
	end
		
	if Module.Settings.Chat.EditBox.ChatType then
		DEFAULT_CHAT_FRAME.editBox:SetAttribute("chatType", 	Module.Settings.Chat.EditBox.ChatType)
	end
		
	if Module.Settings.Chat.EditBox.StickyType then
		DEFAULT_CHAT_FRAME.editBox:SetAttribute("stickyType", 	Module.Settings.Chat.EditBox.StickyType)
	end
end

function Module:LoadChatHistory()
	if Module.Settings.Chat.History == nil then
		Module.Settings.Chat.History = {}
	end

	if Module.IsHistoryLoaded == false then
		-- Populate the chat windows with the chat history.
		for i = 1, NUM_CHAT_WINDOWS do
			local chatFrame = _G["ChatFrame"..i]

			if Module.Settings.Chat.History[i] == nil then
				Module.Settings.Chat.History[i] = {}
			end

			-- Add history messages to chat frame.
			if Module.Settings.Chat.MaxHistoryCount > 0 then
				chatFrame:Clear()
				
				for _, chatMessage in pairs(Module.Settings.Chat.History[i]) do
					chatFrame:AddMessage(unpack(chatMessage))
				end
			end
		end

		Module.IsHistoryLoaded = true
	end
end

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
				ChatFont = {
					name = "Font",
                    dialogControl = "LSM30_Font",
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
				ChatFontSize = {
					name = "Chat Textbox Font Size",
					desc = "Affects the chat edit textbox size, this does not affect the chat font size, which is saved per-frame using Blizzard's options.",
					order = 3,
					type = "range",
					default = 12,
					step = 1,
					min = 10,
					max = 20
				},
				UseChatShortChannels = {
					name = "Shorten channel names",
					desc = "Uses only the channel number instead of the whole channel name",
					order = 2,
					type = "toggle",
					default = false
				},
				MaxHistoryCount = {
					name = "Maximum message history",
					desc = "Maximum amount of messages to keep in history.",
					order = 3,
					type = "range",
					default = 0,
					step = 10,
					min = 0,
					max = 100
				},
				ClearHistory = {
					name = "Clear History",
					desc = "Clears both the chat history and all chat windows.",
					order = 4,
					type = "execute",
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

function Module:SetupShortNameResolver()
	if Module.Settings.Chat.UseChatShortChannels then
		-- If UseChatShortChannels is being set for the first time...
		if Module.OriginalResolvePrefixedChannelNameFunc == nil then
			-- Back up the function and overload with our implementation.
			Module.OriginalResolvePrefixedChannelNameFunc = _G.ChatFrame_ResolvePrefixedChannelName
			_G.ChatFrame_ResolvePrefixedChannelName = function (communityChannel)
				return communityChannel:match("%d+");
			end
		end
	elseif Module.OriginalResolvePrefixedChannelNameFunc ~= nil then
		-- If UseChatShortChannels is being toggled off, restore original function.
		_G.ChatFrame_ResolvePrefixedChannelName = Module.OriginalResolvePrefixedChannelNameFunc
		Module.OriginalResolvePrefixedChannelNameFunc = nil
	end
end
