local WTweaks

local Module = {
    Name = "Units",
    Settings = nil,
    Frames = {
        Player = {
            Base = "Player",
            Updates = false
        },
        Target = {
            Base = "Target",
            Updates = true
        },
        Focus = {
            Base = "Target",
            Updates = true
        }
    },
    UnitFrames = {
        Health = {},
        Power = {}
    }
}

function Module:GetConfig()
    return {
		unit = {
			type = "group",
			name = "Unit Frames",
			order = 2,
			inline = true,
			args = {
				Font = {
					name = "Font",
                    dialogControl = "LSM30_Font",
					desc = "Changes the font of the player and target frames.",
					type = "select",
					values = function()
						return WTweaks.Options.Fonts
					end
				},
				ShowFontOutline = {
					name = "Font Outline",
					desc = "If checked, adds an outline to player and target frames.",
					type = "toggle",
					default = false
				},


                IsHealthStyled = {
					name = "Customize Health Bars",
					desc = "If checked, health bars will be styled",
					type = "toggle",
					default = false
                },
				HealthBarTexture = {
					name = "Health Bar",
                    dialogControl = "LSM30_Statusbar",
					desc = "Sets the texture of healthbars",
					type = "select",
					values = function()
						return WTweaks.Options.Bars
					end,
					default = nil
				},
                HealthBarColor = {
					name = "Health Color",
					desc = "Sets the color of the health bar.",
					type = "color",
                    hasAlpha = true,
					default = { 0.0, 0.8, 0.0, 0.8 }
                },


                IsPowerStyled = {
					name = "Customize Power Bars",
					desc = "If checked, power bars will be styled",
					type = "toggle",
					default = false
                },
				PowerBarTexture = {
					name = "Power Bar",
                    dialogControl = "LSM30_Statusbar",
					desc = "Sets the texture of the power bar.",
					type = "select",
					values = function()
						return WTweaks.Options.Bars
					end,
					default = nil
				},
                UsePowerClassColor = {
					name = "Use Class Power",
					desc = "If checked, power bars will use the class colors instead of custom color.",
					type = "toggle",
					default = true
                },
                PowerBarColor = {
					name = "Power Color",
					desc = "Sets the color of the power bar.",
					type = "color",
                    hasAlpha = true,
					default = { 0.0, 0.0, 0.8, 0.8 }
                },


                StatusBarTexture = {
					name = "Status Bar Texture",
                    dialogControl = "LSM30_Statusbar",
					desc = "Sets the texture of the XP/Reputation Bar.",
					type = "select",
					values = function()
						return WTweaks.Options.Bars
					end,
					default = nil
                },
			}
		}
    }
end 
--/run StatusTrackingBarManager.BottomBarFrameTexture:Show()
table.insert(WTweaksModules, Module)

function Module:OnSettingChanged(settings, groupName)
    Module:Init()
end

function Module:OnModuleRegistered(main)
    WTweaks = main

    Module:Init()
end

