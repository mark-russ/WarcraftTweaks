local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Profile")

function Module:OnModuleRegistered()
	WTweaks.Configuration.args.profile = WTweaks.Libs.AceDBOptions:GetOptionsTable(WTweaks.DB)
	WTweaks:AddOptionPage(Module.Name, "profile", AddonName)

    WTweaks.DB.RegisterCallback(Module, "OnProfileChanged", "RefreshConfig")
    WTweaks.DB.RegisterCallback(Module, "OnProfileCopied",  "RefreshConfig") 
    WTweaks.DB.RegisterCallback(Module, "OnProfileReset",   "RefreshConfig")
end

function Module:RefreshConfig(eventName, newProfile, z)
	WTweaks:SetupConfigWatchers(WTweaks.Configuration, WTweaks.DB.profile, nil, nil)

 	for _, module in pairs(WTweaks.Modules) do
 		local moduleConfig = module:GetConfig()
		module.Settings = WTweaks.DB.profile
        module:OnProfileChanged()
 	end
end