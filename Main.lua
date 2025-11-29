local questManager = QMQuestManager:new()
local questPanel = QMQuestTrackerPanel:new(questManager)
if questPanel then
    questPanel:Register()
end

if dmhub.isDM then

    --- Set the visibility status of a quest
    --- @param args string Pipe-separated list 1st element is quest name or guid; 2nd element is optional and 1, 0, true, false
    Commands.questsetvisible = function(args)
        local function parseArgs(str)
            if str == nil or #str == 0 then return nil, nil end

            local questId, visibleStr = str:match("^([^|]+)|?(.*)$")

            local visible = true
            if visibleStr and #visibleStr > 0 then
                visibleStr = visibleStr:trim():lower()
                visible = visibleStr == "1" or visibleStr == "true"
            end

            return questId:trim(), visible
        end

        local function isGuid(str)
            if #str ~= 36 then return false end
            return str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
        end

        local questId, visible = parseArgs(args)
        if questId and type(visible) == "boolean" then
            local questManager = QMQuestManager:new()
            if questManager then
                local quest
                if isGuid(questId) then
                    quest = questManager:GetQuest(questId)
                else
                    quest = questManager:GetQuestByTitle(questId)
                end
                if quest then
                    if quest:GetVisibleToPlayers() ~= visible then
                        questManager:ExecuteUpdateFn(function()
                            quest:SetVisibleToPlayers(visible)
                        end)
                    end
                end
            end
        end
    end
end