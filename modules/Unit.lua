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
                },

                ShowPlayerBossFrame = {
					name = "Player Boss Frame",
					desc = "The player frame will have a boss border.",
					type = "toggle",
					default = false
                }
			}
		}
    }
end 

function Module:Init()
	Module.UnitFrames.Health.IsEnabled = Module.Settings.Unit.Health.IsEnabled
    Module.UnitFrames.Health.Texture = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.Unit.Health.BarTexture)
    Module.UnitFrames.Health.Color = WTweaks:ColorArrayToRGBA(Module.Settings.Unit.Health.BarColor)

    Module.UnitFrames.Power.IsEnabled = Module.Settings.Unit.Power.IsEnabled
    Module.UnitFrames.Power.Texture = WTweaks.Libs.SharedMedia:Fetch("statusbar", Module.Settings.Unit.Power.BarTexture)
    Module.UnitFrames.Power.Color = WTweaks:Ternary(Module.Settings.Unit.Power.UseClassColor, nil, WTweaks:ColorArrayToRGBA(Module.Settings.Unit.Power.BarColor))

    Module.UnitFrames.IsEnabled = Module.UnitFrames.Health.IsEnabled or Module.UnitFrames.Power.IsEnabled
    
    Module.UnitFrames.Font = {
        File = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.Unit.Font),
        Height = Module.Settings.Unit.FontSize,
        Outline = Module.Settings.Unit.ShowFontOutline and "OUTLINE" or "",
    }
    
    -- One time init code...
    if Module.UnitFrames.IsEnabled and not Module.IsInitialized then
        Module.UnitFrames.Health.BlizzardTexture = WTweaks:GetStatusBar(PlayerFrameHealthBar)
        Module.UnitFrames.Power.BlizzardTexture = WTweaks:GetStatusBar(PlayerFrameManaBar)

        do  -- Populate loaded frames.
            local pendingFrames = {
                PlayerFrame,
                TargetFrame,
                TargetFrameToT,
                FocusFrame,
                FocusFrameToT,
                PetFrame
            }

            -- Party frames.
            for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
                tinsert(pendingFrames, memberFrame)
            end

            -- Arena frames.
            for _, unitFrame in ipairs(ArenaEnemyMatchFramesContainer.UnitFrames) do
                tinsert(pendingFrames, unitFrame)
                tinsert(pendingFrames, unitFrame:GetPetFrame())
            end

            -- Normalize all.
            for _, pendingFrame in pairs(pendingFrames) do
                local frame = Module:GetNormalizedFrame(pendingFrame)
                Module.NormalizedFrames[frame.Unit] = frame
            end
        end

        -- Style each frame.
        for _, unitFrame in pairs(Module.NormalizedFrames) do
            -- Hook frames that require updates.
            if unitFrame.Updates then
                if unitFrame.IsPartyFrame then
                    -- We can set a flag once on the frame to reduce updates to ONE update.
                    WTweaks:HookSecure(unitFrame.BFrame, "Show", function(self)
                        unitFrame.IsUpdatePending = true
                    end)
        
                    -- On update, if the flag is set, we have to update the health bar.
                    WTweaks:HookSecure(unitFrame.BFrame, "UpdateMember", function(self)
                        if unitFrame.IsUpdatePending then
                            Module:UpdateStyle(unitFrame)
                            unitFrame.IsUpdatePending = false
                        end
                    end)
                else
                    -- We can set a flag once on the frame to reduce updates to ONE update.
                    WTweaks:HookSecure(unitFrame.BFrame, "Show", function(self)
                        unitFrame.IsUpdatePending = true
                    end)
        
                    -- On update, if the flag is set, we have to update the health bar.
                    WTweaks:HookSecure(unitFrame.BFrame, "Update", function(self)
                        if unitFrame.IsUpdatePending then
                            Module:UpdateStyle(unitFrame)

                            if Module.Settings.Unit.ShowPlayerBossFrame then
                                local isMe = UnitIsUnit(unitFrame.Unit, "player")

                                if isMe and self.TargetFrameContainer and self.TargetFrameContainer.BossPortraitFrameTexture then
                                    self.TargetFrameContainer.BossPortraitFrameTexture:Show()
                                end
                            end

                            
                            unitFrame.IsUpdatePending = false
                        end
                    end)
                end
            end

            if unitFrame.Init then 
                unitFrame.Init()
            end
        end

        -- Certain actions will cause Blizzard to reset the mana bar, so we have to always override it.
        WTweaks:HookSecure(_G, "UnitFrameManaBar_UpdateType", function(self)
            local registeredFrame = Module.NormalizedFrames[self.unit]

            if registeredFrame ~= nil then
                Module:UpdateStyle(registeredFrame)
            else
                print("Encountered unknown frame for unit " .. self.unit)
            end
        end)

        Module.IsInitialized = true
    end

    for _, unitFrame in pairs(Module.NormalizedFrames) do
        unitFrame.IsUpdatePending = true
        Module:ApplyStyle(unitFrame)
    end

    if Module.Settings.Unit.ShowPlayerBossFrame then
        Module:AttachBossPortraitFrame(PlayerFrame.PlayerFrameContainer.PlayerPortrait)
    elseif PlayerFrame.PlayerFrameContainer.BossPortraitFrameTexture ~= nil then
        PlayerFrame.PlayerFrameContainer.BossPortraitFrameTexture:Hide()
    end
