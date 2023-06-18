local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Minimap")
Module.IsMoving = false
Module.CurrentMapID = nil
Minimap.IsLayoutFlipped = MinimapCluster:GetSettingValueBool(Enum.EditModeMinimapSetting.HeaderUnderneath)

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "Minimap", AddonName)

    WTweaks:HookEvent("ADDON_LOADED", function(addonName)
        if addonName == "Blizzard_HybridMinimap" then
            HybridMinimap.CircleMask:Hide()
        end
    end)

    EditModeSystemSettingsDialog:HookScript("OnHide", function()
        if Module.IsMoving then
            EditModeManagerFrame:SaveLayouts()
            MinimapCluster:OnEditModeExit()
            Module.IsMoving = false
        end
        
        Module:ReanchorMinimapContainer()
    end)

	GetMinimapShape = function()
        return "SQUARE"
	end
    
	MinimapCluster:EnableMouse(false)
    MinimapCompassTexture:Hide()

    Minimap:SetClampedToScreen(true)
    Minimap:SetMaskTexture("Interface/BUTTONS/WHITE8X8")
    
    -- Disable the blue objective indications.
    Minimap:SetQuestBlobInsideTexture("Interface/Tooltips/UI-Tooltip-Background")
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetQuestBlobRingAlpha(0)
    Minimap:SetArchBlobInsideTexture("Interface/Tooltips/UI-Tooltip-Background")
    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetArchBlobRingAlpha(0)

    Module:CreateIndicatorTray()
    Module:CreateHeader()
    Module:CreateFooter()

    if Module.Settings.Minimap.Coordinates.CoordinatesVisibility ~= "hidden" then
        Module:CreateCoordinateFrame()
    end
    
    MinimapCluster.Selection:ClearAllPoints()
    MinimapCluster.Selection:SetAllPoints(MinimapCluster, true)
    
    -- Repositioning the header does jank stuff to the layout. Override.
    MinimapCluster.Layout = WTweaks.NoOp
    
    hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", function(self, shouldHeaderBeUnderneath)
        Minimap.IsLayoutFlipped = shouldHeaderBeUnderneath
        Module:UpdateLayout()
        Module:ReanchorMinimapContainer()
    end)

    -- Instead of rescaling entire minimap, buttons and all, which looks ugly... make the minimap actually change size instead.
    MinimapCluster.MinimapContainer.SetScale = function(self, scale)
        local size = 200 * scale
        MinimapCluster.Selection:SetSize(size, size)
        MinimapCluster:SetSize(size, size)
        MinimapCluster.MinimapContainer:SetSize(size, size)
        Minimap:SetSize(size, size)
        Module:RepaintCanvas()
    end
    
    Module:UpdateLayout()
end

function Module:OnStarted()
    -- Calendar
    GameTimeFrame:ClearAllPoints()
    GameTimeFrame:SetFrameStrata("LOW")
    GameTimeFrame:SetFrameLevel(5)
    GameTimeFrame:SetParent(Minimap.HeaderBar)
    GameTimeFrame:SetPoint("RIGHT", Minimap.HeaderBar, "RIGHT", 0, -1)
    
    -- Time
    TimeManagerClockButton:ClearAllPoints()
    TimeManagerClockButton:SetFrameStrata("LOW")
    TimeManagerClockButton:SetFrameLevel(5)
    TimeManagerClockButton:SetParent(Minimap.HeaderBar)
    TimeManagerClockButton:SetPoint("RIGHT", GameTimeFrame, "LEFT", 0, 0)

    -- Expansion Button
    ExpansionLandingPageMinimapButton:Hide()

    QueueStatusButton:SetScale(0.5)
    QueueStatusButton.UpdatePosition = WTweaks.NoOp
    
    Minimap.IndicatorTray:Add(MiniMapCraftingOrderIcon:GetParent(), false, false)
    Minimap.IndicatorTray:Add(MiniMapMailIcon:GetParent(), false, false)
    Minimap.IndicatorTray:Add(QueueStatusButton, true, true)
    
    if Module.Settings.Minimap.UseEmbeddedAddons then
        Module:EmbedAddons()
    end

    Module:ReanchorMinimapContainer()

    Minimap.HeaderBar:SetAlpha(0)
    WTweaks:HookFader(Minimap.HeaderBar, {
        Minimap,
        GameTimeFrame,
        TimeManagerClockButton,
        MinimapCluster.ZoneTextButton
    }, 0.1)

    Minimap.FooterBar:SetAlpha(0)
    WTweaks:HookFader(Minimap.FooterBar, {
        Minimap,
        AddonCompartmentFrame,
        MinimapCluster.IndicatorFrame,
        MinimapCluster.Tracking,
        MinimapCluster.Tracking.Button,
        Minimap.ZoomIn,
        Minimap.ZoomOut
    }, 0.1)
    
    Minimap.ZoomIn:Show()
    Minimap.ZoomIn.Hide = Minimap.ZoomIn.Show

    Minimap.ZoomOut:Show()
    Minimap.ZoomOut.Hide = Minimap.ZoomOut.Show

    MiniMapIndicatorFrame_UpdatePosition()
