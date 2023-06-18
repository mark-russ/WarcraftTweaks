local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Mail")

local createBtn = function()
    local btn=CreateFrame("Button",name,parent,"SecureActionButtonTemplate");
    btn:SetSize(30,30);

    --      Setup button text
    btn:SetNormalFontObject("GameFontNormalSmall");
    btn:SetHighlightFontObject("GameFontHighlightSmall");
    btn:SetDisabledFontObject("GameFontDisableSmall");
    btn:SetText(text);
    return btn
end


function Module:OnModuleRegistered()
    --local ContactsList = CreateFrame("FRAME", "ContactsList", MailFrame, "DefaultPanelFlatTemplate")
    --ContactsList:SetTitle("Contacts")
    --ContactsList:SetPoint("TOP", MailFrame, "TOP", 0, 0)
    --ContactsList:SetPoint("BOTTOM", MailFrame, "BOTTOM", 0, 0)
    --ContactsList:SetPoint("LEFT", MailFrame, "RIGHT", -2, 0)
    --ContactsList:SetWidth(200)
    --ContactsList:SetParent(MailFrame)
    --ContactsList:SetFrameStrata(MailFrame:GetFrameStrata())
    --ContactsList:SetFrameLevel(MailFrame:GetFrameLevel())
    --ContactsList:SetShown(false)
    --ContactsList:EnableMouse(true)
    
    --local ScrollableFrame = CreateFrame("FRAME", "ScrollableFrame", ContactsList, "ScrollingFlatPanelTemplate") ScrollFrameTemplate  --WowScrollBoxList
    --ScrollableFrame:SetParent(ContactsList)
    --ScrollableFrame:SetAllPoints(ContactsList)

--ScrollFrameTemplate

    local ScrollableFrame = CreateFrame("FRAME", "ScrollableFrame", MailFrame, "DefaultPanelFlatTemplate") --WowScrollBoxList
    ScrollableFrame:SetTitle("Contacts")
    ScrollableFrame:SetWidth(200)
    ScrollableFrame:SetPoint("TOP", MailFrame, "TOP", 0, 0)
    ScrollableFrame:SetPoint("BOTTOM", MailFrame, "BOTTOM", 0, 0)
    ScrollableFrame:SetPoint("LEFT", MailFrame, "RIGHT", -2, 0)
    ScrollableFrame:SetFrameStrata(MailFrame:GetFrameStrata())
    --ScrollableFrame:SetFrameLevel(MailFrame:GetFrameLevel())
    ScrollableFrame:EnableMouse(true)

    local sb = CreateFrame("EventFrame", nil, ScrollableFrame, SCROLL_FRAME_SCROLL_BAR_TEMPLATE)
    ScrollableFrame.ScrollBar = sb
    sb:SetPoint("TOP", ScrollableFrame.Bg, "TOP", 0, -6)
    sb:SetPoint("BOTTOM", ScrollableFrame.Bg, "BOTTOM", 0, 6)
    sb:SetPoint("RIGHT", ScrollableFrame.Bg, "RIGHT", -3, 0)
    sb:SetWidth(ScrollableFrame.ScrollBar.Forward:GetWidth())
    sb:SetParent(ScrollableFrame)

    local sf = CreateFrame("ScrollFrame", nil, ScrollableFrame, "WowScrollBoxList") --WowScrollBoxList
    ScrollableFrame.ScrollBox = sf
    sf:SetPoint("TOP", ScrollableFrame.Bg, "TOP", 0, 0)
    sf:SetPoint("BOTTOM", ScrollableFrame.Bg, "BOTTOM", 0, 0)
    sf:SetPoint("LEFT", ScrollableFrame.Bg, "LEFT", 0, 0)
    sf:SetPoint("RIGHT", sb, "LEFT", -3, 0)
    sf:SetParent(ScrollableFrame)
    
	local view = CreateScrollBoxListLinearView(ScrollBoxPad, ScrollBoxPad, ScrollBoxPad, ScrollBoxPad, ScrollBoxSpacing);
	view:SetElementFactory(function(factory, elementData)
        factory("UIPanelButtonTemplate", function(item, elementData)
            item.index = elementData.index;
            item:SetText(elementData.name);
            item.type = SQUELCH_TYPE_IGNORE;
            item:SetScript("OnClick", function()
                print("CLICK")
            end)

            print("MAKE IT")
        end);

        --factory("LootFrameMoneyElementTemplate", Initializer);
	end)
	ScrollUtil.InitScrollBoxWithScrollBar(ScrollableFrame.ScrollBox, ScrollableFrame.ScrollBar, view);
    
	local dataProvider = CreateDataProvider();
    dataProvider:Insert({ index = 0, name = "Mithindis", selected = true });
    ScrollableFrame.ScrollBox:SetDataProvider(dataProvider);
    
    SendMailFrame:HookScript("OnShow", function()
        ScrollableFrame:Show()
    end)
    
    SendMailFrame:HookScript("OnHide", function()
        ScrollableFrame:Hide()
    end)
end