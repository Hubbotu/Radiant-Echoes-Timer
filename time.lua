local addonName, addonTable = ...

-- Localization table
local L = {
    enUS = {
        TIME_RUIN = "Event in progress",
        TIME_LEFT = "Before changing location",
        NEXT_LOCATION = "Next location",
    },
    ruRU = {
        TIME_RUIN = "Событие идет",
        TIME_LEFT = "До смены локации",
        NEXT_LOCATION = "Сл. локация",
    }
}

-- Function to get localized string
local function GetLocalizedString(key)
    local locale = GetLocale()
    if L[locale] and L[locale][key] then
        return L[locale][key]
    else
        return L["enUS"][key] -- Fallback to English
    end
end

local function UpdateTimer()
    if addonTable.timerEndTime then
        local timeLeft = addonTable.timerEndTime - GetTime()
        if timeLeft > 0 then
            local hoursLeft = math.floor(timeLeft / 3600)
            local minutesLeft = math.floor((timeLeft % 3600) / 60)
            local secondsLeft = math.floor(timeLeft % 60)
            if not addonTable.timerFrame then
                addonTable.timerFrame = CreateFrame("Frame", addonName.."TimerFrame", UIParent, "DialogBoxFrame")
                addonTable.timerFrame:SetSize(225, 120) -- Adjusted size
                addonTable.timerFrame:SetPoint("CENTER")
                addonTable.timerFrame:SetMovable(true)
                addonTable.timerFrame:EnableMouse(true)
                addonTable.timerFrame:RegisterForDrag("LeftButton")
                addonTable.timerFrame:SetScript("OnDragStart", addonTable.timerFrame.StartMoving)
                addonTable.timerFrame:SetScript("OnDragStop", addonTable.timerFrame.StopMovingOrSizing)
                addonTable.timerFrame:SetScript("OnHide", function(self)
                    self.UserHidden = true
                end)
                addonTable.timerFrame:SetBackdrop({
                    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
                    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                    edgeSize = 16,
                    insets = { left = 8, right = 6, top = 8, bottom = 8 },
                })
                addonTable.timerFrame:SetBackdropBorderColor(1, 1, 1)
                
                addonTable.timerFrame.textZone = addonTable.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                addonTable.timerFrame.textZone:SetPoint("TOP", addonTable.timerFrame, "TOP", 0, -20)
                
                addonTable.timerFrame.textTimer = addonTable.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                addonTable.timerFrame.textTimer:SetPoint("TOP", addonTable.timerFrame.textZone, "BOTTOM", 0, -5) -- Reduced vertical spacing

                addonTable.timerFrame.nextLocationText = addonTable.timerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                addonTable.timerFrame.nextLocationText:SetPoint("TOP", addonTable.timerFrame.textTimer, "BOTTOM", 0, -5) -- Reduced vertical spacing
                
                addonTable.timerFrame.deleteButton = CreateFrame("Button", nil, addonTable.timerFrame, "UIPanelCloseButton")
                addonTable.timerFrame.deleteButton:SetPoint("TOPRIGHT", addonTable.timerFrame, "TOPRIGHT")
                addonTable.timerFrame.deleteButton:SetScript("OnClick", function()
                    addonTable.timerFrame:Hide()
                end)
            end
            
            addonTable.timerFrame.textZone:SetText(addonTable.currentZone)
            if addonTable.spawning then
                addonTable.timerFrame.textTimer:SetText(string.format("%s: %02d:%02d:%02d", GetLocalizedString("TIME_RUIN"), hoursLeft, minutesLeft, secondsLeft))
                addonTable.timerFrame.textTimer:SetTextColor(0, 1, 0) -- Light green color for "TIME_RUIN"
                addonTable.timerFrame.textZone:SetTextColor(0, 1, 0) -- Light green color for "TIME_RUIN"
            else
                addonTable.timerFrame.textTimer:SetText(string.format("%s: %02d:%02d:%02d", GetLocalizedString("TIME_LEFT"), hoursLeft, minutesLeft, secondsLeft))
                addonTable.timerFrame.nextLocationText:SetText(string.format("%s: %s", GetLocalizedString("NEXT_LOCATION"), addonTable.nextZone))
                addonTable.timerFrame.textTimer:SetTextColor(1, 1, 1) -- Default color for "TIME_LEFT"
                addonTable.timerFrame.textZone:SetTextColor(1, 1, 1) -- Default color for "TIME_LEFT"
            end
        else
            if addonTable.timerFrame then
                addonTable.timerFrame:Hide()
            end
        end
    end
end

local function UpdateLocation()
    local zone_rotation = {
        115, -- Dragonblight
        1254, -- Searing Gorge
        1315, -- Dustwallow Marsh
    }

    local region_timers = {
        NA = 1722432600, -- NA
        US = 1722432600, -- US
        KR = 1722409200, -- KR
        EU = 1722409200, -- EU
        TW = nil, -- TW (Add TW timestamp if available)
    }

    local region_start_timestamp = region_timers[GetCVar("portal"):upper()]
    if region_start_timestamp then
        local duration = 600 -- Adjusted duration
        local interval = 5400 -- Adjusted interval
        local start_timestamp = GetServerTime() - region_start_timestamp
        local next_event = interval - start_timestamp % interval
        local spawning = interval - next_event < duration
        local remaining = duration - (interval - next_event)

        local offset = not spawning and interval or 0
        local rotation_index = math.floor(start_timestamp / interval % #zone_rotation)
        local currentLocationID = zone_rotation[rotation_index + 1] -- Ensure the index starts from 1
        local nextLocationID = zone_rotation[(rotation_index + 1) % #zone_rotation + 1] -- Next location index
        addonTable.currentZone = C_Map.GetMapInfo(currentLocationID).name
        addonTable.nextZone = C_Map.GetMapInfo(nextLocationID).name

        addonTable.spawning = spawning
        if spawning then
            if addonTable.timerFrame and not addonTable.timerFrame.UserHidden then
                addonTable.timerFrame:Show()
            end
            addonTable.timerEndTime = GetTime() + remaining
        else
            addonTable.timerEndTime = GetTime() + next_event
        end
    end
end

local function InitializeAddon()
    addonTable.states = {}
    addonTable.currentZone = ""
    addonTable.nextZone = ""
    addonTable.timerEndTime = nil
    addonTable.spawning = false

    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:SetScript("OnEvent", function(_, event, ...) 
        if event == "PLAYER_ENTERING_WORLD" then
            UpdateLocation() -- Update location on entering world
        end
    end)

    frame:SetScript("OnUpdate", function() 
        UpdateTimer() -- Update timer continuously
        UpdateLocation() -- Update location continuously
    end)
end

InitializeAddon()

SLASH_ZAM4TIMER1 = "/zt"
SlashCmdList.ZAM4TIMER = function(msg)
    if addonTable.timerFrame then
        addonTable.timerFrame.UserHidden = nil
        addonTable.timerFrame:Show()
    end
end
