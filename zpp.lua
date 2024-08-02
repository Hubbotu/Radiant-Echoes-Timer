-- Addon Initialization
local addonName, addonTable = ...

-- Configuration
addonTable.config = {
    QUEST = true,  -- Enable quest tracking
    LANGUAGE = "AUTO",  -- Default to AUTO
    SHOW_CURRENCY = true,
    ALARM_ENABLE = true,
    WEEK_INTERVAL = 1,  -- Auto detect interval
    OFFSET = 0,  -- Default offset
}

addonTable.currencies = {
    [0] = {
        id = 3089,
        name = "Residual Memories",
    }
}

-- Localized strings for quest status
local questDone = "Quest Done" -- default to English
local questNotDone = "Quest Not Done" -- default to English

-- Function to get the localized map names and quest status messages
local function getLocalizedMapNames(language)
    local map_id_list = { [0] = 70, [1] = 115, [2] = 32 }
    local names = {}

    if language == "AUTO" then
        for i, mapID in pairs(map_id_list) do
            names[i] = C_Map.GetMapInfo(mapID).name
        end
    elseif language == "English" then
        names = { [0] = "Dustwallow Marsh", [1] = "Dragonblight", [2] = "Searing Gorge" }
    elseif language == "Korean" then
        names = { [0] = "먼지진흙 습지대", [1] = "용의 안식처", [2] = "이글거리는 협곡" }
        questDone = "퀘스트 완료" -- Korean for Quest Done
        questNotDone = "퀘스트 미완료" -- Korean for Quest Not Done
    elseif language == "French" then
        names = { [0] = "Marécage d'Âprefange", [1] = "Désolation des dragons", [2] = "Gorge des vents brûlants" }
        questDone = "Quête Terminée" -- French for Quest Done
        questNotDone = "Quête Non Terminée" -- French for Quest Not Done
    elseif language == "German" then
        names = { [0] = "Düstermarschen", [1] = "Drachenöde", [2] = "Sengende Schlucht" }
        questDone = "Quest Abgeschlossen" -- German for Quest Done
        questNotDone = "Quest Nicht Abgeschlossen" -- German for Quest Not Done
    elseif language == "Spanish" then
        names = { [0] = "Marjal Revolcafango", [1] = "Cementerio de dragones", [2] = "La Garganta de Fuego" }
        questDone = "Misión Completa" -- Spanish for Quest Done
        questNotDone = "Misión No Completa" -- Spanish for Quest Not Done
    elseif language == "Chinese" then
        names = { [0] = "尘泥沼泽", [1] = "龙骨荒野", [2] = "灼热峡谷" }
        questDone = "任务完成" -- Chinese for Quest Done
        questNotDone = "任务未完成" -- Chinese for Quest Not Done
    else
        names = { [0] = "Dustwallow Marsh", [1] = "Dragonblight", [2] = "Searing Gorge" }
    end

    return names
end

-- Function to get the next word in different languages
local function getNextWord(language)
    if language == "Korean" then return "다음"
    elseif language == "German" then return "Nächste"
    elseif language == "Spanish" then return "Siguiente"
    elseif language == "Chinese" then return "下一张地图"
    else return "Next" end
end

-- Function to create the display frame
local function createDisplayFrame()
    local frame = CreateFrame("Frame", "AddonDisplayFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(300, 130)
    frame:SetPoint("CENTER")
    frame.title = frame:CreateFontString(nil, "OVERLAY")
    frame.title:SetFontObject("GameFontHighlightLarge")
    frame.title:SetPoint("CENTER", frame.TitleBg, "CENTER", 0, 0)
    frame.title:SetText(addonName)

    frame.content = CreateFrame("Frame", nil, frame)
    frame.content:SetSize(280, 160)
    frame.content:SetPoint("TOP", frame, "TOP", 0, -40)

    frame.text = frame.content:CreateFontString(nil, "OVERLAY")
    frame.text:SetFontObject("GameFontHighlight")
    frame.text:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 10, -10)
    frame.text:SetWidth(260)
    frame.text:SetJustifyH("LEFT")
    frame.text:SetJustifyV("TOP")

    -- Add drag functionality
    local isDragging = false
    local dragStartX, dragStartY

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            isDragging = true
            dragStartX, dragStartY = self:GetCenter()
            self:StartMoving()
        end
    end)
    frame:SetScript("OnMouseUp", function(self)
        if isDragging then
            isDragging = false
            self:StopMovingOrSizing()
        end
    end)

    -- Initially hide the frame
    frame:Hide()

    return frame
