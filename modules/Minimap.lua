local AddonName, WTweaks = ...
local Module = WTweaks:RegisterModule("Minimap");
local FadeSpeed = 0.1;
Minimap.IsLayoutFlipped = MinimapCluster:GetSettingValueBool(Enum.EditModeMinimapSetting.HeaderUnderneath);

function Module:OnModuleRegistered()
	WTweaks:AddOptionPage(Module.Name, "Minimap", AddonName);
    Module:SetMinimapSquare();
    Module:CreateHeader();
    Module:CreateFooter();

    hooksecurefunc(MinimapCluster, "SetHeaderUnderneath", function(self, shouldHeaderBeUnderneath)
        Minimap.IsLayoutFlipped = shouldHeaderBeUnderneath;
        Module:ReanchorMinimapContainer();
        Module:UpdateLayout();
    end);

    EventRegistry:RegisterCallback("ExpansionLandingPage.OverlayChanged", function()
        Module:UpdateExpansionButton();
    end)

    WTweaks:HookEvent("PLAYER_ENTERING_WORLD", function()
        WTweaks:DelayedCall(0.1, function()
            Module:InitFaders();
            Module:EmbedAddons();
        end);
    end);
    
    WTweaks:HookEvent("ADDON_LOADED", function(addonName)
        if addonName == "Blizzard_HybridMinimap" then
            HybridMinimap.CircleMask:Hide();
        elseif addonName == "Blizzard_TimeManager" then
            -- Time addon loads late. So it has to be added to the footer later.
            TimeManagerClockButton:ClearAllPoints();
            TimeManagerClockButton:SetFrameStrata("LOW");
            TimeManagerClockButton:SetFrameLevel(5);
            TimeManagerClockButton:SetParent(Minimap.Footer);
            TimeManagerClockButton:SetPoint("RIGHT", GameTimeFrame, "LEFT", 0, 0);
        end
    end);
end

function Module:SetMinimapSquare()
    Minimap:SetClampedToScreen(true);
    Minimap:SetMaskTexture("Interface/BUTTONS/WHITE8X8");
    MinimapCompassTexture:Hide();
	GetMinimapShape = function() return "SQUARE" end; -- Set square.
    
    -- Instead of rescaling entire minimap, buttons and all, which looks ugly... make the minimap actually change size instead.
    MinimapCluster.MinimapContainer.SetScale = function(self, scale)
        local size = 200 * scale;
        MinimapCluster.Selection:SetSize(size, size);
        MinimapCluster:SetSize(size, size);
        MinimapCluster.MinimapContainer:SetSize(size, size);
        Minimap:SetSize(size, size);

        -- Force repaint the canvas.
        local originalZoom = Minimap:GetZoom();
        Minimap:SetZoom(originalZoom > 0 and 0 or 1);
        Minimap:SetZoom(originalZoom);
    end
end

function Module:EmbedAddons()
    if Module.Settings.Minimap.UseEmbeddedAddons then
        local children = { Minimap:GetChildren() }
        for _, child in ipairs(children) do 
            local childName = child:GetName();
    
            if childName ~= nil and child:IsShown() and string.find(childName, "LibDBIcon10_") == 1 then
                local name = child.text or gsub(childName, "LibDBIcon10_", "");
                local isAddonAlreadyRegistered = false;

                for _, registeredAddon in ipairs(AddonCompartmentFrame.registeredAddons) do
                    if name == registeredAddon.text then
                        isAddonAlreadyRegistered = true;
                        break;
                    end
                end

                if isAddonAlreadyRegistered ~= true and name ~= "RareScannerMinimapIcon" then
                    AddonCompartmentFrame:RegisterAddon({
                        text = name,
                        icon = child.dataObject.icon,
                        registerForAnyClick = true,
                        notCheckable = true,
                        func = function(data, inputData, menu)
                            child:Click(inputData.buttonName)
                        end
                    });
                end

                child:Hide();
            end
        end
    end
end

function Module:UpdateLayout()
    Minimap.Header:ClearAllPoints();
    Minimap.Footer:ClearAllPoints();

    if Minimap.IsLayoutFlipped then
        Minimap.Header:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0);
        Minimap.Header:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0);
        Minimap.Footer:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0);
        Minimap.Footer:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0);
    else
        Minimap.Header:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0);
        Minimap.Header:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT", 0, 0);
        Minimap.Footer:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 0, 0);
        Minimap.Footer:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", 0, 0);
    end
end

-- Finds the corner of the screen that the minimap is close to and anchors the minimap to its direction.
function Module:ReanchorMinimapContainer()
    local screenCenterX, screenCenterY = UIParent:GetCenter();
    local minimapCenterX, minimapCenterY = MinimapCluster:GetCenter();
    local center = { X = screenCenterX - minimapCenterX, Y = screenCenterY - minimapCenterY };
    local margin = { X = 0, Y = 0 };

    local anchor = nil
    if center.Y > 0 then
        anchor = "BOTTOM";
        margin.Y = -2;
    else
        anchor = "TOP";
        margin.Y = 2;
    end

    if center.X < 0 then
        anchor = anchor .. "RIGHT";
        margin.X = 2;
    else
        anchor = anchor .. "LEFT";
        margin.X = -2;
    end
    
    MinimapCluster.MinimapContainer:ClearAllPoints();
    MinimapCluster.MinimapContainer:SetPoint(anchor, MinimapCluster, anchor, margin.X, margin.Y);
    MiniMapIndicatorFrame_UpdatePosition();