end

function Module:ApplyStyle(unitFrame)
    if Module.UnitFrames.Health.IsEnabled then
        local c = Module.UnitFrames.Health.Color
        unitFrame.Bars.Health:SetStatusBarColor(c.r, c.g, c.b, c.a)
        unitFrame.Bars.Health:SetStatusBarTexture(Module.UnitFrames.Health.Texture)
    else
        WTweaks:SetStatusBar(unitFrame.Bars.Health, Module.UnitFrames.Health.BlizzardTexture)
    end

    if Module.UnitFrames.Power.IsEnabled then
        local c = Module.UnitFrames.Power.Color or Module:GetClassColor(unitFrame.Unit)
        unitFrame.Bars.Mana:SetStatusBarColor(c.r, c.g, c.b, c.a)
        unitFrame.Bars.Mana:SetStatusBarTexture(Module.UnitFrames.Power.Texture)
    else
        UnitFrameManaBar_Update(unitFrame.Bars.Mana, unitFrame.Unit)
    end

    for _, text in pairs(unitFrame.Text) do
        text:SetFont(Module.UnitFrames.Font.File, Module.UnitFrames.Font.Height + (unitFrame.FontSizeAdjust or 0), Module.UnitFrames.Font.Outline)
    end
end

function Module:UpdateStyle(unitFrame)
    if Module.UnitFrames.Health.IsEnabled then
        local c = Module.UnitFrames.Health.Color
        unitFrame.Bars.Health:SetStatusBarColor(c.r, c.g, c.b, c.a)
        unitFrame.Bars.Health:SetStatusBarTexture(Module.UnitFrames.Health.Texture)
    end

    if Module.UnitFrames.Power.IsEnabled then
        local c = Module.UnitFrames.Power.Color or Module:GetClassColor(unitFrame.Unit)
        unitFrame.Bars.Mana:SetStatusBarColor(c.r, c.g, c.b, c.a)
        unitFrame.Bars.Mana:SetStatusBarTexture(Module.UnitFrames.Power.Texture)
    end
end

function Module:GetNormalizedFrame(frame)
    local parent = frame:GetParent()
    local frame = Module:GetNormalizedFrameDetails(frame)
    
    if frame.BFrame == PlayerFrame then
        frame.Updates = false
    elseif parent == PartyFrame then
        frame.IsPartyFrame = true
        frame.Updates = true
    elseif parent == ArenaEnemyMatchFramesContainer then
        frame.IsEnemyFrame = true
    else
        frame.Updates = true
    end

    -- Fix Blizzard's text alignment.
    if frame.Text.Level then
        frame.Init = function()
            Module:AdjustText(frame.Text.Level, 0, 1, 0, 12)
        end
    end

    return frame
end

function Module:GetNormalizedFrameDetails(frame)
    local normalized = {
        BFrame = frame,
        Unit = frame.unit,
        Portrait = frame.portrait,
        Text = {
            Name = frame.name,
            Level = frame.level,
            Health = nil,
            Mana = nil,
        },
        Bars = {
            Health = frame.healthbar,
            Mana = frame.manabar
        }
    }

    if frame == PlayerFrame then
        normalized.Text.Level = PlayerLevelText
    else
        normalized.Text.Level = frame.name:GetParent().LevelText
    end

    if frame.healthbar then
        normalized.Text.Health = frame.healthbar.text
    end

    if frame.manabar then
        normalized.Text.Mana = frame.manabar.text
    end

    return normalized
end


function Module:AttachBossPortraitFrame(portraitFrame)
    if portraitFrame:GetParent().BossPortraitFrameTexture then
        portraitFrame:GetParent().BossPortraitFrameTexture:Show()
        return
    end

    local bossPortraitFrame = TargetFrame.TargetFrameContainer.BossPortraitFrameTexture
    local bossPortraitTexture = bossPortraitFrame:GetTexture()
    local bossPortraitAtlas = bossPortraitFrame:GetAtlas()
    
    local parent = portraitFrame:GetParent()

    local texture = parent:CreateTexture(bossPortraitTexture, "ARTWORK", nil, 2)
    texture:SetAtlas(bossPortraitAtlas, TextureKitConstants.UseAtlasSize)
    texture:SetTexCoord(1, 0, 0, 1); -- Flip X
    texture:SetPoint("CENTER", portraitFrame, "CENTER", -6, 0)
    parent.BossPortraitFrameTexture = texture
end

function Module:AdjustText(textFrame, x, y, width, height)
    local point = { textFrame:GetPoint() }
    point[4] = point[4] + x
    point[5] = point[5] + y
    textFrame:SetPoint(unpack(point))

    if width ~= nil then
        textFrame:SetSize(width, height)
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