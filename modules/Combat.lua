local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Combat")
local PlayerGUID = UnitGUID("player")
local MSG_SPELL_INTERRUPT = "Interrupted %s's %s."

function Module:OnModuleRegistered()
	Module:Init()
	WTweaks:AddOptionPage(Module.Name, "Combat", AddonName)
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:Init()
	WTweaks:HookEvent("COMBAT_LOG_EVENT_UNFILTERED", Module.CombatEvent)
end

-- https://wowpedia.fandom.com/wiki/COMBAT_LOG_EVENT
function Module:CombatEvent()
	local _, eventType, _, sourceGUID, _, _, _, _, destName, _, _, interruptorSpellId, _, _, interruptedSpellId = CombatLogGetCurrentEventInfo()

	if sourceGUID ~= PlayerGUID then
		return
	end
	
	if Module.Settings.Combat.ShouldAnnounceInterrupts == true and eventType == "SPELL_INTERRUPT" then
		Module:AnnounceInterrupt(destName, interruptedSpellId)
	elseif Module.Settings.Combat.ShouldAnnounceInterrupts == true and eventType == "SPELL_DISPEL" then
		Module:AnnounceInterrupt(destName, interruptedSpellId)
	end
end

function Module:AnnounceInterrupt(destName, spellId)
	local chatChannel = Module:GetBestChatChannel()

	if chatChannel ~= nil then
		local chatMsg = MSG_SPELL_INTERRUPT:format(destName, GetSpellLink(spellId))
		SendChatMessage(chatMsg, chatChannel)
	end
end

function Module:GetBestChatChannel()
	return IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or IsInRaid() and "RAID" or IsInGroup() and "PARTY" or nil
end

function Module:GetConfig()
    return {
		Combat = {
			name = "Combat",
			type = "group",
			order = 2,
			inline = true,
			args = {
                ShouldAnnounceInterrupts = {
                    name = "Announce Interrupts",
                    desc = "If checked, interrupts will be announced to raid/party chat.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full"
                }
			}
		}
    }
end