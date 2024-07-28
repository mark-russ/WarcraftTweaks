local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("Developer")
local C = DeveloperConsole

function Module:OnModuleRegistered(main)
	main:RegisterChatCommand("find", Module.OnFindCommandInvoked)
	main:RegisterChatCommand("templates", Module.ListFrames)

	main:RegisterChatCommand("interface", function()
        interfaceVersion = select(4, GetBuildInfo())
        print("Interface: " .. interfaceVersion)
    end)
end

function WTweaks:PrintTable(table, targetFrame, depth)
    if targetFrame == nil then
        targetFrame = ChatFrame1
    end

	local depth = (depth or -5) + 5 
	local indentation = string.rep(" ", depth)
	for elementName, element in pairs(table) do
		local elementType = type(element)

		if elementType == "table" then
			targetFrame:AddMessage(indentation .. elementName .. " {")
			WTweaks:PrintTable(element, targetFrame, depth)
			targetFrame:AddMessage(indentation .. "}")
		else
            if (elementType == "string") then
                elementValue = "\"" .. tostring(element) .. "\""
            else
                elementValue = tostring(element)
            end
            
			targetFrame:AddMessage(indentation .. elementName .. " = " .. elementValue)
		end
	end
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