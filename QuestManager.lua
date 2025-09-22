--- Central manager for all quest operations and document synchronization
--- Handles document snapshots, networking, and provides the API for quest manipulation
--- @class QTQuestManager
--- @field mod table The Codex mod loading instance
--- @field documentName string The name of the document used for quest storage
QTQuestManager = RegisterGameType("QTQuestManager")
QTQuestManager.__index = QTQuestManager

-- Module-level document monitor for persistence (like ZenHeroTokens pattern)
local mod = dmhub.GetModLoading()
local documentName = "QTQuestLog"
local monitorDoc = mod:GetDocumentSnapshot(documentName)

--- Creates a new quest manager instance
--- @return QTQuestManager instance The new quest manager instance
function QTQuestManager:new()
    local instance = setmetatable({}, self)
    instance.mod = dmhub.GetModLoading()
    instance.documentName = "QTQuestLog"

    -- Initialize document if it doesn't exist
    instance:_initializeDocument()

    return instance
end

--- Initializes the quest log document with default structure
function QTQuestManager:_initializeDocument()
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or type(doc.data) ~= "table" then
        doc:BeginChange()
        doc.data = {
            quests = {},
            metadata = {
                campaignName = "Default Campaign",
                version = 1,
                createdTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        }
        doc:CompleteChange("Initialize quest log", {undoable = true})
    end
end

--- Creates a new quest with basic properties
--- @param title string The quest title
--- @param createdBy string The Codex player ID of the creator
--- @return QTQuest instance The newly created quest
function QTQuestManager:CreateQuest(title, createdBy)
    local quest = QTQuest:new(self)
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    quest:UpdateProperties(
        {
            title = title or "New Quest",
            description = "",
            category = QTQuest.CATEGORY.MAIN,
            status = QTQuest.STATUS.NOT_STARTED,
            priority = QTQuest.PRIORITY.MEDIUM,
            questGiver = "",
            location = "",
            rewards = "",
            rewardsClaimed = false,
            visibleToPlayers = true,
            createdBy = createdBy or "",
            createdTimestamp = timestamp,
            modifiedTimestamp = timestamp
        },
        "Created new quest"
    )

    return quest
end

--- Creates a new draft quest that exists in memory but is not persisted
--- @param title string The quest title (optional)
--- @param createdBy string The Codex player ID of the creator (optional)
--- @return QTQuest instance The newly created draft quest
function QTQuestManager:CreateDraftQuest(title, createdBy)
    local quest = QTQuest:new(self)
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    -- Set properties directly without calling UpdateProperties (which persists)
    quest.title = title or "New Quest"
    quest.description = ""
    quest.category = QTQuest.CATEGORY.MAIN
    quest.status = QTQuest.STATUS.NOT_STARTED
    quest.priority = QTQuest.PRIORITY.MEDIUM
    quest.questGiver = ""
    quest.location = ""
    quest.rewards = ""
    quest.rewardsClaimed = false
    quest.visibleToPlayers = true
    quest.createdBy = createdBy or ""
    quest.createdTimestamp = timestamp
    quest.modifiedTimestamp = timestamp

    return quest
end

--- Saves a draft quest to persistent storage
--- @param quest QTQuest The draft quest to save
--- @return boolean success Whether the save was successful
function QTQuestManager:SaveDraftQuest(quest)
    if not quest then
        return false
    end

    -- Use UpdateProperties to persist the quest
    quest:UpdateProperties({
        title = quest.title,
        description = quest.description,
        category = quest.category,
        status = quest.status,
        priority = quest.priority,
        questGiver = quest.questGiver,
        location = quest.location,
        rewards = quest.rewards,
        rewardsClaimed = quest.rewardsClaimed,
        visibleToPlayers = quest.visibleToPlayers,
        createdBy = quest.createdBy,
        createdTimestamp = quest.createdTimestamp,
        modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }, "Saved draft quest")

    return true
end

--- Gets a quest by its ID
--- @param questId string The GUID of the quest
--- @return QTQuest|nil instance The quest instance or nil if not found
function QTQuestManager:GetQuest(questId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.quests and doc.data.quests[questId] then
        return QTQuest:new(self, questId)
    end
    return nil
end

--- Gets all quests visible to the current user
--- @return table quests Array of QTQuest instances
function QTQuestManager:GetAllQuests()
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    local quests = {}

    if doc.data and doc.data.quests then
        for questId, _ in pairs(doc.data.quests) do
            local quest = QTQuest:new(self, questId)

            -- Apply user-based filtering
            if dmhub.isDM then
                -- DMs see all quests
                table.insert(quests, quest)
            else
                -- Players see quests that are visible to players OR quests they created
                if quest:GetVisibleToPlayers() or quest:GetCreatedBy() == dmhub.userid then
                    table.insert(quests, quest)
                end
            end
        end
    end

    return quests
end

--- Gets quests filtered by status
--- @param status string One of QTQuest.STATUS values
--- @return table quests Array of QTQuest instances with the specified status
function QTQuestManager:GetQuestsByStatus(status)
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
--- @param category string One of QTQuest.CATEGORY values
--- @return table quests Array of QTQuest instances with the specified category
function QTQuestManager:GetQuestsByCategory(category)
    local allQuests = self:GetAllQuests()
    local filteredQuests = {}

    for _, quest in ipairs(allQuests) do
        if quest:GetCategory() == category then
            table.insert(filteredQuests, quest)
        end
    end

    return filteredQuests
end

--- Deletes a quest and all its associated data
--- @param questId string The GUID of the quest to delete
function QTQuestManager:DeleteQuest(questId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Remove the quest itself (includes all objectives and notes as child data)
    doc.data.quests[questId] = nil
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Deleted quest", {undoable = true})
end

--- Gets a field value from a quest
--- @param questId string The GUID of the quest
--- @param field string The field name to retrieve
--- @return any value The field value or nil
function QTQuestManager:GetQuestField(questId, field)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.quests and doc.data.quests[questId] then
        return doc.data.quests[questId][field]
    end
    return nil
end

--- Updates a single field in a quest
--- @param questId string The GUID of the quest
--- @param field string The field name to update
--- @param value any The new field value
function QTQuestManager:UpdateQuestField(questId, field, value)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)

    doc:BeginChange()
    -- Ensure document structure exists
    if not doc.data or type(doc.data) ~= "table" then
        doc.data = {}
    end
    if not doc.data.quests or type(doc.data.quests) ~= "table" then
        doc.data.quests = {}
    end
    if not doc.data.quests[questId] or type(doc.data.quests[questId]) ~= "table" then
        doc.data.quests[questId] = {}
    end

    doc.data.quests[questId][field] = value
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
    doc:CompleteChange("Update quest " .. field, {undoable = true})
end

--- Updates multiple fields in a quest
--- @param questId string The GUID of the quest
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuestManager:UpdateQuestProperties(questId, properties, changeDescription)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    if not doc.data.quests then
        doc.data.quests = {}
    end
    if not doc.data.quests[questId] then
        doc.data.quests[questId] = {}
    end

    doc:BeginChange()

    for field, value in pairs(properties) do
        doc.data.quests[questId][field] = value
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange(changeDescription or "Update quest properties", {undoable = true})
end

--- Gets all objectives for a quest
--- @param questId string The GUID of the quest
--- @return table objectives Table of objectives keyed by objective ID
function QTQuestManager:GetQuestObjectives(questId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.quests and doc.data.quests[questId] and doc.data.quests[questId].objectives then
        return doc.data.quests[questId].objectives
    end
    return {}
end

--- Gets all notes for a quest
--- @param questId string The GUID of the quest
--- @return table notes Table of notes keyed by note ID
function QTQuestManager:GetQuestNotes(questId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.quests and doc.data.quests[questId] and doc.data.quests[questId].notes then
        return doc.data.quests[questId].notes
    end
    return {}
end

--- Gets a field value from a quest objective
--- @param questId string The GUID of the quest
--- @param objectiveId string The GUID of the objective
--- @param field string The field name to retrieve
--- @return any value The field value or nil
function QTQuestManager:GetQuestObjectiveField(questId, objectiveId, field)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.quests and doc.data.quests[questId] and
       doc.data.quests[questId].objectives and doc.data.quests[questId].objectives[objectiveId] then
        return doc.data.quests[questId].objectives[objectiveId][field]
    end
    return nil
end

--- Updates a field value in a quest objective
--- @param questId string The GUID of the quest
--- @param objectiveId string The GUID of the objective
--- @param field string The field name to update
--- @param value any The new field value
function QTQuestManager:UpdateQuestObjectiveField(questId, objectiveId, field, value)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Ensure objectives table exists
    if not doc.data.quests[questId].objectives then
        doc.data.quests[questId].objectives = {}
    end
    if not doc.data.quests[questId].objectives[objectiveId] then
        doc.data.quests[questId].objectives[objectiveId] = {}
    end

    -- Update the field
    doc.data.quests[questId].objectives[objectiveId][field] = value
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Update objective " .. field, {undoable = true})
end

--- Updates multiple properties in a quest objective
--- @param questId string The GUID of the quest
--- @param objectiveId string The GUID of the objective
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuestManager:UpdateQuestObjective(questId, objectiveId, properties, changeDescription)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Ensure objectives table exists
    if not doc.data.quests[questId].objectives then
        doc.data.quests[questId].objectives = {}
    end
    if not doc.data.quests[questId].objectives[objectiveId] then
        doc.data.quests[questId].objectives[objectiveId] = {}
    end

    -- Update all properties
    for field, value in pairs(properties) do
        doc.data.quests[questId].objectives[objectiveId][field] = value
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange(changeDescription or "Update objective properties", {undoable = true})
end

--- Deletes an objective from a quest
--- @param questId string The GUID of the quest
--- @param objectiveId string The GUID of the objective to delete
function QTQuestManager:DeleteQuestObjective(questId, objectiveId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Remove the objective
    if doc.data.quests[questId].objectives then
        doc.data.quests[questId].objectives[objectiveId] = nil
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Removed objective from quest", {undoable = true})
end

--- Gets a field value from a quest note
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note
--- @param field string The field name to retrieve
--- @return any value The field value or nil
function QTQuestManager:GetQuestNoteField(questId, noteId, field)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.quests and doc.data.quests[questId] and
       doc.data.quests[questId].notes and doc.data.quests[questId].notes[noteId] then
        return doc.data.quests[questId].notes[noteId][field]
    end
    return nil
end

--- Updates a field value in a quest note
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note
--- @param field string The field name to update
--- @param value any The new field value
function QTQuestManager:UpdateQuestNoteField(questId, noteId, field, value)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Ensure notes table exists
    if not doc.data.quests[questId].notes then
        doc.data.quests[questId].notes = {}
    end
    if not doc.data.quests[questId].notes[noteId] then
        doc.data.quests[questId].notes[noteId] = {}
    end

    -- Update the field
    doc.data.quests[questId].notes[noteId][field] = value
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Update note " .. field, {undoable = true})
end

--- Updates multiple properties in a quest note
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuestManager:UpdateQuestNote(questId, noteId, properties, changeDescription)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Ensure notes table exists
    if not doc.data.quests[questId].notes then
        doc.data.quests[questId].notes = {}
    end
    if not doc.data.quests[questId].notes[noteId] then
        doc.data.quests[questId].notes[noteId] = {}
    end

    -- Update all properties
    for field, value in pairs(properties) do
        doc.data.quests[questId].notes[noteId][field] = value
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange(changeDescription or "Update note properties", {undoable = true})
end

--- Deletes a note from a quest
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note to delete
function QTQuestManager:DeleteQuestNote(questId, noteId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data or not doc.data.quests or not doc.data.quests[questId] then
        return
    end

    doc:BeginChange()

    -- Remove the note
    if doc.data.quests[questId].notes then
        doc.data.quests[questId].notes[noteId] = nil
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Removed note from quest", {undoable = true})
end

--- Gets the path for document monitoring in UI
--- @return string path The document path for monitoring
function QTQuestManager:GetDocumentPath()
    return monitorDoc.path
end