end

local displayFrame = createDisplayFrame()

-- Function to update the display frame text
local function updateDisplayFrame()
    local config = addonTable.config
    local region_index = GetCurrentRegion()
    local region_timers = { [1] = 1722281440, [2] = 1722472240, [3] = 1722574800, [4] = 1722488400, [5] = 1722488400 }
    local region_start_timestamp = region_timers[region_index]
    local region_start_delay = config.OFFSET
    local language = config.LANGUAGE
    local interval = (config.WEEK_INTERVAL == 2 and 3600) or (config.WEEK_INTERVAL == 3 and 3600) or (config.WEEK_INTERVAL == 4 and 1800) or 3600
    local localizedMapNames = getLocalizedMapNames(language)
    local wordNext = getNextWord(language)

    local locationText = ""
    local currencyText = ""

    if region_start_timestamp then
        local start_timestamp = GetServerTime() - region_start_timestamp + region_start_delay
        local interval_delay_ingame = 0
        interval = interval + interval_delay_ingame
        local duration = 0
        local next_event = interval - (start_timestamp % interval)
        local spawning = (interval - next_event) < duration
        local remaining = duration - (interval - next_event)
        local offset = not spawning and interval or 0
        local rotation_index = math.floor((start_timestamp + offset) / interval) % 3
        local zone = localizedMapNames[rotation_index]
        local questID = ({82676, 82689, 78938})[rotation_index + 1]

        local state = {
            changed = true,
            show = true,
            progressType = "timed",
            autoHide = true,
            duration = spawning and duration or interval - duration,
            expirationTime = GetTime() + (spawning and remaining or next_event),
            spawning = spawning,
            name = wordNext .. ": " .. zone,
            isQuestDone = C_QuestLog.IsQuestFlaggedCompleted(questID),
            soundAlarm = config.ALARM_ENABLE
        }

        locationText = state.name .. "\n" .. (state.isQuestDone and questDone or questNotDone)
    end

    -- Update currency information
    local config = addonTable.config
    local IS_ENABLE = config.SHOW_CURRENCY
    local residual_memories = addonTable.currencies[0]
    local currency_info = C_CurrencyInfo.GetCurrencyInfo(residual_memories.id)
    
    if IS_ENABLE and currency_info and (currency_info.quantity >= 0) then
        currencyText = "Currency: " .. currency_info.name .. ", Quantity: " .. currency_info.quantity
    else
        currencyText = "Currency: " .. (currency_info and currency_info.name or residual_memories.name) .. ", Quantity: " .. (currency_info and currency_info.quantity or 0)
    end

    -- Update the display frame with both location and currency information
    displayFrame.text:SetText(locationText .. "\n" .. currencyText)
end

-- Main Event Handler
local function eventHandler(self, event, ...)
    if event ~= "PLAYER_ENTERING_WORLD" and event ~= "ZONE_CHANGED_NEW_AREA" and event ~= "CURRENCY_DISPLAY_UPDATE" then
        return false
    end

    -- Update the display frame text
    updateDisplayFrame()

    return true
end

-- Currency Display Event Handler
local function currencyEventHandler(self, event, ...)
    -- Update the display frame text
    updateDisplayFrame()
    return true
end

-- Slash Command Handler
SLASH_ZD1 = "/zd"
SlashCmdList["ZD"] = function(msg)
    if displayFrame:IsShown() then
        displayFrame:Hide()
    else
        displayFrame:Show()
    end
end

-- Initialize frame and register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:SetScript("OnEvent", eventHandler)

-- Currency tracking frame
local currencyFrame = CreateFrame("Frame")
currencyFrame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
currencyFrame:SetScript("OnEvent", currencyEventHandler)

-- Trigger initial event scan
C_Timer.After(0, function() eventHandler(frame, "PLAYER_ENTERING_WORLD") end)
