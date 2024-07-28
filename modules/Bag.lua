local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("Bags")

function Module:GetConfig()
    return {
        Bags = {
            type = "group",
            name = "Bags",
            order = 5,
            inline = true,
            args = {
                AutoRepair = {
                    name = "Auto Repair",
					width = 1,
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
				IsAutoVendorJunkEnabled = {
                    name = "Automatically Vendor Junk",
					width = "full",
                    desc = "When visiting a merchant, the \"Vendor Junk\" button will be automatically activated.",
                    order = 2,
                    type = "toggle",
                    default = false
				},
				IsInstantLootEnabled = {
                    name = "Instant Loot",
					width = "full",
                    desc = "Loot will be gathered instantly. This will only work if autoloot is enabled.",
                    order = 3,
                    type = "toggle",
                    default = false
				}
            }
        }
    }
end

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "Bags", AddonName)

	WTweaks:HookEvent("LOOT_OPENED", function(isAutoLoot)
		if isAutoLoot and Module.Settings.Bags.IsInstantLootEnabled then
			LootFrame:Hide()
		end
	end)
    
    WTweaks:HookSecure(MerchantFrame, "Show", Module.OnMerchantOpened)
end

function Module:OnMerchantOpened()
	if Module.Settings.Bags.IsAutoVendorJunkEnabled then
		Module:VendorJunk()
	end

	if Module.Settings.Bags.AutoRepair ~= "disabled" then
		Module:RepairGear()
	end
end

function Module:VendorJunk()
	MerchantSellAllJunkButton:Click()
end

function Module:RepairGear()
	local repairAllCost, canRepair = GetRepairAllCost()
    local autorepairMode = Module.Settings.Bags.AutoRepair

	if repairAllCost > 0 and canRepair then
		if CanGuildBankRepair() and autorepairMode == "guild" then
			RepairAllItems(1)
		elseif autorepairMode == "personal" and repairAllCost <= GetMoney() then
			RepairAllItems()
		end

        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00Gear repaired: |r" .. GetMoneyString(repairAllCost))
	end
end