function Module:Init()
	for _, bar in ipairs(StatusTrackingBarManager.bars) do
        local z = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.HealthBarTexture)
        --local tName = "Interface\\TargetingFrame\\UI-StatusBar"

        local statusBar = bar.StatusBar
        --local sbT = statusBar:GetStatusBarTexture()
        --local abT = statusBar:GetStatusBarTexture():GetAtlas()

        --local atlas = statusBar:GetStatusBarTexture(tName):GetAtlas()
        --/run StatusTrackingBarManager.bars[1].StatusBar.BarTexture
        statusBar.BarTexture:SetTexture(z)
        --statusBar:SetStatusBarTexture(tName)
        --statusBar:GetStatusBarTexture(tName):SetMask()
	end

	local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.Font)
    local fontHeight = 10
    local fontOutline = Module.Settings.ShowFontOutline and "OUTLINE" or ""

	Module.UnitFrames.Health.Enabled = Module.Settings.IsHealthStyled
    Module.UnitFrames.Health.Texture = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.HealthBarTexture)
    Module.UnitFrames.Health.Color = WTweaks:ColorArrayToRGBA(Module.Settings.HealthBarColor)

    if Module.UnitFrames.Health.BlizzardTexture == nil then
        Module.UnitFrames.Health.BlizzardTexture = WTweaks:GetStatusBar(PlayerFrameHealthBar)
    end

    Module.UnitFrames.Power.Enabled = Module.Settings.IsPowerStyled
    Module.UnitFrames.Power.Texture = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.PowerBarTexture)
    Module.UnitFrames.Power.Color = WTweaks:Ternary(Module.Settings.UsePowerClassColor, nil, WTweaks:ColorArrayToRGBA(Module.Settings.PowerBarColor))

    if Module.UnitFrames.Power.BlizzardTexture == nil then
        Module.UnitFrames.Power.BlizzardTexture = WTweaks:GetStatusBar(PlayerFrameManaBar)
    end

    Module:NormalizePlayerFrame()

    for frameName, frameInfo in pairs(Module.Frames) do
        frameName = frameName.."Frame"
        frameBase = frameInfo.Base .. "Frame"
        local mainFrame = _G[frameName]
        local contentFrame = mainFrame[frameBase.."Content"][frameBase.."ContentMain"]
        Module:StyleMainUnitFrame(contentFrame, fontFile, fontHeight, fontOutline)

        if frameInfo.Updates then
            WTweaks:HookSecure(mainFrame, "Update", function(self)
                -- No need to override texture if texture isn't gonna be seen.
                if not self:IsShown() or not Module.UnitFrames.Health.Enabled then
                    return
                end
        
                local healthBar = contentFrame.HealthBar
                healthBar:SetStatusBarTexture(Module.UnitFrames.Health.Texture)

                local c = Module.UnitFrames.Health.Color
                healthBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
            end)
        end
    end

    -- The mana bar has a mind of its own, so we need to override the texture.
    WTweaks:HookSecure(_G, "UnitFrameManaBar_UpdateType", function(manaBar)
        if not Module.UnitFrames.Power.Enabled then
            return
        end

        manaBar:SetStatusBarTexture(Module.UnitFrames.Power.Texture)

        if Module.UnitFrames.Power.Color ~= nil then
            local c = Module.UnitFrames.Power.Color
            manaBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
        else
            local c = Module:GetClassColor(manaBar.unit)
            manaBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
        end
    end)
end

function Module:NormalizePlayerFrame()
    -- Modifies the player frame to make it programmatically seem more like a target & focus frame to reduce boilerplate
    local pFrame = PlayerFrame.PlayerFrameContent.PlayerFrameContentMain
    pFrame.Name = PlayerName
    pFrame.LevelText = PlayerLevelText

    pFrame.HealthBar = PlayerFrameHealthBar
    pFrame.HealthBar.HealthBarText = PlayerFrameHealthBarText
    
    pFrame.ManaBar = PlayerFrameManaBar
    pFrame.ManaBar.ManaBarText = PlayerFrameManaBarText
end

function Module:StyleMainUnitFrame(frame, fontFile, fontHeight, fontOutline)
    frame.Name:SetFont(fontFile, fontHeight, fontOutline)
    frame.LevelText:SetFont(fontFile, fontHeight, fontOutline)
    frame.HealthBar.HealthBarText:SetFont(fontFile, fontHeight, fontOutline)
    frame.ManaBar.ManaBarText:SetFont(fontFile, fontHeight, fontOutline)

    if Module.UnitFrames.Health.Enabled then
        frame.HealthBar:SetStatusBarTexture(Module.UnitFrames.Health.Texture)

        local c = Module.UnitFrames.Health.Color
        frame.HealthBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
    else
        WTweaks:SetStatusBar(frame.HealthBar, Module.UnitFrames.Health.BlizzardTexture)
    end
    
    if Module.UnitFrames.Power.Enabled then
        frame.ManaBar:SetStatusBarTexture(Module.UnitFrames.Power.Texture)

        if Module.UnitFrames.Power.Color ~= nil then
            local c = Module.UnitFrames.Power.Color
            frame.ManaBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
        else
            local c = Module:GetClassColor(frame.ManaBar.unit)
            frame.ManaBar:SetStatusBarColor(c.r, c.g, c.b, c.a)
        end
    else
        WTweaks:SetStatusBar(frame.ManaBar, Module.UnitFrames.Power.BlizzardTexture)
    end
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