end

function Module:SyncCoordinates(isMapChanging)
    if Module.Settings.Minimap.Coordinates.CoordinatesVisibility ~= "hidden" then
        Module.CurrentMapID = C_Map.GetBestMapForUnit("PLAYER")
    
        if isMapChanging then
            Minimap.CoordinateFrame:SetTextColor(MinimapZoneText:GetTextColor())
        end
    
        if Module.CurrentMapID ~= nil then
            local position = C_Map.GetPlayerMapPosition(Module.CurrentMapID, "PLAYER")
        
            if position ~= nil then
                local x = math.ceil(position.x * 10000) / 100
                local y = math.ceil(position.y * 10000) / 100
                Minimap.CoordinateFrame:SetText(x .. ", " .. y)
                Minimap.CoordinateFrame:Show()
            else
                Minimap.CoordinateFrame:Hide()
            end
        end
    end
end

function Module:OnSettingChanged(settings, groupName)
	if groupName == "IsEnabled" then
        ReloadUI()
	end

    if groupName == "UseEmbeddedAddons" then
        if Module.Settings.Minimap.UseEmbeddedAddons then
            Module:EmbedAddons()
        else
            ReloadUI()
        end
    end
end

function Module:UpdateLayout()
    Minimap.HeaderBar:ClearAllPoints()
    Minimap.FooterBar:ClearAllPoints()

    if Minimap.CoordinateFrame ~= nil then
        Minimap.CoordinateFrame:ClearAllPoints()
    end

    if Minimap.IsLayoutFlipped then
        Minimap.HeaderBar:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
        Minimap.HeaderBar:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
        
        Minimap.FooterBar:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
        Minimap.FooterBar:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
        
        if Minimap.CoordinateFrame ~= nil then
            Minimap.CoordinateFrame:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
            Minimap.CoordinateFrame:SetPoint("RIGHT", Minimap, "RIGHT", 0, 0)
        end
    else
        Minimap.HeaderBar:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
        Minimap.HeaderBar:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)

        Minimap.FooterBar:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
        Minimap.FooterBar:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
            
        if Minimap.CoordinateFrame ~= nil then
            Minimap.CoordinateFrame:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
            Minimap.CoordinateFrame:SetPoint("RIGHT", Minimap, "RIGHT", 0, 0)
        end
    end
    
    if Module.Settings.Minimap.Coordinates.CoordinatesVisibility == "always" then
        Minimap.CoordinateFrame:SetParent(Minimap)
    elseif Module.Settings.Minimap.Coordinates.CoordinatesVisibility == "auto" then
        Minimap.CoordinateFrame:SetParent(Minimap.FooterBar)
    end
end

function Module:CreateCoordinateFrame()
    local CoordinateFrame = Minimap:CreateFontString(nil, "BACKGROUND") 
    Minimap.CoordinateFrame = CoordinateFrame
    CoordinateFrame:ClearAllPoints()
    CoordinateFrame:SetParent(Minimap)
    CoordinateFrame:SetHeight(20)
    Module:UpdateCoordinateFrameFont()
    
    -- We'll match the color of the minimap text, always.
    hooksecurefunc(MinimapZoneText, "SetTextColor", function(self, r, g, b, a)
        CoordinateFrame:SetTextColor(r, g, b, a)
    end)

    WTweaks:Repeat(0.5, function()
        Module:SyncCoordinates(false)
    end)
    
    Module:SyncCoordinates(true)
end

function Module:UpdateCoordinateFrameFont()
    local fontFile = WTweaks.Libs.SharedMedia:Fetch("font", Module.Settings.Minimap.Coordinates.FontFile)
    local fontSize = Module.Settings.Minimap.Coordinates.FontSize
    local fontFlags = Module.Settings.Minimap.Coordinates.ShowFontOutline and "OUTLINE" or nil
    Minimap.CoordinateFrame:SetFont(fontFile, fontSize, fontFlags)
