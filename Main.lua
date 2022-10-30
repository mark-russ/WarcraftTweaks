local AddonName, Vars = ...
local WTweaks = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0")
local DBName = "WarcraftTweaks"

function WTweaks:NoOp() end

function WTweaks:GetConfig()
	return {
		type = "group",
		set = WTweaks.Events.SetConfig,
		get = WTweaks.Events.GetConfig,
	  	args = {
			general = {
				type = "group",
				name = "General",
				order = 0,
				inline = true,
				args = {
					ShowXPBar = {
						name = "Show XP bar",
						desc = "This also affects the reputation bar.",
						type = "toggle"
					},
					ShowMicroBar = {
						name = "Show micro bar",
						desc = "If unchecked, the micro bar will be hidden.",
						type = "toggle"
					},
					ShowRestedXP = {
						name = "Show resting indicator",
						desc = "If unchecked, the resting indicator will be hidden.",
						type = "toggle"
					},
					ShowErrorText = {
						name = "Show red error text",
						desc = "If unchecked, the red error text will be hidden.",
						type = "toggle"
					}
				}
			},
			bags = {
				type = "group",
				name = "Bags / Vendor",
				order = 1,
				inline = true,
				args = {
					VendorJunk = {
						name = "Vendor Junk",
						desc = "Adds a vendor junk button to the bag frame.",
						order = 0,
						type = "select",
						values = {
							disabled = "Disable",
							button = "Button only",
							autoButton = "Automatic + button",
							auto = "Automatically"
						}
					},
					AutoRepair = {
						name = "Auto Repair",
						desc = "If checked, your gear will automatically be repaired.",
						order = 1,
						type = "select",
						values = {
							disabled = "Disable",
							personal = "Repair using your funds",
							guild = "Repair using guild funds"
						}
					},
					ShowReorganizeBagsButton = {
						name = "Show bag sort button",
						desc = "If unchecked, the sort button will be hidden.",
						order = 2,
						type = "toggle"
					}
				}
			}
	  	}
	} 
end

function WTweaks:OnEnable()
	WTweaks:Main()
end

