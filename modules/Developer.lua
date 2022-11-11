local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Developer")
local C = DeveloperConsole

function Module:OnModuleRegistered()
    
end

function Module:OnInitialize(main)
	main:RegisterChatCommand("find", Module.OnFindCommandInvoked)
end


Module.OnFindCommandInvoked = function(...)
    local params = { ... }
    tremove(params, table.getn(params))
    local searchQuery = table.concat(params, " ")
    
    C:Clear()
    C:AddMessage("==============================[Search results]==============================")
    for k, v in pairs(_G) do
        if k:find(searchQuery) ~= nil then
            C:AddMessage(k)
        end
    end
    C:Show()
end