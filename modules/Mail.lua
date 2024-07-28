local AddonName, WTweaks = ...;
local Module = WTweaks:RegisterModule("Mail");
Module.IsDataInitialized = false;
Module.ReferenceKey = "WarcraftTweaks_Mail";
Module.DataProviders = {
    Alts = {},
    Others = {}
};

function Module:RegisterTab(text, canAddPlayers)
    local tab = CreateFrame("Button", "ContactsFrameTab" .. MailContactsFrame.numTabs , MailContactsFrame, "PanelTabButtonTemplate");
    tab.index = MailContactsFrame.numTabs + 1;
    tab:SetParent(MailContactsFrame)
    tab:SetText(text)
    tab:SetScript("OnClick", function(self)
        PanelTemplates_SetTab(MailContactsFrame, self.index);
        MailContactsFrame.ScrollBox:SetDataProvider(Module.DataProviders[text]);
        --MailContactsFrame.PlayerAddPanel:SetShown(canAddPlayers)
    end);

    MailContactsFrame.numTabs = tab.index;
    MailContactsFrame.Tabs[MailContactsFrame.numTabs] = tab;
end

function Module:OnModuleRegistered()
	if Module.Settings.Mail.Contacts == nil then
		Module.Settings.Mail.Contacts = {
            Alts = {},
            Others = {}
        }
	end
    --WTweaks:HookEvent("UPDATE_PENDING_MAIL", function(a, b)
    --    if HasNewMail() then
    --        local latestSenders = GetLatestThreeSenders()
    --        if latestSenders ~= nil then
    --            PlaySound(SOUNDKIT.TELL_MESSAGE)
    --            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00" .. HAVE_MAIL .. ":|r " .. GetLatestThreeSenders())
    --        end
    --    end
    --end);
    
    local WINDOW_WIDTH = 315
    local WINDOW_SPACE_FROM_MAILFRAME = -2
    local ITEM_LINE_HEIGHT = 20
    local SCROLLBOX_PADDING = 4
    local SCROLLBOX_SPACING = 0
    local NAME_COLUMN_WIDTH = 140
    local REALM_COLUMN_WIDTH = nil

    local Contacts = CreateFrame("FRAME", "MailContactsFrame", MailFrame, "DefaultPanelFlatTemplate")
    Contacts.Tabs = {}
    Contacts.numTabs = 0
    Contacts:SetTitle("Contacts")
    Contacts:SetWidth(WINDOW_WIDTH)
    Contacts:SetPoint("TOP", MailFrame, "TOP", 0, 0)
    Contacts:SetPoint("BOTTOM", MailFrame, "BOTTOM", 0, 0)
    Contacts:SetPoint("LEFT", MailFrame, "RIGHT", WINDOW_SPACE_FROM_MAILFRAME, 0)
    Contacts:EnableMouse(true)
    Contacts:SetShown(false)

    --local playerAddPanel = CreateFrame("Frame", nil, Contacts)
    --playerAddPanel:SetPoint("BOTTOMLEFT", Contacts, "BOTTOMLEFT", 0, 2)
    --playerAddPanel:SetPoint("BOTTOMRIGHT", Contacts, "BOTTOMRIGHT", 0, 2)
    --playerAddPanel.ShownHeight = 30
    --playerAddPanel:SetHeight(playerAddPanel.ShownHeight)
    --playerAddPanel:SetParent(Contacts)
    --Contacts.PlayerAddPanel = playerAddPanel

    local scrollBar = CreateFrame("EventFrame", nil, Contacts, SCROLL_FRAME_SCROLL_BAR_TEMPLATE)
    scrollBar:SetPoint("TOP", Contacts.Bg, "TOP", 0, -6)
    scrollBar:SetPoint("BOTTOM", Contacts.Bg, "BOTTOM", 0, 6)
    scrollBar:SetPoint("RIGHT", Contacts.Bg, "RIGHT", -3, 0)
    scrollBar:SetWidth(scrollBar.Forward:GetWidth())
    scrollBar:SetParent(Contacts)
    Contacts.ScrollBar = scrollBar

    local scrollBox = CreateFrame("ScrollFrame", nil, Contacts, "WowScrollBoxList")
    scrollBox:SetPoint("TOP", Contacts.Bg, "TOP", 0, 0)
    scrollBox:SetPoint("BOTTOM", Contacts.Bg, "BOTTOM", 0, 0)
    scrollBox:SetPoint("LEFT", Contacts.Bg, "LEFT", 0, 0)
    scrollBox:SetPoint("RIGHT", scrollBar, "LEFT", 0, 0)
    scrollBox:SetParent(Contacts)
    Contacts.ScrollBox = scrollBox

    scrollBox.Backdrop = CreateFrame("Frame", nil, Contacts.ScrollBox, "InsetFrameTemplate")
    scrollBox.Backdrop.Bg:SetVertTile(false)
    scrollBox.Backdrop.Bg:SetTexture(904010)
    scrollBox.Backdrop.Bg:SetTexCoord(0, 0.5, 0.5, 1)
    scrollBox.Backdrop:SetAllPoints(Contacts.ScrollBox)

    Module:RegisterTab("Alts", false)
    Module:RegisterTab("Others", true)
    
	local view = CreateScrollBoxListLinearView(SCROLLBOX_PADDING, SCROLLBOX_PADDING, SCROLLBOX_PADDING, SCROLLBOX_PADDING, SCROLLBOX_SPACING)
    view:SetElementExtent(ITEM_LINE_HEIGHT)
    view:SetElementInitializer("TemplatedListElementTemplate", function(frame, data)
        if frame.isCreated ~= true then
            frame.DeleteButton = CreateFrame("Button", nil, frame, "SecureHandlerClickTemplate")
            frame.DeleteButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, -1)
            frame.DeleteButton:SetPoint("BOTTOM", frame, "BOTTOM", 1, 1)
            frame.DeleteButton:SetWidth(frame.DeleteButton:GetHeight())
            frame.DeleteButton:SetParent(frame)

            frame.DeleteButton.Icon = frame.DeleteButton:CreateTexture(nil, "ARTWORK")
            frame.DeleteButton.Icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
            frame.DeleteButton.Icon:SetAllPoints(frame.DeleteButton)

            frame.NameText = frame:CreateFontString(nil, "BACKGROUND")
            frame.NameText:SetPoint("LEFT", frame, "LEFT", 0, 0)
            frame.NameText:SetParent(frame)
            frame.NameText:SetFontObject(GameFontNormal)
            frame.NameText:SetWidth(NAME_COLUMN_WIDTH)
            frame.NameText:SetJustifyH("LEFT")

            frame.RealmText = frame:CreateFontString(nil, "BACKGROUND")
            frame.RealmText:SetPoint("LEFT", frame.NameText, "RIGHT", 0, 0)
            frame.RealmText:SetParent(frame)
            frame.RealmText:SetFontObject(GameFontNormal)

            if REALM_COLUMN_WIDTH == nil then
                frame.RealmText:SetPoint("RIGHT", frame.DeleteButton, "LEFT", 0, 0)
            else
                frame.RealmText:SetWidth(REALM_COLUMN_WIDTH)
            end
            
            frame.RealmText:SetJustifyH("LEFT")
            frame.isCreated = true
        end
        
        frame.NameText:SetText(data.name)
        frame.NameText:SetTextColor(unpack(data.color))

        frame.RealmText:SetText(data.realm)
        frame.RealmText:SetTextColor(unpack(data.color))

        frame:SetScript("OnClick", function(self)
            local recipient = data.name .. "-" .. data.realm
            SendMailNameEditBox:SetText(recipient)
            SendMailSubjectEditBox:SetFocus()
        end)
        
        frame.DeleteButton:SetScript("OnClick", function(self)
            if not StaticPopup_IsCustomGenericConfirmationShown(Module.ReferenceKey) then
                StaticPopup_Show("GENERIC_CONFIRMATION", nil, nil, {
                    text = "Remove %s from your contacts list?",
                    text_arg1 = data.name,
                    showAlert = true,
                    referenceKey = Module.ReferenceKey,
                    callback = function()
                        scrollBox:GetDataProvider():Remove(data)
                    end
                }, nil)
            end
        end)
    end)

	ScrollUtil.InitScrollBoxWithScrollBar(Contacts.ScrollBox, Contacts.ScrollBar, view)

    SendMailFrame:HookScript("OnShow", function()
        if Module.IsDataInitialized ~= true then
            for providerName, val in pairs(Module.DataProviders) do
                Module.DataProviders[providerName] = Module:CreateDataProvider()
                Module:PopulateProvider(providerName)
            end

            Module.IsDataInitialized = true
            MailContactsFrame.Tabs[1]:Click()
        end

        Contacts:Show()
    end)
    
    SendMailFrame:HookScript("OnHide", function()
        Contacts:Hide()
    end)

	WTweaks:AddOptionPage(Module.Name, "Mail", AddonName)