end

function Module:CreateIndicatorTray()
    local MinimapIndicatorTray = CreateFrame("FRAME", "MinimapIndicatorTray", Minimap)
    Minimap.IndicatorTray = MinimapIndicatorTray
    MinimapIndicatorTray.Margin = 8
    MinimapIndicatorTray.UseAutoWidth = true
    MinimapIndicatorTray:SetPoint("TOP", Minimap, "TOP", -3, 3)
    MinimapIndicatorTray:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMLEFT", -3, 3)

    MinimapIndicatorTray.Add = function(self, newChild, shouldUpdateOnShow, shouldUpdateOnHide)
        newChild:ClearAllPoints()
        newChild:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
        newChild:SetParent(self)
        
        if shouldUpdateOnShow then
            hooksecurefunc(newChild, "Show", function()
                MinimapIndicatorTray:Layout()
            end)
        end
        
        if shouldUpdateOnHide then
            hooksecurefunc(newChild, "Hide", function()
                MinimapIndicatorTray:Layout()
            end)
        end
    end

    MinimapIndicatorTray.Layout = function(self)
        local prevChild = nil
        local widest = 0

        for _, child in ipairs({ self:GetChildren() }) do 
            if child:IsShown() and (child ~= MinimapCluster.IndicatorFrame or MiniMapMailIcon:GetParent():IsShown() or MiniMapCraftingOrderIcon:GetParent():IsShown()) then
                child:ClearPoint("BOTTOM")

                if prevChild == nil then
                    child:SetPoint("BOTTOM", self, "BOTTOM", 0, 0)
                else
                    child:SetPoint("BOTTOM", prevChild, "TOP", 0, self.Margin)
                end
            
                if self.UseAutoWidth == true then
                    local width = child:GetWidth() * child:GetEffectiveScale()
                    
                    if width > widest then
                        widest = width
                    end
                end
                
                prevChild = child
            end
        end

        if self.UseAutoWidth == true then
            self:SetWidth(widest)
        end
    end
end

function Module:CreateHeader()
    local Bar = CreateFrame("FRAME", "MinimapHeaderBar", Minimap)
    Bar.Backdrop = Bar:CreateTexture(nil, "BACKGROUND")
    Bar.Backdrop:SetAllPoints(Bar)
    Bar.Backdrop:SetColorTexture(0.03, 0.03, 0.03, 0.35)
    Bar:SetHeight(20)
    Minimap.HeaderBar = Bar

    -- Hijack existing border.
    MinimapCluster.BorderTop:Hide()
    MinimapCluster.BorderTop:ClearAllPoints()
    MinimapCluster.BorderTop:SetPoint("TOPLEFT", MinimapCluster, "TOPLEFT", 0, 0)
    MinimapCluster.BorderTop:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", 0, 0)
    MinimapCluster.BorderTop:SetFrameStrata("LOW")
    MinimapCluster.BorderTop:SetFrameLevel(4)
    
    MinimapCluster.ZoneTextButton:ClearAllPoints()
    MinimapCluster.ZoneTextButton:SetFrameStrata("LOW")
    MinimapCluster.ZoneTextButton:SetFrameLevel(5)
    MinimapCluster.ZoneTextButton:SetParent(Bar)
    MinimapCluster.ZoneTextButton:SetPoint("LEFT", Bar, "LEFT", 1, 0)
end

function Module:CreateFooter()
    local Bar = CreateFrame("FRAME", "MinimapFooterBar", Minimap)
    Bar.Backdrop = Bar:CreateTexture(nil, "BACKGROUND")
    Bar.Backdrop:SetAllPoints(Bar)
    Bar.Backdrop:SetColorTexture(0.03, 0.03, 0.03, 0.35)
    Bar:SetHeight(20)
    Minimap.FooterBar = Bar
    
    -- Addon Button
    AddonCompartmentFrame:ClearAllPoints()
    AddonCompartmentFrame:SetParent(Bar)
    AddonCompartmentFrame:SetPoint("LEFT", Bar, "LEFT", 0, 0)

    MinimapCluster.Tracking:ClearAllPoints()
    MinimapCluster.Tracking.Background:Hide()
    MinimapCluster.Tracking:SetParent(Bar)
    MinimapCluster.Tracking:SetPoint("LEFT", AddonCompartmentFrame, "RIGHT", 5, 0)

    Minimap.ZoomIn:ClearAllPoints()
    Minimap.ZoomIn:SetParent(Bar)
    Minimap.ZoomIn:SetPoint("RIGHT", Bar, "RIGHT", 0, -1)

    Minimap.ZoomOut:ClearAllPoints()
    Minimap.ZoomOut:SetParent(Bar)
    Minimap.ZoomOut:SetPoint("RIGHT", Minimap.ZoomIn, "LEFT", -5, 0)