function WTweaks:InitConfig()
	WTweaks.NativeEvents = {
		-- MERCHANT_SHOW = WTweaks.OnMerchantOpened
	}

	WTweaks.Events = {
		SetConfig = function(info, value)
			WTweaks.DB.profile[info[#info]] = value
			WTweaks:Main()
		end,
		GetConfig = function(info)
			return WTweaks.DB.profile[info[#info]]
		end
	}

	WTweaks.Config = {
		profile = {
			XPBarPoint = nil,
			ShowXPBar = true,
			ShowMicroBar = false,
			ShowRestedXP = false,
			ShowErrorText = false,
			ShowReorganizeBagsButton = true,
			AutoRepair = "disabled",
			VendorJunk = "button"
		}
	}
	
	WTweaks.DB = WTweaks.Libs.AceDB:New(DBName, WTweaks.Config)
	WTweaks.Libs.AceConfig:RegisterOptionsTable(AddonName, WTweaks:GetConfig())
	WTweaks.Frames.Config = WTweaks.Libs.AceCfgDialog:AddToBlizOptions(AddonName, AddonName, nil)
end


function WTweaks:InitBagTray()
	if WTweaks.BagTray ~= nil then
		return
	end

	WTweaks.BagTray = {
		Width = 0,
		Margin = 4,
		Integrations = {
			VendorJunkButton = nil,
			ReorganizeBagsButton = nil
		},
		GetCalculatedWidth = function()
			local newWidth = 0
			local visibleCount = 0
			local previousElement = BagItemSearchBox

			for k, frame in pairs(WTweaks.BagTray.Integrations) do
				if frame ~= nil and frame:IsShown() then
					newWidth = newWidth + frame:GetWidth()
					visibleCount = visibleCount + 1
					
					frame:SetPoint("LEFT", previousElement, "RIGHT", WTweaks.BagTray.Margin, 0)
					previousElement = frame
				end
			end

			if visibleCount > 0 then
				newWidth = newWidth + (WTweaks.BagTray.Margin * (visibleCount - 1))
			end

			WTweaks.BagTray.Width = newWidth
			return newWidth
		end
	}
	
	local width, height = BagItemAutoSortButton:GetSize()
	width = width - 6;
	height = height - 6;

	WTweaks.BagTray.Integrations.VendorJunkButton = WTweaks:CreateButton(ContainerFrameCombinedBags, "INTERFACE/Icons/inv_misc_coin_04", nil, nil, width, height, "Vendor Junk", "Clean all junk from your bags.")
	WTweaks.BagTray.Integrations.VendorJunkButton:SetScript("OnClick", WTweaks.VendorJunk)
	
	WTweaks.BagTray.Integrations.ReorganizeBagsButton = WTweaks:CreateButton(ContainerFrameCombinedBags, "INTERFACE/Icons/INV_Pet_Broom", nil, nil, width, height, BAG_CLEANUP_BAGS, BAG_CLEANUP_BAGS_DESCRIPTION)
	WTweaks.BagTray.Integrations.ReorganizeBagsButton:SetScript("OnClick", BagItemAutoSortButton:GetScript("OnClick"))
end

function WTweaks:OnInitialize()
	WTweaks:RegisterChatCommand("edit",  "OpenEditMode")
	WTweaks:RegisterChatCommand("tweaks", "OpenConfig")
	
	WTweaks.Libs = {
		AceGUI = LibStub("AceGUI-3.0"),
		AceDB = LibStub("AceDB-3.0"),
		AceConfig = LibStub("AceConfig-3.0"),
		AceCfgDialog = LibStub("AceConfigDialog-3.0")
	}

	WTweaks.BlizzFuncs = {}
	WTweaks.Frames = {
		Main = CreateFrame("FRAME", AddonName)
	}

	WTweaks:InitConfig()

	for eventName in pairs(WTweaks.NativeEvents) do
		WTweaks.Frames.Main:RegisterEvent(eventName);
	end
	
	WTweaks.Frames.Main:SetScript("OnEvent", function(frame, event, ...)
		WTweaks.NativeEvents[event](...)
	end)
end

function WTweaks:Main()
	WTweaks:InitBagTray()
	WTweaks:UpdateMicroBarState()
	WTweaks:UpdateXPBarState()
	WTweaks:UpdateErrorTextState()
	WTweaks:UpdateVendorJunkButtonState()
	WTweaks:UpdateRestedXPIndicatorState()
	WTweaks:UpdateReorganizeBagsButtonState()
end

function WTweaks:UpdateXPBarState()
	WTweaks:LoadFrame(StatusTrackingBarManager)
	WTweaks:MakeFrameDraggable(StatusTrackingBarManager)

	if self.DB.profile.ShowXPBar then
		StatusTrackingBarManager:Show()
	else
		StatusTrackingBarManager:Hide()
	end
end

function WTweaks:UpdateReorganizeBagsButtonState()
	WTweaks:HookSecure(BagItemAutoSortButton, "Show", BagItemAutoSortButton.Hide)
	
	if WTweaks.DB.profile.ShowReorganizeBagsButton then
		WTweaks.BagTray.Integrations.ReorganizeBagsButton:Show()
	else
		WTweaks.BagTray.Integrations.ReorganizeBagsButton:Hide()
	end
end

function WTweaks:UpdateMicroBarState()
	-- Repositions the bag frames to appear in the bottom-right corner.
	WTweaks:HookSecure(_G, "UpdateContainerFrameAnchors", function()
		if not self.DB.profile.ShowMicroBar then
			local bagFrame = WTweaks:GetBagFrame()
			
			bagFrame:ClearAllPoints()
			bagFrame:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -3, 3)
		end
	end)

	if not self.DB.profile.ShowMicroBar then
		MicroButtonAndBagsBar:Hide()

		-- Reposition the Queue indicator button.
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

function WTweaks:UpdateErrorTextState()
	if not self.DB.profile.ShowErrorText then
		UIErrorsFrame:Hide()
	else
		UIErrorsFrame:Show()
	end
end

function WTweaks:UpdateVendorJunkButtonState()
	WTweaks:HookSecure(MerchantFrame, "Show", WTweaks.OnMerchantOpened)

	WTweaks:HookSecure(ContainerFrameCombinedBags, "SetSearchBoxPoint", function()
		WTweaks.BagTray.Margin = 8
		BagItemSearchBox:SetWidth(BagItemSearchBox:GetWidth() - WTweaks.BagTray.GetCalculatedWidth() + 20)
	end)

	WTweaks:HookSecure(ContainerFrame1, "SetSearchBoxPoint", function()
		WTweaks.BagTray.Margin = 4
		BagItemSearchBox:SetWidth(BagItemSearchBox:GetWidth() - WTweaks.BagTray.GetCalculatedWidth() + 26)
	end)

	WTweaks:HookSecure(ContainerFrameCombinedBags, "Show", WTweaks.OnBackpackOpened)
	WTweaks:HookSecure(ContainerFrame1, "Show", WTweaks.OnBackpackOpened)
	
	if WTweaks.DB.profile.VendorJunk == "disabled" or WTweaks.DB.profile.VendorJunk == "auto" then
		WTweaks.BagTray.Integrations.VendorJunkButton:Hide()
	else
		WTweaks.BagTray.Integrations.VendorJunkButton:Show()
	end
end

function WTweaks:UpdateRestedXPIndicatorState()
	if not self.DB.profile.ShowRestedXP then
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetAlpha(0)
	else
		PlayerFrame.PlayerFrameContent.PlayerFrameContentContextual.PlayerRestLoop:SetAlpha(1)
	end
end

function WTweaks:IsFuncSaved(frame, funcName)
	if WTweaks.BlizzFuncs[frame] == nil then
		WTweaks.BlizzFuncs[frame] = {}
	end

	return WTweaks.BlizzFuncs[frame][funcName] ~= nil
end

function WTweaks:RemoveFunc(frame, funcName)
	-- Back the function up.
	if not WTweaks:IsFuncSaved(frame, funcName) then
		WTweaks.BlizzFuncs[frame][funcName] = frame[funcName]
	end

	-- Replace the original with no-op.
	frame[funcName] = WTweaks.NoOp
end

function WTweaks:RestoreFunc(frame, funcName)
	-- If the function was saved.
	if WTweaks:IsFuncSaved(frame, funcName) then
		frame[funcName] = WTweaks.BlizzFuncs[frame][funcName]
		WTweaks.BlizzFuncs[frame][funcName] = nil
	end
end

function WTweaks:OpenEditMode()
	EditModeManagerFrame:Show()
end

function WTweaks:OpenConfig(input)
	InterfaceOptionsFrame_OpenToCategory(AddonName)
end

function WTweaks:VendorJunk()
	if not MerchantFrame:IsShown() then
		print("|cFFFFFF00You must be speaking to a merchant.|r")
		return
	end

    for bagId = 0, NUM_BAG_SLOTS do
		local slotCount = GetContainerNumSlots(bagId)

        for slotId = 1, slotCount do
			local itemQuality = select(4, GetContainerItemInfo(bagId, slotId))
			
			if itemQuality == 0 then
				UseContainerItem(bagId, slotId)
			end
        end
    end
end

function WTweaks:RepairGear()
	local repairAllCost, canRepair = GetRepairAllCost()

	if repairAllCost > 0 and canRepair then
		if CanGuildBankRepair() and WTweaks.DB.profile.AutoRepair == "guild" then
			RepairAllItems(1)
		elseif WTweaks.DB.profile.AutoRepair == "personal" and repairAllCost <= GetMoney() then
			RepairAllItems()
		end

		local didRepair = select(1, GetRepairAllCost()) == 0

		if didRepair then
			print("|cFFFFFF00Gear repaired: |r" .. GetMoneyString(repairAllCost))
		end
	end
end

function WTweaks:GetBagFrame()
	return ContainerFrameSettingsManager:IsUsingCombinedBags() and ContainerFrameCombinedBags or ContainerFrame1
end

function WTweaks:OnBackpackOpened()
	local bagFrame = WTweaks:GetBagFrame()
	
	WTweaks.BagTray.Margin = isCombined and 8 or 4
	WTweaks.BagTray.Integrations.VendorJunkButton:SetParent(bagFrame)
	WTweaks.BagTray.Integrations.ReorganizeBagsButton:SetParent(bagFrame)
end

function WTweaks:OnMerchantOpened()
	if WTweaks.DB.profile.VendorJunk == "auto" or WTweaks.DB.profile.VendorJunk == "autoButton" then
		WTweaks:VendorJunk()
	end

	if WTweaks.DB.profile.AutoRepair ~= "disabled" then
		WTweaks:RepairGear()
	end
end

function WTweaks:HookSecure(frame, funcName, func)
	-- Ensure no duplicate hooks are created.
	if not WTweaks:IsFuncSaved(frame, funcName) then
		hooksecurefunc(frame, funcName, func)

		if WTweaks.BlizzFuncs[frame] == nil then
			WTweaks.BlizzFuncs[frame] = {}
		end

		WTweaks.BlizzFuncs[frame][funcName] = "secure"
	end
end

function WTweaks:LoadFrame(frame)
	local frameName = frame:GetName()

	if WTweaks.DB.profile.Frames == nil or WTweaks.DB.profile.Frames[frameName] == nil then
		return
	end

	frame:ClearAllPoints()
	-- frame:SetSize(select(1, unpack(WTweaks.DB.profile.Frames[frameName].Size)))
	frame:SetPoint(unpack(WTweaks.DB.profile.Frames[frameName].Point))
end

function WTweaks:SaveFrame(frame)
	if WTweaks.DB.profile.Frames == nil then
		WTweaks.DB.profile.Frames = {}
	end

	local frameName = frame:GetName()

	WTweaks.DB.profile.Frames[frameName] = { 
		Size = { frame:GetSize() },
		Point = { frame:GetPoint() }
	}
end

function WTweaks:MakeFrameDraggable(frame, draggerFrame)
	if draggerFrame == nil then
		draggerFrame = frame
	end

	frame:SetMovable(true)

	draggerFrame:EnableMouse(true)
	draggerFrame:RegisterForDrag("LeftButton")

	draggerFrame:HookScript("OnDragStart", function()
		frame:StartMoving()
	end)

	draggerFrame:HookScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		WTweaks:SaveFrame(frame)
	end)
end

function WTweaks:ShowButtonTooltip(frame, title, text)
	GameTooltip:SetOwner(frame)
	GameTooltip_SetTitle(GameTooltip, title)
	GameTooltip_AddNormalLine(GameTooltip, text)
	GameTooltip:Show()
end

function WTweaks:CreateButton(parent, normalTexture, pushTexture, hoverTexture, width, height, title, text)
	local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")

	if normalTexture ~= nil then
		btn:SetNormalTexture(normalTexture)
	end

	btn:SetPushedTexture(pushTexture and pushTexture or normalTexture)
	btn:SetHighlightTexture(hoverTexture and hoverTexture or "Interface/Buttons/ButtonHilight-Square", "ADD")

	btn:SetSize(width, height)
	
	btn:SetScript("OnEnter", function(self)
		WTweaks:ShowButtonTooltip(self, title, text)
	end)

	btn:SetScript("OnLeave", GameTooltip_Hide)
	return btn
end