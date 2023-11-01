local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("ToolTip")

function Module:OnModuleRegistered()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(toolTip, toolTipData)
        if toolTip == GameTooltip then
            local itemId = select(3, toolTip:GetItem())

            if itemId ~= nil then
                local expansionId = select(15, GetItemInfo(itemId)) + 1
                local expansionName = EJ_GetTierInfo(expansionId)
                toolTip:AddLine(expansionName, 1, 1, 1)
            end
        end
    end)
end