end

-- Finds the corner of the screen that the minimap is close to and anchors the minimap to its direction.
function Module:ReanchorMinimapContainer()
    local screenCenterX, screenCenterY = UIParent:GetCenter()
    local minimapCenterX, minimapCenterY = MinimapCluster:GetCenter()
    local center = { X = screenCenterX - minimapCenterX, Y = screenCenterY - minimapCenterY }
    local margin = { X = 0, Y = 0 }

    local anchor = nil
    if center.Y > 0 then
        anchor = "BOTTOM"
        margin.Y = -2
    else
        anchor = "TOP"
        margin.Y = 2
    end

    if center.X < 0 then
        anchor = anchor .. "RIGHT"
        margin.X = 2
    else
        anchor = anchor .. "LEFT"
        margin.X = -2
    end
    
    MinimapCluster.MinimapContainer:ClearAllPoints()
    MinimapCluster.MinimapContainer:SetPoint(anchor, MinimapCluster, anchor, margin.X, margin.Y)
    MiniMapIndicatorFrame_UpdatePosition()
end

function Module:EmbedAddons()
    local children = { Minimap:GetChildren() }
    for _, child in ipairs(children) do 
        local childName = child:GetName()

        if childName ~= nil and child:IsShown() and string.find(childName, "LibDBIcon10_") == 1 then
            local fallbackName = gsub(childName, "LibDBIcon10_", "")
    
            AddonCompartmentFrame:RegisterAddon({
                text = child.text or fallbackName,
                icon = child.dataObject.icon,
                notCheckable = true,
                func = function()
                    child.dataObject:OnClick("LeftButton")
                end
            })
            
            child:Hide()
        end
    end
end

function Module:RepaintCanvas()
    local originalZoom = Minimap:GetZoom()
    Minimap:SetZoom(originalZoom > 0 and 0 or 1)
    Minimap:SetZoom(originalZoom)
end

function Module:GetConfig()
    local config = {
		Minimap = {
			name = "Minimap",
			type = "group",
			order = 0,
			inline = true,
			args = {
                IsEnabled = {
                    name = "Enable Module",
                    desc = "If checked, various elements will become adjustable for the minimap.",
                    type = "toggle",
                    default = false,
					order = 0,
					width = "full"
                },
                ToggleMover = {
                    name = "Toggle Editor",
                    desc = "This will toggle the EditMode window. Changes will be saved on close.",
                    type = "execute",
					order = 1,
                    func = function()
                        Module.IsMoving = true
                        MinimapCluster:SelectSystem()
                    end
                },
                ScaleSpacer = {
                    name = "",
                    width = 2,
                    type = "description",
                    order = 2
                },
                UseEmbeddedAddons = {
                    name = "Embed Addons",
                    desc = "Will attempt to embed all minimap buttons into the addon compartment.",
                    type = "toggle",
                    default = true,
					order = 3
                },
				Coordinates = {
					name = "Coordinate Block",
					type = "group",
					order = 4,
                    inline = true,
                    args = {
                        CoordinatesVisibility = {
                            name = "Coordinates",
                            desc = "If auto, it will appear if mouse is over the area.",
                            type = "select",
                            values = {
                                hidden = "Disabled",
                                auto = "Auto",
                                always = "Always Shown"
                            },
                            default = "auto",
                            set = function(a, visibility)
                                if visibility ~= "hidden" then
                                    if Minimap.CoordinateFrame == nil then
                                        Module:CreateCoordinateFrame()
                                    end

                                    Module:UpdateLayout()
                                    Module:SyncCoordinates(true)
                                else
                                    Minimap.CoordinateFrame:Hide()
                                end
                            end
                        }
                    }
				}
			}
		}
    }

    -- Spacer to make the tracker scale slider on its own line. 
    local fontOptions = WTweaks:CreateFontOptions(11, 8, 20)

    -- Bump font options to bottom and hook their setters.
    for k, v in pairs(fontOptions) do
        fontOptions[k].set = Module.UpdateCoordinateFrameFont
        fontOptions[k].order = fontOptions[k].order + 5
    end
    
    WTweaks:Merge(fontOptions, config.Minimap.args.Coordinates.args)

    return config
end