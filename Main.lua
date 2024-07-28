local AddonName, WTweaks = ...
local LibAddon = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceConsole-3.0")
WTweaks.Version = GetAddOnMetadata(AddonName, "Version")

local DBName = AddonName
WTweaks.Frames = {
	Main = CreateFrame("FRAME", AddonName)
}

WTweaks.BlizzFuncs = {}
WTweaks.NativeEvents = {}
WTweaks.Modules = {}

WTweaks_OpenSettings = function()
	Settings.OpenToCategory(AddonName)
end

function LibAddon:OnInitialize()
	WTweaks.Libs = {
		AceGUI = LibStub("AceGUI-3.0"),
		AceDB = LibStub("AceDB-3.0"),
		AceDBOptions = LibStub("AceDBOptions-3.0"),
		AceConfig = LibStub("AceConfig-3.0"),
		AceCfgDialog = LibStub("AceConfigDialog-3.0"),
		SharedMedia = LibStub("LibSharedMedia-3.0")
	}

	WTweaks.Libs.SharedMedia:Register("font", "OS Condensed Bold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_condensed_bold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Condensed Bold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_condensed_bold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Condensed ExtraBold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_condensed_extrabold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Condensed ExtraBold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_condensed_extrabold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Condensed SemiBold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_condensed_semibold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Condensed SemiBold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_condensed_semibold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiCondensed SemiBold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semicondensed_semibold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiCondensed SemiBold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semicondensed_semibold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiCondensed Bold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semicondensed_bold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiCondensed Bold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semicondensed_bold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiCondensed ExtraBold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semicondensed_extrabold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiCondensed ExtraBold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semicondensed_extrabold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS ExtraBold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_extrabold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS ExtraBold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_extrabold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Bold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_bold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS Bold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_bold_italic.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiBold", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semibold.ttf]])
	WTweaks.Libs.SharedMedia:Register("font", "OS SemiBold Italic", [[Interface\AddOns\WarcraftTweaks\media\fonts\opensans_semibold_italic.ttf]])

	WTweaks.Options = {
		Fonts = WTweaks.Libs.SharedMedia:HashTable("font"),
		Bars = WTweaks.Libs.SharedMedia:HashTable("statusbar")
	}

	WTweaks.Configuration = {
		type = "group",
		args = { }
	}
	
	-- Merge configuration groups into one group.
	WTweaks.ModuleConfigMap = {}
	for _, module in pairs(WTweaks.Modules) do
		local moduleConfig = module:GetConfig()

		for groupName, group in pairs(moduleConfig) do
			WTweaks.ModuleConfigMap[group] = module

			if group.parent then
				-- Reparent the group and remove the key to not break AceConfigDialog
				WTweaks.Configuration.args[group.parent].args[groupName] = group
				group.parent = nil
			else
				WTweaks.Configuration.args[groupName] = group
			end
		end
	end

	WTweaks.DefaultConfig = {
		profile = {}
	}

	WTweaks:ExtractDefaultConfig(WTweaks.Configuration, WTweaks.DefaultConfig.profile, nil)
	
	WTweaks.DB = WTweaks.Libs.AceDB:New(DBName, WTweaks.DefaultConfig, true)
	WTweaks.DB:RegisterDefaults(WTweaks.DefaultConfig)
	WTweaks:SetupConfigWatchers(WTweaks.Configuration, WTweaks.DB.profile, nil, nil)
	
	for _, mod in pairs(WTweaks.Modules) do
		mod.Settings = WTweaks.DB.profile
 	end

	WTweaks.Libs.AceConfig:RegisterOptionsTable(AddonName, WTweaks.Configuration, { "settweak" })
	
	-- Notify each module that everything's good.
	for _, mod in ipairs(WTweaks.Modules) do
		mod:OnModuleRegistered(self)
	end
	
	self:RegisterChatCommand("tweaks", WTweaks_OpenSettings)
	
	self:RegisterChatCommand("edit", function()
		EditModeManagerFrame:Show()
	end)
	
	-- As events happen, notify.
	WTweaks.Frames.Main:SetScript("OnEvent", function(self, event, ...)
		for _, callback in pairs(WTweaks.NativeEvents[event]) do
			callback(...)
		end
	end)
end

function WTweaks:RegisterModule(moduleName)
	local module = {
		Name = moduleName,
		Settings = nil,
		OnProfileChanged = function() end,
		GetConfig = function()
			return {}
		end
	}

	tinsert(WTweaks.Modules, module)
	return module
end

function WTweaks:ExtractDefaultConfig(group, defaults, groupName)
	for optionName, option in pairs(group.args) do
		if option.type == "group" then
			defaults[optionName] = {}
			WTweaks:ExtractDefaultConfig(option, defaults[optionName], optionName)
		else
			-- Copy default over and remove it to not break AceConfigDialog
			local defaultValue = option.default
			defaults[optionName] = defaultValue
			option.default = nil
		end
	end
end

function WTweaks:SetupConfigWatchers(group, config, groupName, module)
	-- This is added by the profile manager. Do not watch.
	if groupName == "profile" then
		return
	end

	if groupName ~= nil and module == nil then
		module = WTweaks.ModuleConfigMap[group]
	end

	for optionName, option in pairs(group.args) do
		if option.type == "group" then
			local submodule = WTweaks.ModuleConfigMap[option]
			WTweaks:SetupConfigWatchers(option, config[optionName], optionName, submodule or module)
		else
			-- Colors are a special structure, so we give them a special vararg getter/setter.
			if (option.type == "color") then
				option.set = function(info, ...)
					local name = info[#info]
					config[name] = { ... }
	
					module:OnSettingChanged(config, name)
				end
				
				option.get = function(info)
					local name = info[#info]
					return unpack(config[name])
				end
			else
				local originalSetter = option.set
				option.set = function(info, ...)
					local name = info[#info]
					config[name] = ...

					if module.OnSettingChanged then
						module:OnSettingChanged(config, name)
					end
					
					if originalSetter ~= nil then
						originalSetter(info, config[name])
					end
				end
				
				local originalGetter = option.get
				option.get = function(info)
					local name = info[#info]

					if originalGetter ~= nil then
						return originalGetter(info)
					end

					return config[name]
				end
			end
		end
	end
end

function WTweaks:AddOptionPage(label, path, parent)
	WTweaks.Libs.AceCfgDialog:AddToBlizOptions(AddonName, label, parent, path)
end
