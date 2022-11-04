local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Unit Frames")

function Module:OnModuleRegistered()
    Module.UnitFrames = {
        Health = {},
        Power = {}
    }

    Module.NormalizedFrames = {}
    Module.IsInitialized = false

	WTweaks:AddOptionPage(Module.Name, "Unit", AddonName)
    Module:Init()
end

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:GetConfig()
    return {
		Unit = {
			type = "group",
			name = "Unit Frames",
			order = 2,
			inline = true,
			args = {
				Font = {
					name = "Font",
                    dialogControl = "LSM30_Font",
					desc = "Affects player, target and focus frames.",
					type = "select",
					values = function()
						return WTweaks.Options.Fonts
					end
				},
				ShowFontOutline = {
					name = "Font Outline",
					desc = "Affects player, target and focus frames.",
					type = "toggle",
					default = false
				},
				FontSize = {
					name = "Font Size",
					desc = "Affects player, target and focus frames.",
					order = 3,
					type = "range",
					default = 10,
					step = 1,
					min = 6,
					max = 14
				},

                Health = {
                    type = "group",
                    name = "Health",
                    order = 2,
                    inline = true,
                    args = {
                        IsEnabled = {
                            name = "Customize Health Bars",
                            desc = "If checked, health bars will be styled",
                            type = "toggle",
                            default = false
                        },
                        BarTexture = {
                            name = "Health Bar",
                            dialogControl = "LSM30_Statusbar",
                            desc = "Sets the texture of healthbars",
                            type = "select",
                            values = function()
                                return WTweaks.Options.Bars
                            end,
                            default = nil,
                            disabled = function()
                                return not Module.Settings.Unit.Health.IsEnabled
                            end
                        },
                        BarColor = {
                            name = "Health Color",
                            desc = "Sets the color of the health bar.",
                            type = "color",
                            hasAlpha = true,
                            default = { 0.0, 0.8, 0.0, 0.8 },
                            disabled = function()
                                return not Module.Settings.Unit.Health.IsEnabled
                            end
                        }
                    }
                },


                Power = {
                    type = "group",
                    name = "Power",
                    order = 2,
                    inline = true,
                    args = {
                        IsEnabled = {
                            name = "Customize Power Bars",
                            desc = "If checked, power bars will be styled",
                            type = "toggle",
                            default = false
                        },
                        BarTexture = {
                            name = "Power Bar",
                            dialogControl = "LSM30_Statusbar",
                            desc = "Sets the texture of the power bar.",
                            type = "select",
                            values = function()
                                return WTweaks.Options.Bars
                            end,
                            default = nil,
                            disabled = function()
                                return not Module.Settings.Unit.Power.IsEnabled
                            end
                        },
                        UseClassColor = {
                            name = "Use Class Power",
                            desc = "If checked, power bars will use the class colors instead of custom color.",
                            type = "toggle",
                            default = true,
                            disabled = function()
                                return not Module.Settings.Unit.Power.IsEnabled
                            end
                        },
                        BarColor = {
                            name = "Power Color",
                            desc = "Sets the color of the power bar.",
                            type = "color",
                            hasAlpha = true,
                            default = { 0.0, 0.0, 0.8, 0.8 },
                            disabled = function()
                                return not Module.Settings.Unit.Power.IsEnabled or not Module.Settings.Unit.Power.UseClassColor
                            end
                        }
                    }
                }
			}
		}
    }
end 

function Module:Init()
	Module.UnitFrames.Health.Enabled = Module.Settings.Unit.Health.IsEnabled
    Module.UnitFrames.Health.Texture = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.Unit.Health.BarTexture)
    Module.UnitFrames.Health.Color = WTweaks:ColorArrayToRGBA(Module.Settings.Unit.Health.BarColor)

    if Module.UnitFrames.Health.BlizzardTexture == nil then
        Module.UnitFrames.Health.BlizzardTexture = WTweaks:GetStatusBar(PlayerFrameHealthBar)
    end

    Module.UnitFrames.Power.Enabled = Module.Settings.Unit.Power.IsEnabled
    Module.UnitFrames.Power.Texture = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.Unit.Power.BarTexture)
    Module.UnitFrames.Power.Color = WTweaks:Ternary(Module.Settings.Unit.Power.UseClassColor, nil, WTweaks:ColorArrayToRGBA(Module.Settings.Unit.Power.BarColor))

    if Module.UnitFrames.Power.BlizzardTexture == nil then
        Module.UnitFrames.Power.BlizzardTexture = WTweaks:GetStatusBar(PlayerFrameManaBar)
    end

    if not Module.IsInitialized then
        do  -- Populate loaded frames.
            local pendingFrames = {
                PlayerFrame,
                TargetFrame,
                FocusFrame,
                TargetFrameToT
            }

            for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                tinsert(pendingFrames, memberFrame)
            end

            for _, pendingFrame in pairs(pendingFrames) do
                local frame = Module:GetNormalizedFrame(pendingFrame)
                Module.NormalizedFrames[frame.Unit] = frame
            end
        end

        -- Style each frame.
        for _, unitFrame in pairs(Module.NormalizedFrames) do
            Module:ApplyStyle(unitFrame)

            -- Hook frames that require updates.
            if unitFrame.Updates then
                if unitFrame.IsPartyFrame then
                    -- We can set a flag once on the frame to reduce updates to ONE update.
                    WTweaks:HookSecure(unitFrame.BlizzFrame, "Show", function(self)
                        unitFrame.IsUpdatePending = true
                    end)
        
                    -- On update, if the flag is set, we have to update the health bar.
                    WTweaks:HookSecure(unitFrame.BlizzFrame, "UpdateMember", function(self)
                        if unitFrame.IsUpdatePending then
                            Module:ApplyStyle(unitFrame)
                            unitFrame.IsUpdatePending = false
                        end
                    end)
                else
                    -- We can set a flag once on the frame to reduce updates to ONE update.
                    WTweaks:HookSecure(unitFrame.BlizzFrame, "Show", function(self)
                        unitFrame.IsUpdatePending = true
                    end)
        
                    -- On update, if the flag is set, we have to update the health bar.
                    WTweaks:HookSecure(unitFrame.BlizzFrame, "Update", function(self)
                        if unitFrame.IsUpdatePending then
                            Module:ApplyStyle(unitFrame)
                            unitFrame.IsUpdatePending = false
                        end
                    end)
                end
            end
  
            -- Fix Blizzard's text alignment.
            if unitFrame.Text.Level then
                local point = { unitFrame.Text.Level:GetPoint() }
                point[5] = point[5] + 1
                unitFrame.Text.Level:SetPoint(unpack(point))
                unitFrame.Text.Level:SetSize(0, 12)
            end
        end

        -- Certain actions will cause Blizzard to reset the mana bar, so we have to always override it.
        WTweaks:HookSecure(_G, "UnitFrameManaBar_UpdateType", function(self)
            local registeredFrame = Module.NormalizedFrames[self.unit]

            if registeredFrame ~= nil then
                Module:ApplyStyle(registeredFrame)
            end
        end)
    else
        for _, unitFrame in pairs(Module.NormalizedFrames) do
            Module:ApplyStyle(unitFrame)
        end
    end

    Module.IsInitialized = true