end

function Module:CreateHeader()
    Minimap.Header = CreateFrame("FRAME", "MinimapHeaderBar", Minimap);
    Minimap.Header.Backdrop = Minimap.Header:CreateTexture(nil, "BACKGROUND");
    Minimap.Header.Backdrop:SetAllPoints(Minimap.Header);
    Minimap.Header.Backdrop:SetColorTexture(0.03, 0.03, 0.03, 0.35);
    Minimap.Header:SetHeight(20);
    
    -- Addon Button
    AddonCompartmentFrame:ClearAllPoints();
    AddonCompartmentFrame:SetParent(Minimap.Header);
    AddonCompartmentFrame:SetPoint("LEFT", Minimap.Header, "LEFT", 0, 0);

    MinimapTrackingFrame = MinimapCluster.Tracking;
    MinimapTrackingFrame:ClearAllPoints();
    MinimapTrackingFrame.Background:Hide();
    MinimapTrackingFrame:SetParent(Minimap.Header);
    MinimapTrackingFrame:SetPoint("LEFT", AddonCompartmentFrame, "RIGHT", 3, 0);

    Minimap.ZoomIn:ClearAllPoints();
    Minimap.ZoomIn:SetParent(Minimap.Header);
    Minimap.ZoomIn:SetPoint("RIGHT", Minimap.Header, "RIGHT", 0, -1);

    Minimap.ZoomOut:ClearAllPoints();
    Minimap.ZoomOut:SetParent(Minimap.Header);
    Minimap.ZoomOut:SetPoint("RIGHT", Minimap.ZoomIn, "LEFT", -5, 0);
    
    -- Zoom buttons always show.
    Minimap.ZoomIn:Show();
    Minimap.ZoomIn.Hide = WTweaks.NoOp; --Minimap.ZoomIn.Show;
    Minimap.ZoomOut:Show();
    Minimap.ZoomOut.Hide = WTweaks.NoOp; --Minimap.ZoomOut.Show;
end

function Module:CreateFooter()
    Minimap.Footer = CreateFrame("FRAME", "MinimapFooterBar", Minimap);
    Minimap.Footer.Backdrop = Minimap.Footer:CreateTexture(nil, "BACKGROUND");
    Minimap.Footer.Backdrop:SetAllPoints(Minimap.Footer);
    Minimap.Footer.Backdrop:SetColorTexture(0.03, 0.03, 0.03, 0.35);
    Minimap.Footer:SetHeight(20);
    

    MinimapCluster.ZoneTextButton:ClearAllPoints();
    MinimapCluster.ZoneTextButton:SetFrameStrata("LOW");
    MinimapCluster.ZoneTextButton:SetFrameLevel(5);
    MinimapCluster.ZoneTextButton:SetParent(Minimap.Footer);
    MinimapCluster.ZoneTextButton:SetPoint("LEFT", Minimap.Footer, "LEFT", 1, 0);

    -- Calendar
    GameTimeFrame:ClearAllPoints();
    GameTimeFrame:SetFrameStrata("LOW");
    GameTimeFrame:SetFrameLevel(5);
    GameTimeFrame:SetParent(Minimap.Footer);
    GameTimeFrame:SetPoint("RIGHT", Minimap.Footer, "RIGHT", 0, -1);
    
    -- Instance Indicator
    MinimapCluster.InstanceDifficulty:ClearAllPoints();
    MinimapCluster.InstanceDifficulty:SetParent(Minimap.Header);

    -- Hide old backdrop
    MinimapCluster.BorderTop:Hide();
end

function Module:UpdateExpansionButton()
    ExpansionLandingPageMinimapButton:ClearAllPoints();
    ExpansionLandingPageMinimapButton:SetParent(Minimap.Header);
    ExpansionLandingPageMinimapButton:SetPoint("LEFT", MinimapTrackingFrame, "RIGHT", 3, 0);
    ExpansionLandingPageMinimapButton:SetScale(0.45);
end

function Module:InitFaders()
    Minimap.Header:SetAlpha(0);
    WTweaks:HookFader(Minimap.Header, Minimap, FadeSpeed);

    Minimap.Footer:SetAlpha(0);
    WTweaks:HookFader(Minimap.Footer, Minimap, FadeSpeed);

    frames = {
        AddonCompartmentFrame,
        AddonCompartmentFrame.DropDown,
        MinimapTrackingFrame.Button,
        MinimapTrackingFrame.DropDown,
        ExpansionLandingPageMinimapButton,
        MinimapCluster.InstanceDifficulty,
        Minimap.ZoomIn,
        Minimap.ZoomOut,
        MinimapCluster.ZoneTextButton,
        GameTimeFrame,
        TimeManagerClockButton
    };

    for _, childFrame in pairs(frames) do
        childFrame:SetPropagateMouseMotion(true);
    end;
end

function Module:GetConfig()
    return {
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
                        Module.IsMoving = true;
                        MinimapCluster:SelectSystem();
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
                    set = Module.EmbedAddons,
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
end