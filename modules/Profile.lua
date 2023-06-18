local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Profile")

function Module:OnModuleRegistered()
	WTweaks.Configuration.args.profile = WTweaks.Libs.AceDBOptions:GetOptionsTable(WTweaks.DB)
	WTweaks:AddOptionPage(Module.Name, "profile", AddonName)

    WTweaks.DB.RegisterCallback(Module, "OnProfileChanged", ReloadUI)
    WTweaks.DB.RegisterCallback(Module, "OnProfileCopied",  ReloadUI) 
    WTweaks.DB.RegisterCallback(Module, "OnProfileReset",   ReloadUI)
end