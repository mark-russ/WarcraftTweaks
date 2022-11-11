local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Objective Tracker")

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "ObjectiveTracker", AddonName)
	Module:Init()
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:OnProfileChanged()
    Module:Init()
end

function Module:Init()
	if not Module.Settings.ObjectiveTracker.IsEnabled then
		-- If module is being unloaded then reload the UI.
		if Module.IsLoaded then
			ReloadUI()
		end

		return
	end

    ObjectiveTrackerFrame:SetScale(Module.Settings.ObjectiveTracker.Scale)
    ObjectiveTrackerFrame.isUpdateDirty = true
	Module.IsLoaded = true

	local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.ObjectiveTracker.FontFile)
	local fontOutline = Module.Settings.ObjectiveTracker.ShowFontOutline and "OUTLINE" or ""
    ObjectiveFont:SetFont(fontFile, Module.Settings.ObjectiveTracker.FontSize, fontOutline)
end

function Module:GetConfig()
    local config = {
		ObjectiveTracker = {
			name = "Objective Tracker",
			type = "group",
			order = 0,
			inline = true,
			args = {
                IsEnabled = {
                    name = "Enable Module",
                    desc = "If checked, various elements will become adjustable for the objective tracker.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full"
                },
                Scale = {
					name = "Tracker Scale",
					desc = "This rescales the objective tracker. If you change this, the objective tracker may move. You may need to reposition it.",
					order = 1,
					width = 1,
					type = "range",
					default = 1.0,
					step = 0.05,
					min = 0.1,
					max = 2.0
                },
                -- Spacer to make the tracker scale slider on its own line.
                ScaleSpacer = {
                    name = "",
					width = 2,
                    type = "description",
					order = 2
                }
			}
		}
    }

    local fontOptions = WTweaks:CreateFontOptions(12, 8, 20)

    -- Bump font options to bottom.
    for k, v in pairs(fontOptions) do
        fontOptions[k].order = fontOptions[k].order + 100
    end

    WTweaks:Merge(fontOptions, config.ObjectiveTracker.args)
    return config
end