local mod = dmhub.GetModLoading()
local questManager = QMQuestManager:new()
local questPanel = QMQuestTrackerPanel:new(questManager)
if questPanel then
    questPanel:Register()
end
