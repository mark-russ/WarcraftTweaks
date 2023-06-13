local AddonName, WTweaks = ...

local Module = WTweaks:RegisterModule("Minimap")
Module.IsMoving = false
Module.IsInitialized = false

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "Minimap", AddonName)
    Module:Init()
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

function Module:OnProfileChanged()
    Module:Init()
end

function Module:Init()
    if not Module.Settings.Minimap.IsEnabled or Module.IsInitialized then
        return
    end

    EditModeSystemSettingsDialog:HookScript("OnHide", function()
        if Module.IsMoving then
            EditModeManagerFrame:SaveLayouts()
            MinimapCluster:OnEditModeExit()
            Module.IsMoving = false
        end
        
        Module:ReanchorMinimapContainer()
    end)

    WTweaks:HookEvent("PLAYER_ENTERING_WORLD", Module.OnPlayerConnect)

	GetMinimapShape = function()
        return "SQUARE"
	end

	MinimapCluster:EnableMouse(false)
    MinimapCompassTexture:Hide()

    Minimap:SetMaskTexture("Interface/BUTTONS/WHITE8X8")
    
    -- Disable the blue objective indications.
    Minimap:SetQuestBlobInsideTexture("Interface/Tooltips/UI-Tooltip-Background")
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetQuestBlobRingAlpha(0)
    
    Minimap:SetArchBlobInsideTexture("Interface/Tooltips/UI-Tooltip-Background")
    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetArchBlobRingAlpha(0)
    --Minimap:SetMaskTexture(167013)

    GameTimeFrame:Hide()
    
    Module:CreateHeader()
    Module:CreateFooter()
    
    MinimapCluster.Tracking:Hide()
    Minimap:SetClampedToScreen(true)

    MinimapCluster.Selection:ClearAllPoints()
    MinimapCluster.Selection:SetAllPoints(MinimapCluster, true)
    
    -- Repositioning the header does jank stuff to the layout. Override.
    MinimapCluster.Layout = WTweaks.NoOp
    
    MinimapCluster.SetHeaderUnderneath = function(self, shouldHeaderBeUnderneath)
        MinimapCluster.ShouldBeUnderheath = shouldHeaderBeUnderneath
    end
    
    -- Instead of rescaling entire minimap, buttons and all, which looks ugly...
    -- Let's make the minimap actually change size instead.
    MinimapCluster.MinimapContainer.SetScale = function(self, scale)
        local size = 200 * scale
        MinimapCluster.Selection:SetSize(size, size)
        MinimapCluster:SetSize(size, size)
        MinimapCluster.MinimapContainer:SetSize(size, size)
        Minimap:SetSize(size, size)
    end
    
    Module.IsInitialized = true
end

function Module:CreateHeader()
    -- Hijack existing border.
    MinimapCluster.BorderTop:Hide()
    MinimapCluster.BorderTop:ClearAllPoints()
    MinimapCluster.BorderTop:SetPoint("TOPLEFT", MinimapCluster, "TOPLEFT", 0, 0)
    MinimapCluster.BorderTop:SetPoint("TOPRIGHT", MinimapCluster, "TOPRIGHT", 0, 0)
    MinimapCluster.BorderTop:SetFrameStrata("LOW")
    MinimapCluster.BorderTop:SetFrameLevel(4)
    
    local HeaderBar = CreateFrame("FRAME", "MinimapHeaderBar", Minimap)
    Minimap.HeaderBar = HeaderBar
    HeaderBar:ClearAllPoints()
    HeaderBar:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    HeaderBar:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0)
    HeaderBar:SetHeight(20)
    HeaderBar:SetFrameStrata("LOW")
    HeaderBar:SetFrameLevel(4)

    --local HeaderBarBackdrop = HeaderBar:CreateTexture(nil, "BACKGROUND")
    --HeaderBarBackdrop:SetAllPoints(HeaderBar)
    --HeaderBarBackdrop:SetColorTexture(0.03, 0.03, 0.03, 0.35)

    MinimapCluster.ZoneTextButton:ClearAllPoints()
    MinimapCluster.ZoneTextButton:SetFrameStrata("LOW")
    MinimapCluster.ZoneTextButton:SetFrameLevel(5)
    MinimapCluster.ZoneTextButton:SetPoint("LEFT", Minimap.HeaderBar, "LEFT", 1, 0)
end

function Module:CreateFooter()
    local Bar = CreateFrame("FRAME", "MinimapFooterBar", Minimap)
    Minimap.FooterBar = Bar
    Bar:ClearAllPoints()
    Bar:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0)
    Bar:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0)
    Bar:SetHeight(20)
    Bar:SetFrameStrata("LOW")
    Bar:SetFrameLevel(4)

    --local Backdrop = Bar:CreateTexture(nil, "BACKGROUND")
    --Backdrop:SetAllPoints(Bar)
    --Backdrop:SetColorTexture(0.03, 0.03, 0.03, 0.5)
    
    -- Addon Button UPDATE_PENDING_MAIL
    AddonCompartmentFrame:ClearAllPoints()
    AddonCompartmentFrame:SetPoint("LEFT", Bar, "LEFT", 0, 0)
    AddonCompartmentFrame:SetFrameStrata("LOW")
    AddonCompartmentFrame:SetFrameLevel(5)

    Minimap:HookScript("OnEnter", function()
        AddonCompartmentFrame:Show()
    end)
    
    Minimap:HookScript("OnLeave", function()
        AddonCompartmentFrame:Hide()
    end)
    
    -- AddonCompartmentFrame should stay visible
    AddonCompartmentFrame:HookScript("OnEnter", AddonCompartmentFrame.Show)
    AddonCompartmentFrame:HookScript("OnLeave", AddonCompartmentFrame.Hide)

    -- Mail Button
    MinimapCluster.IndicatorFrame:ClearAllPoints()
    MinimapCluster.IndicatorFrame:SetParent(Bar)
    MinimapCluster.IndicatorFrame:SetPoint("CENTER", Bar, "CENTER", 0, 0)

    Minimap.ZoomIn:ClearAllPoints()
    Minimap.ZoomIn:SetPoint("RIGHT", Bar, "RIGHT", 0, -1)

    Minimap.ZoomOut:ClearAllPoints()
    Minimap.ZoomOut:SetPoint("RIGHT", Bar, "RIGHT", -25, -1)
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
end

function Module:OnPlayerConnect()
    ExpansionLandingPageMinimapButton:Hide()
    
    if Module.Settings.Minimap.UseEmbeddedAddons then
        Module:EmbedAddons()
    end
    
    Module:ReanchorMinimapContainer()

    TimeManagerClockButton:ClearAllPoints()
    TimeManagerClockButton:SetPoint("RIGHT", Minimap.HeaderBar, "RIGHT", 0, 0)
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
                        MinimapCluster.Selection:ShowSelected()
                        EditModeSystemSettingsDialog:AttachToSystemFrame(MinimapCluster)
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
                }
			}
		}
    }
    --,
    --            -- Spacer to make the tracker scale slider on its own line.
    --           
    --           
	--			
    --           
	--			
    --           
    --local fontOptions = WTweaks:CreateFontOptions(12, 8, 20)
--
    ---- Bump font options to bottom.
    --for k, v in pairs(fontOptions) do
    --    fontOptions[k].order = fontOptions[k].order + 100
    --end
--
    --WTweaks:Merge(fontOptions, config.Minimap.args)

    return config
end