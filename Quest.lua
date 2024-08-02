local addonName, addon = ...
local frame = CreateFrame("Frame", "QuestCompletionFrame2", UIParent)
frame:SetSize(100, 100)
frame:SetPoint("CENTER")
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
text:SetPoint("CENTER")

local Quests_Completed = Quests_Completed or {}

local function QuestTurnedIn(questID, xpReward, moneyReward)
    local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
    print("Quest: ", questID, "XP: ", xpReward, "Money: ", moneyReward, "Completed: ", isCompleted)
    Quests_Completed[questID] = { Completed = isCompleted }
end

local function QuestAccepted(questID)
    local questLogIndex = C_QuestLog.GetLogIndexForQuestID(questID)
    local info = C_QuestLog.GetInfo(questLogIndex)
    print("Accepted Quest: ", questID, info.title)
    Quests_Completed[questID] = info
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        self.elapsed = 0 -- Initialize elapsed time
        self:RegisterEvent("QUEST_TURNED_IN")
        self:RegisterEvent("QUEST_ACCEPTED")
    elseif event == "QUEST_TURNED_IN" then
        QuestTurnedIn(...)
    elseif event == "QUEST_ACCEPTED" then
        QuestAccepted(...)
    end
end)

frame:SetScript("OnUpdate", function(self, elapsed)
    self.elapsed = self.elapsed + elapsed
    if self.elapsed >= 1 then -- Check every 1 second
        local completedQuests = {}
        local questIDs = {82676, 82689, 78938}

        for _, questID in ipairs(questIDs) do
            local isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
            completedQuests[questID] = isCompleted
        end

        local localization = {
            ["enUS"] = {
                ["quest82676"] = "|cFFDEB887Dustwallow Marsh:|r",
                ["quest82689"] = "|cFFDEB887Dragonblight:|r",
                ["quest78938"] = "|cFFDEB887Searing Gorge:|r",
                ["yes"] = "|cFF1EFF00Complete|r",
                ["no"] = "|cFFDC143CIncomplete|r"
            },
            ["ruRU"] = {
                ["quest82676"] = "|cFFDEB887Пылевые топи:|r",
                ["quest82689"] = "|cFFDEB887Драконий Погост:|r",
                ["quest78938"] = "|cFFDEB887Тлеющее ущелье:|r",
                ["yes"] = "|cFF1EFF00Выполнено|r",
                ["no"] = "|cFFDC143CНе выполнено|r"
            }
        }

        local locale = GetLocale()
        local locStrings = localization[locale] or localization["enUS"]

        local questStatus = locStrings["quest82676"] .. " "
        if completedQuests[82676] then
            questStatus = questStatus .. locStrings["yes"]
        else
            questStatus = questStatus .. locStrings["no"]
        end

        questStatus = questStatus .. "\n" .. locStrings["quest82689"] .. " "
        if completedQuests[82689] then
            questStatus = questStatus .. locStrings["yes"]
        else
            questStatus = questStatus .. locStrings["no"]
        end

        questStatus = questStatus .. "\n" .. locStrings["quest78938"] .. " "
        if completedQuests[78938] then
            questStatus = questStatus .. locStrings["yes"]
        else
            questStatus = questStatus .. locStrings["no"]
        end

        text:SetText(questStatus)
        
        self.elapsed = 0 -- Reset elapsed time
    end
end)

frame:RegisterEvent("PLAYER_LOGIN")

-- Slash command to hide the frame
SLASH_ZQ1 = "/zq"
SlashCmdList["ZQ"] = function()
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
    end
end