end

function Module:CreateDataProvider()
    local dataProvider = CreateDataProvider()

    dataProvider:SetSortComparator(function(a, b)
        return a.realm < b.realm or (a.realm == b.realm and a.name < b.name)
    end, true)

    dataProvider:RegisterCallback(DataProviderMixin.Event.OnRemove, function(self, contact, maxIndex)
        Module:DeleteContact("Alts", contact.guid)
    end)
    return dataProvider
end

function Module:PopulateProvider(providerName)
    local dataProvider = Module.DataProviders[providerName]
    local myGuid = GetPlayerGuid()
    local myRealm = GetRealmName()

    for guid, details in pairs(Module.Settings.Mail.Contacts[providerName]) do
        if guid ~= myGuid then
            local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
            local r, g, b = GetClassColor(englishClass)

            if name == nil then
                Module.Settings.Mail.Contacts.Alts[guid] = nil
            else
                realm = WTweaks:Ternary(realm == "", myRealm, realm)
    
                dataProvider:Insert({
                    guid = guid,
                    name = name,
                    realm = realm,
                    isOnSameRealm = realm == myRealm,
                    race = localizedRace,
                    class = localizedClass,
                    color = { r, g, b, 1},
                })
            end
        end
    end
end

function Module:GetConfig()
    return {
		Mail = {
			name = "Mail",
			type = "group",
			order = 7,
			inline = true,
			args = {
                IsEnabled = {
                    name = "Enable Module",
                    desc = "If checked, a \"Contacts\" window will appear alongside the \"Send Mail\" window.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full"
                },
                UseNotifications = {
                    name = "Use Notifications",
                    desc = "Plays a sound and shows a text when you receive mail.",
                    type = "toggle",
                    default = true,
					order = 1
                }
			}
		}
    }
end

function Module:OnProfileLoaded()
    if Module.Settings.Mail.UseNotifications then
    end
    
    if Module.Settings.Mail.Contacts == nil then
        Module.Settings.Mail.Contacts = {
            Alts = {},
            Others = {}
        }
    end

    -- Prefetch. This function is bad about returning nil the first time it's called for certain players.
    -- I'm guessing it's because of a cache miss.
    for guid, details in pairs(Module.Settings.Mail.Contacts.Alts) do
        GetPlayerInfoByGUID(guid)
    end
end

function Module:SaveContact(providerName, guid)
    local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
    Module.Settings.Mail.Contacts[providerName][guid] = GetPlayerInfoByGUID(guid)
end

function Module:DeleteContact(providerName, guid)
    Module.Settings.Mail.Contacts[providerName][guid] = nil
end

function Module:OnPlayerEnteringWorld()
	WTweaks:HookEvent("PLAYER_LOGOUT", Module.OnLogout)
end

function Module:OnLogout()
    Module:SaveContact("Alts", GetPlayerGuid())
end