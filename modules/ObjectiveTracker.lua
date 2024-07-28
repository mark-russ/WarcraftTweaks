local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Objective Tracker")

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "ObjectiveTracker", AddonName)
	Module:Init()
end

function Module:Init()
    Module:UpdateScale();
end

function Module:UpdateScale()
    ObjectiveTrackerFrame:SetScale(Module.Settings.ObjectiveTracker.Scale);
end

function Module:GetConfig()
    return {
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
					max = 2.0,
                    set = Module.UpdateScale
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
end