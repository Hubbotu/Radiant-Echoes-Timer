-- Initialize the addon
local addonName, addonTable = ...

local MyAddon = CreateFrame("Frame")
MyAddon:RegisterEvent("ADDON_LOADED")
MyAddon:RegisterEvent("PLAYER_LOGIN")
MyAddon:RegisterEvent("QUEST_COMPLETE")
MyAddon:RegisterEvent("CURRENCY_DISPLAY_UPDATE")

-- Localization Table
local L = {
    ["enUS"] = {
        ["Residual Memories"] = "Residual Memories",
    },
    ["ruRU"] = {
        ["Residual Memories"] = "Остаточные воспоминания",
    },
    -- Add other languages here if needed
}

-- Function to get localized string
local function GetLocalizedString(key)
    local locale = GetLocale()
    return L[locale] and L[locale][key] or L["enUS"][key] -- Fallback to English
end

-- Event handler function
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            if not MyAddonDB then
                MyAddonDB = {
                    config = {
                        QUEST = true,
                        LANGUAGE = 1,
                        SHOW_CURRENCY = true,
                        WEEK_INTERVAL = 1,
                        ALARM_ENABLE = true,
                        OFFSET = 0,
                    },
                    currencies = {
                        [0] = {
                            id = 3089,
                            name = GetLocalizedString("Residual Memories"),
                        }
                    }
                }
            end
            self:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
        MyAddon:Initialize()
    elseif event == "QUEST_COMPLETE" then
        MyAddon:CreateQuestTracker()
    elseif event == "CURRENCY_DISPLAY_UPDATE" then
        MyAddon:UpdateCurrency()
    end
end

MyAddon:SetScript("OnEvent", OnEvent)

-- Function to initialize the addon
function MyAddon:Initialize()
    self.last = nil
    self:CreateQuestTracker()
    self:UpdateCurrency()
    self:SetupSlashCommands()
end

-- Function to create quest tracker
function MyAddon:CreateQuestTracker()
    if not MyAddonDB.config.QUEST then return end
    
    local language_index = MyAddonDB.config.LANGUAGE

    local quest_id_list = {
        82676, -- Dustwallow Marsh <Broken Masquerade>
        82689, -- Dragonblight <Only Darkness>
        78938, -- Searing Gorge <Champion of the Waterlords>
    }
    local map_id_list = {
        [0] = 70, -- Dustwallow Marsh
        [1] = 115, -- Dragonblight
        [2] = 32, -- Searing Gorge
    }
    
    local language
    if language_index == 1 then
        language = "AUTO"
    elseif language_index == 2 then
        language = "English"
    elseif language_index == 3 then
        language = "Korean"
    elseif language_index == 4 then
        language = "French"
    elseif language_index == 5 then
        language = "German"
    elseif language_index == 6 then
        language = "Spanish"
    elseif language_index == 7 then
        language = "Chinese"
    end
    
    local zone_rotation
    if language == "AUTO" then
        zone_rotation = {
            [0] = C_Map.GetMapInfo(map_id_list[0]).name,
            [1] = C_Map.GetMapInfo(map_id_list[1]).name,
            [2] = C_Map.GetMapInfo(map_id_list[2]).name,
        } 
    elseif language == "English" then
        zone_rotation = {
            [0] = "Dustwallow Marsh",
            [1] = "Dragonblight",
            [2] = "Searing Gorge",
        }
    elseif language == "Korean" then
        zone_rotation = {
            [0] = "먼지진흙 습지대",
            [1] = "용의 안식처",
            [2] = "이글거리는 협곡",
        }
    elseif language == "French" then
        zone_rotation = {
            [0] = "Marécage d'Âprefange",
            [1] = "Désolation des dragons",
            [2] = "Gorge des vents brûlants",
        }
    elseif language == "German" then
        zone_rotation = {
            [0] = "Düstermarschen",
            [1] = "Drachenöde",
            [2] = "Sengende Schlucht",
        }
    elseif language == "Spanish" then
        zone_rotation = {
            [0] = "Marjal Revolcafango",
            [1] = "Cementerio de dragones",
            [2] = "La garganta de fuego",
        }
    elseif language == "Chinese" then
        zone_rotation = {
            [0] = "尘泥沼泽",
            [1] = "灼热峡谷",
            [2] = "龙骨荒野",
        }
    else
        zone_rotation = {
            [0] = "Dustwallow Marsh",
            [1] = "Dragonblight",
            [2] = "Searing Gorge",
        }
    end

    local frame = CreateFrame("Frame", "MyAddonQuestTracker", UIParent)
    frame:SetSize(300, 100)
    frame:SetPoint("CENTER", 0, 0)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    for i, questID in ipairs(quest_id_list) do
        local mapName = zone_rotation[i - 1]
        local isQuestCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
        local iconString
        if isQuestCompleted then
            iconString = "\124Tinterface\\targetingframe\\ui-raidtargetingicon_1.blp:0\124t"
        else
            iconString = "\124Tinterface\\targetingframe\\ui-raidtargetingicon_7.blp:0\124t"
        end
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("TOP", frame, "TOP", 0, -i * 20)
        label:SetText(iconString .. " " .. mapName)
    end
end

-- Function to update currency display
function MyAddon:UpdateCurrency()
    if not MyAddonDB.config.SHOW_CURRENCY then return end

    local frame = _G["MyAddonRadiantEchoes"]
    if not frame then
        frame = CreateFrame("Frame", "MyAddonRadiantEchoes", UIParent)
        frame:SetSize(300, 150)
        frame:SetPoint("CENTER", 0, 0)
        frame:EnableMouse(true)
        frame:SetMovable(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    end

    -- Find or create currency label
    local currencyLabel = frame.currencyLabel
    if not currencyLabel then
        currencyLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        currencyLabel:SetPoint("TOP", frame, "TOP", 0, -30)
        frame.currencyLabel = currencyLabel
    end

    local currency_info = C_CurrencyInfo.GetCurrencyInfo(MyAddonDB.currencies[0].id)
    if currency_info then
        currencyLabel:SetText(MyAddonDB.currencies[0].name .. ": " .. currency_info.quantity)
    else
        currencyLabel:SetText(MyAddonDB.currencies[0].name .. ": 0")
    end
end

-- Function to setup slash commands
function MyAddon:SetupSlashCommands()
    -- Slash command for Residual Memories
    SLASH_ZRM1 = "/zrm"
    SlashCmdList["ZRM"] = function(msg)
        -- Toggle the visibility of the currency frame
        local frame = _G["MyAddonRadiantEchoes"]
        if frame then
            if frame:IsShown() then
                frame:Hide()
                MyAddonDB.config.SHOW_CURRENCY = false
                print("Residual Memories display hidden.")
            else
                frame:Show()
                MyAddonDB.config.SHOW_CURRENCY = true
                MyAddon:UpdateCurrency()
                print("Residual Memories display shown.")
            end
        else
            print("Residual Memories display frame not found.")
        end
    end

    -- Slash command for Quest Tracker
    SLASH_ZQ1 = "/zq"
    SlashCmdList["ZQ"] = function(msg)
        -- Toggle the visibility of the quest tracker frame
        local frame = _G["MyAddonQuestTracker"]
        if frame then
            if frame:IsShown() then
                frame:Hide()
                MyAddonDB.config.QUEST = false
                print("Quest Tracker hidden.")
            else
                frame:Show()
                MyAddonDB.config.QUEST = true
                MyAddon:CreateQuestTracker()
                print("Quest Tracker shown.")
            end
        else
            print("Quest Tracker frame not found.")
        end
    end
end
