local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Bags")

function Module:OnModuleRegistered()
	WTweaks:HookEvent("LOOT_OPENED", function(isAutoLoot)
		if isAutoLoot and Module.Settings.General.Bags.IsInstantLootEnabled then
			LootFrame:Hide()
		end
	end)

	Module:InitBagTray()
	Module:Init()
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:Init()
	Module:UpdateVendorJunkButtonState()
	Module:UpdateReorganizeBagsButtonState()
end

function Module:GetConfig()
    return {
        Bags = {
			parent = "General",
            type = "group",
            name = "Bags / Vendor",
            order = 5,
            inline = true,
            args = {
                VendorJunk = {
                    name = "Vendor Junk",
                    desc = "Adds a vendor junk button to the bag frame.",
                    order = 0,
                    type = "select",
                    values = {
                        disabled = "Disabled",
                        button = "Button only",
                        autoButton = "Automatic + button",
                        auto = "Automatically"
                    },
                    default = "disabled"
                },
                AutoRepair = {
                    name = "Auto Repair",
                    desc = "If checked, your gear will automatically be repaired.",
                    order = 1,
                    type = "select",
                    values = {
                        disabled = "Disabled",
                        personal = "Repair using your funds",
                        guild = "Repair using guild funds"
                    },
                    default = "disabled"
                },
                ShowReorganizeBagsButton = {
                    name = "Show bag sort button",
                    desc = "If unchecked, the sort button will be hidden.",
                    order = 2,
                    type = "toggle",
                    default = true
                },
				IsInstantLootEnabled = {
                    name = "Instant Loot",
                    desc = "Loot will be gathered instantly. This will only work if autoloot is enabled.",
                    order = 3,
                    type = "toggle",
                    default = false
				}
            }
        }
    }
end

function Module:OnBackpackOpened()
	local bagFrame = WTweaks:GetBagFrame()
	
	Module.BagTray.Margin = isCombined and 8 or 4
	Module.BagTray.Integrations.VendorJunkButton:SetParent(bagFrame)
	Module.BagTray.Integrations.ReorganizeBagsButton:SetParent(bagFrame)
end

function Module:OnMerchantOpened()
	if Module.Settings.General.Bags.VendorJunk == "auto" or Module.Settings.General.Bags.VendorJunk == "autoButton" then
		Module:VendorJunk()
	end

	if Module.Settings.General.Bags.AutoRepair ~= "disabled" then
		Module:RepairGear()
	end
end

function Module:InitBagTray()
	if Module.BagTray ~= nil then
		return
	end

	Module.BagTray = {
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

			for k, frame in pairs(Module.BagTray.Integrations) do
				if frame ~= nil and frame:IsShown() then
					newWidth = newWidth + frame:GetWidth()
					visibleCount = visibleCount + 1
					
					frame:SetPoint("LEFT", previousElement, "RIGHT", Module.BagTray.Margin, 0)
					previousElement = frame
				end
			end

			if visibleCount > 0 then
				newWidth = newWidth + (Module.BagTray.Margin * (visibleCount - 1))
			end

			Module.BagTray.Width = newWidth
			return newWidth
		end
	}
	
	local width, height = BagItemAutoSortButton:GetSize()
	width = width - 6;
	height = height - 6;

	Module.BagTray.Integrations.VendorJunkButton = WTweaks:CreateButton(ContainerFrameCombinedBags, "INTERFACE/Icons/inv_misc_coin_04", nil, nil, width, height, "Vendor Junk", "Clean all junk from your bags.")
	Module.BagTray.Integrations.VendorJunkButton:SetScript("OnClick", Module.VendorJunk)
	
	Module.BagTray.Integrations.ReorganizeBagsButton = WTweaks:CreateButton(ContainerFrameCombinedBags, "INTERFACE/Icons/INV_Pet_Broom", nil, nil, width, height, BAG_CLEANUP_BAGS, BAG_CLEANUP_BAGS_DESCRIPTION)
	Module.BagTray.Integrations.ReorganizeBagsButton:SetScript("OnClick", BagItemAutoSortButton:GetScript("OnClick"))
end

function Module:UpdateReorganizeBagsButtonState()
	WTweaks:HookSecure(BagItemAutoSortButton, "Show", BagItemAutoSortButton.Hide)
	
	if Module.Settings.General.Bags.ShowReorganizeBagsButton then
		Module.BagTray.Integrations.ReorganizeBagsButton:Show()
	else
		Module.BagTray.Integrations.ReorganizeBagsButton:Hide()
	end
end

function Module:UpdateVendorJunkButtonState()
	WTweaks:HookSecure(MerchantFrame, "Show", Module.OnMerchantOpened)

	WTweaks:HookSecure(ContainerFrameCombinedBags, "SetSearchBoxPoint", function()
		Module.BagTray.Margin = 8
		BagItemSearchBox:SetWidth(BagItemSearchBox:GetWidth() - Module.BagTray.GetCalculatedWidth() + 20)
	end)

	WTweaks:HookSecure(ContainerFrame1, "SetSearchBoxPoint", function()
		Module.BagTray.Margin = 4
		BagItemSearchBox:SetWidth(BagItemSearchBox:GetWidth() - Module.BagTray.GetCalculatedWidth() + 26)
	end)

	WTweaks:HookSecure(ContainerFrameCombinedBags, "Show", Module.OnBackpackOpened)
	WTweaks:HookSecure(ContainerFrame1, "Show", Module.OnBackpackOpened)
	
	if Module.Settings.General.Bags.VendorJunk == "disabled" or Module.Settings.General.Bags.VendorJunk == "auto" then
		Module.BagTray.Integrations.VendorJunkButton:Hide()
	else
		Module.BagTray.Integrations.VendorJunkButton:Show()
	end
end

function Module:VendorJunk()
	MerchantSellAllJunkButton:Click()
end

function Module:RepairGear()
	local repairAllCost, canRepair = GetRepairAllCost()
    local autorepairMode = Module.Settings.General.Bags.AutoRepair

	if repairAllCost > 0 and canRepair then
		if CanGuildBankRepair() and autorepairMode == "guild" then
			RepairAllItems(1)
		elseif autorepairMode == "personal" and repairAllCost <= GetMoney() then
			RepairAllItems()
		end

        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Gear repaired: |r" .. GetMoneyString(repairAllCost))
	end
end
