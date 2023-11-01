local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Developer")
local C = DeveloperConsole

function Module:OnModuleRegistered()
    --print((select(4, GetBuildInfo())))
end

function Module:OnInitialize(main)
	main:RegisterChatCommand("find", Module.OnFindCommandInvoked)
	main:RegisterChatCommand("templates", Module.ListFrames)
end

Module.ListFrames = function(searchType)
    C:Clear()
    C:AddMessage("==============================[Search results]==============================")
    for k, v in pairs(C_XMLUtil:GetTemplates()) do
        if searchType == "" or v.type == searchType then
            C:AddMessage(v.name .. " | " .. v.type)
        end
    end
    C:Show()
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