end

-- TargetFrame.TargetFrameContainer.BossPortraitFrame

function Module:ApplyStyle(unitFrame)
	local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.Unit.Font)
    local fontHeight = Module.Settings.Unit.FontSize
    local fontOutline = Module.Settings.Unit.ShowFontOutline and "OUTLINE" or ""

    unitFrame.Bars.Health:SetStatusBarTexture(Module.UnitFrames.Health.Texture)
    unitFrame.Bars.Mana:SetStatusBarTexture(Module.UnitFrames.Power.Texture)

    local c = Module.UnitFrames.Health.Color
    unitFrame.Bars.Health:SetStatusBarColor(c.r, c.g, c.b, c.a)

    c = Module.UnitFrames.Power.Color or Module:GetClassColor(unitFrame.Unit)
    unitFrame.Bars.Mana:SetStatusBarColor(c.r, c.g, c.b, c.a)

    for _, text in pairs(unitFrame.Text) do
        text:SetFont(fontFile, fontHeight, fontOutline)
    end
end

function Module:GetNormalizedFrame(frame)
    if frame == PlayerFrame then
        return Module:GetNormalizedPlayerFrame(frame)
    elseif frame == TargetFrame or frame == FocusFrame then
        return Module:GetNormalizedTargetFrame(frame)
    elseif frame == TargetFrameToT then
        return Module:GetNormalizedTargetOfTargetFrame(frame)
    elseif frame:GetParent() == PartyFrame then
        return Module:GetNormalizedPartyMemberFrame(frame)
    elseif frame == PetFrame then
        print("unknown frame of type: " .. frame.unit)
    else
        print("unknown frame of type: " .. frame.unit)
    end

    return nil
end

function Module:GetNormalizedPlayerFrame(frame)
    return {
        Unit = frame.unit,
        Text = {
            Name = PlayerName,
            Level = PlayerLevelText,
            Health = PlayerFrameHealthBarText,
            Mana = PlayerFrameManaBarText
        },
        Bars = {
            Health = PlayerFrameHealthBar,
            Mana = PlayerFrameManaBar
        },
        BlizzFrame = frame
    }
end

function Module:GetNormalizedTargetFrame(frame)
    local content = frame.TargetFrameContent.TargetFrameContentMain
    return {
        Unit = frame.unit,
        Text = {
            Name = content.Name,
            Level = content.LevelText,
            Health = content.HealthBar.TextString,
            Mana = content.ManaBar.TextString
        },
        Bars = {
            Health = content.HealthBar,
            Mana = content.ManaBar
        },
        BlizzFrame = frame,
        Updates = true
    }
end

function Module:GetNormalizedTargetOfTargetFrame(frame)
    return {
        Unit = frame.unit,
        Text = {
            Name = frame.Name,
            Level = nil,
            Health = nil,
            Mana = nil
        },
        Bars = {
            Health = frame.HealthBar,
            Mana = frame.ManaBar
        },
        BlizzFrame = frame,
        Updates = true
    }
end

function Module:GetNormalizedPartyMemberFrame(frame)
    return {
        Unit = frame.unit,
        Text = {
            Name = frame.Name,
            Level = nil, -- Party members have no level text.
            Health = frame.HealthBar.TextString,
            Mana = frame.ManaBar.TextString
        },
        Bars = {
            Health = frame.HealthBar,
            Mana = frame.ManaBar
        },
        BlizzFrame = frame,
        IsPartyFrame = true,
        Updates = true
    }
end

function Module:GetClassColor(unit)
    local powerType, powerToken, altR, altG, altB = UnitPowerType(unit)
    local info = PowerBarColor[powerToken]

    if info then
        return info
    elseif altR then
        return { r = altR, g = altG, b = altB }
    else
        return PowerBarColor[powerType] or PowerBarColor["MANA"]
    end
end

function Module:OnPowerTypeChanged(blizzFrame) 

end