local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Typography")
local T = nil -- Abbreviation for Module.Settings.Typography

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "Typography", AddonName)
	Module:Init()
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:OnProfileChanged()
    Module:Init()
end

function Module:Init()
	if not Module.Settings.Typography.IsEnabled then
		-- If module is being unloaded then reload the UI.
		if Module.IsLoaded then
			ReloadUI()
		end

		return
	end

	Module.IsLoaded = true

	T = Module.Settings.Typography
	local configMapping = {
		{
			From = T.General,
			TargetMap = {
				-- Character screen font, titles, tabs, reputation, action bars.
				Title = { GameFontNormal },
				Body = { GameFontNormalSmall },
				BodySecondary = { GameFontHighlightSmall }
			}
		},
		{
			From = T.Minimap,
			TargetMap = {
				Name = { MinimapZoneText },
				Time = { WhiteNormalNumberFont }
			}
		},
		{
			From = T.Dialogue,
			TargetMap = {
				-- Dialog frame/people speaking.
				Title = { QuestFont_Huge },
				Regular = { QuestFont }
			}
		},
		{
			From = T.Tooltip,
			TargetMap = {
				Header = { GameTooltipHeaderText },
				Normal = { GameTooltipText },
				Small = { GameTooltipTextSmall }
			}
		},
		{
			From = T.Zone,
			TargetMap = {
				Main = { ZoneTextFont },
				Subzone = { SubZoneTextFont, PVPInfoTextFont },
			}
		}
	}
	
	for _, group in ipairs(configMapping) do
		for configName, targets in pairs(group.TargetMap) do
			local c = group.From[configName] -- "From" is a table reference to a specific table in Module.Settings.
			
			local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", c.FontFile)
			local fontOutline = c.ShowFontOutline and "OUTLINE" or ""

			for _, frame in ipairs(targets) do
				frame:SetFont(fontFile, c.FontSize, fontOutline)
			end
		end

		if group.OnApply then
			group.OnApply()
		end
	end
end

function Module:OnPlayerConnect()
    Module:ApplyChanges()
end

function Module:GetConfig()
    return {
		Typography = {
			name = "Typography",
			type = "group",
			order = 0,
			inline = true,
			args = {
                IsEnabled = {
                    name = "Enable Module",
                    desc = "If checked, various fonts will become adjustable.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full"
                },
				General = {
					name = "General",
					type = "group",
					order = 0,
					args = {
						Title = {
							name = "Title",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						},
						Body = {
							name = "Body",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(10, 8, 20)
						},
						BodySecondary = {
							name = "Body (Secondary)",
							type = "group",
							order = 2,
							inline = true,
							args = WTweaks:CreateFontOptions(10, 8, 20)
						}
					}
				},
				Minimap = {
					name = "Minimap",
					type = "group",
					order = 1,
					args = {
						Name = {
							name = "Zone Name",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						},
						Time = {
							name = "Time",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						}
					}
				},
				Dialogue = {
					name = "Quest Window",
					type = "group",
					order = 1,
					args = {
						Title = {
							name = "Title",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						},
						Regular = {
							name = "Regular",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						}
					}
				},
				Tooltip = {
					name = "Tooltips",
					type = "group",
					order = 1,
					args = {
						Header = {
							name = "Header",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(14, 8, 20)
						},
						Normal = {
							name = "Normal",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(12, 8, 20)
						},
						Small = {
							name = "Small",
							type = "group",
							order = 2,
							inline = true,
							args = WTweaks:CreateFontOptions(11, 8, 20)
						}
					}
				},
				Zone = {
					name = "Zone",
					type = "group",
					order = 1,
					args = {
						Main = {
							name = "Main name",
							type = "group",
							order = 0,
							inline = true,
							args = WTweaks:CreateFontOptions(32, 10, 60, true)
						},
						Subzone = {
							name = "Subzone name",
							type = "group",
							order = 1,
							inline = true,
							args = WTweaks:CreateFontOptions(24, 10, 60, true)
						}
					}
				}
			}
		}
    }
end