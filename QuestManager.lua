--- Central manager for all quest operations and document synchronization
--- Handles document snapshots, networking, and provides the API for quest manipulation
--- @class QMQuestManager
--- @field mod table The Codex mod loading instance
--- @field documentName string The name of the document used for quest storage
QMQuestManager = RegisterGameType("QMQuestManager")
QMQuestManager.__index = QMQuestManager

-- Module-level document monitor for persistence (like ZenHeroTokens pattern)
local mod = dmhub.GetModLoading()
local documentName = "QMQuestLog"

--- Creates a new quest manager instance
--- @return QMQuestManager instance The new quest manager instance
function QMQuestManager:new()
    local instance = setmetatable({}, self)
    instance.mod = mod
    instance.documentName = documentName
    return instance
end

--- Initializes the quest log with the default structure
--- forcing the initialization
--- WANRING!!! All data will be lost!
--- @return table doc The initialized document
function QMQuestManager:InitializeDocument()
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    doc:BeginChange()
    doc.data = {
        quests = {},
        metadata = {
            campaignName = dmhub.gameid,
            version = 1,
            createdTimestamp = timestamp,
            modifiedTimestamp = timestamp
        }
    }
    doc:CompleteChange("Initialize quest log", {undoable = true})
    return doc
end

--- Creates and stores a quest in the manager then returns it
--- @return QMQuest|nil quest The newly created quest or nil if we can't create or store one
function QMQuestManager:CreateQuest()
    local quest = QMQuest:new()
    if quest then
        self:StoreQuest(quest)
        return self:GetQuest(quest:GetID())
    end
    return nil
end

--- Gets a quest by its ID with visibility checks applied
--- @param questId string The GUID of the quest
--- @return QMQuest|nil instance The quest instance or nil if not found or not visible
function QMQuestManager:GetQuest(questId)
    local doc = self:_safeDoc()
    if doc and doc.data.quests[questId] then
        local quest = doc.data.quests[questId]
        if QMQuestManager._questVisibleToUser(quest) then
            return quest
        end
    end
    return nil
end

--- Gets a quest by its name (case insensitive) with visibility checks applied
--- @param questTitle string The name of the quest to find
--- @return QMQuest|nil instance The quest instance or nil if not found or not visible
function QMQuestManager:GetQuestByTitle(questTitle)
    local doc = self:_safeDoc()
    if doc and questTitle then
        local lowerName = string.lower(questTitle)
        for _, quest in pairs(doc.data.quests) do
            if QMQuestManager._questVisibleToUser(quest) and string.lower(quest:GetTitle()) == lowerName then
                return quest
            end
        end
    end
    return nil
end

--- Return the timestamp the quest was last modified or nil if not found
--- @param questId string The GUID identifier of the quest to evaluate
--- @return string|osdate|nil lastModified The timestampe the quest was last modified or nil of not found
function QMQuestManager:GetQuestLastModified(questId)
    local doc = self:_safeDoc()
    if doc and doc.data.quests[questId] then
        return doc.data.quests[questId]:GetModifiedTimestamp()
    end
    return nil
end

--- Stores a quest
--- @param quest QMQuest The quest to store
--- @return QMQuest quest The quest passed
function QMQuestManager:StoreQuest(quest)
    local doc = self:_safeDoc()
    if doc then
        doc:BeginChange()

        doc.data.quests[quest:GetID()] = quest:_setModifiedTimestamp()
        if doc.data.metadata then
            doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        end

        doc:CompleteChange("Added quest", {undoable = false})
    end
    return quest
end

--- Deletes a quest and all its associated data
--- @param questId string The GUID of the quest to delete
function QMQuestManager:DeleteQuest(questId)
    local doc = self:_safeDoc()
    if doc and doc.data.quests[questId] then

        doc:BeginChange()

        doc.data.quests[questId] = nil
        if doc.data.metadata then
            doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        end

        doc:CompleteChange("Deleted quest", {undoable = false})
    end
end

--- Executes an update function callback within a change transaction
--- @param f function The function to execute
function QMQuestManager:ExecuteUpdateFn(f)
    local doc = self:_safeDoc()
    if doc then
        doc:BeginChange()
        f()
        if doc.data.metadata then
            doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        end
        doc:CompleteChange("quest update", {undoable = false})
    end
end

--- Gets all quests visible to the current user
--- @return table quests Hash table of QMQuest instances
--- @return number questCount Number of quests in the hash table
function QMQuestManager:GetAllQuests()
    local doc = self:_safeDoc()
    local quests = {}
    local questCount = 0

    if doc then
        for questId, quest in pairs(doc.data.quests) do
            if QMQuestManager._questVisibleToUser(quest) then
                quests[questId] = DeepCopy(quest)
                questCount = questCount + 1
            end
        end
    end

    return quests, questCount
end

--- Gets quests filtered by status
--- @param status string One of QMQuest.STATUS values
--- @return table quests Array of QMQuest instances with the specified status
function QMQuestManager:GetQuestsByStatus(status)
    local allQuests = self:GetAllQuests()
    local filteredQuests = {}

    for _, quest in ipairs(allQuests) do
        if quest:GetStatus() == status then
            table.insert(filteredQuests, quest)
        end
    end

    return filteredQuests
end

--- Gets quests filtered by category
--- @param category string One of QMQuest.CATEGORY values
--- @return table quests Array of QMQuest instances with the specified category
function QMQuestManager:GetQuestsByCategory(category)
    local allQuests = self:GetAllQuests()
    local filteredQuests = {}

    for _, quest in ipairs(allQuests) do
        if quest:GetCategory() == category then
            table.insert(filteredQuests, quest)
        end
    end

    return filteredQuests
end

--- Initializes the quest log document with default structure
--- if it's not already set
--- @return table doc The document
function QMQuestManager:_ensureDocInitialized()
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if QMQuestManager._validDoc(doc) then
        return doc
    end
    return self:InitializeDocument()
end

--- Helper function to determine whether a quest is visible to the current user
--- @param quest QMQuest The quest object for which to evaluate visibility
--- @return boolean isVisible Whether the quest is visible to the current user
--- @private
function QMQuestManager._questVisibleToUser(quest)
    return dmhub.isDM or quest:GetVisibleToPlayers() or dmhub.userid == quest:GetCreatedBy()
end

--- Return a document object that is guaranteed to be valid or nil
--- @return table|nil doc The doc if it's valid
function QMQuestManager:_safeDoc()
    local doc = self:_ensureDocInitialized()
    if QMQuestManager._validDoc(doc) then
        return doc
    end
    return nil
end

--- Determine whether the document has the valid / expected structure
--- @return boolean isValid Whether the document has the expected structure
function QMQuestManager._validDoc(doc)
    return doc.data and type(doc.data) == "table" and doc.data.quests and type(doc.data.quests) == "table"
end

--- Gets the path for document monitoring in UI
--- @return string path The document path for monitoring
function QMQuestManager:GetDocumentPath()
    return self.mod:GetDocumentSnapshot(self.documentName).path
end
