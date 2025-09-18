local mod = dmhub.GetModLoading()
local questManager = QTQuestManager:new()
local questPanel = QTQuestTrackerPanel:new(questManager)
if questPanel then
    questPanel:Register()
end
