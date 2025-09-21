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
    if not doc.data then
        doc:BeginChange()
        doc.data = {
            quests = {},
            objectives = {},
            notes = {},
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

    -- Remove associated objectives and their notes
    local objectiveIds = doc.data.quests[questId].objectiveIds or {}
    for _, objectiveId in ipairs(objectiveIds) do
        self:_deleteObjectiveData(doc, objectiveId)
    end

    -- Remove quest notes
    local noteIds = doc.data.quests[questId].noteIds or {}

    if doc.data.notes then
        for _, noteId in ipairs(noteIds) do
            doc.data.notes[noteId] = nil
        end
    end

    -- Remove the quest itself
    doc.data.quests[questId] = nil
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Deleted quest", {undoable = true})
end

--- Helper function to delete objective data
--- @param doc table The document snapshot
--- @param objectiveId string The GUID of the objective to delete
function QTQuestManager:_deleteObjectiveData(doc, objectiveId)
    if not doc.data.objectives or not doc.data.objectives[objectiveId] then
        return
    end

    -- Remove objective notes
    local playerNoteIds = doc.data.objectives[objectiveId].playerNoteIds or {}
    local directorNoteIds = doc.data.objectives[objectiveId].directorNoteIds or {}

    if doc.data.notes then
        for _, noteId in ipairs(playerNoteIds) do
            doc.data.notes[noteId] = nil
        end
        for _, noteId in ipairs(directorNoteIds) do
            doc.data.notes[noteId] = nil
        end
    end

    -- Remove the objective
    doc.data.objectives[objectiveId] = nil
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
    if not doc.data.quests[questId] then
        doc.data.quests[questId] = {}
    end

    doc:BeginChange()
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

--- Gets a field value from an objective
--- @param objectiveId string The GUID of the objective
--- @param field string The field name to retrieve
--- @return any value The field value or nil
function QTQuestManager:GetObjectiveField(objectiveId, field)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.objectives and doc.data.objectives[objectiveId] then
        return doc.data.objectives[objectiveId][field]
    end
    return nil
end

--- Updates a single field in an objective
--- @param objectiveId string The GUID of the objective
--- @param field string The field name to update
--- @param value any The new field value
function QTQuestManager:UpdateObjectiveField(objectiveId, field, value)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data.objectives[objectiveId] then
        doc.data.objectives[objectiveId] = {}
    end

    doc:BeginChange()
    doc.data.objectives[objectiveId][field] = value
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
    doc:CompleteChange("Update objective " .. field, {undoable = true})
end

--- Updates multiple fields in an objective
--- @param objectiveId string The GUID of the objective
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuestManager:UpdateObjectiveProperties(objectiveId, properties, changeDescription)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    if not doc.data.objectives then
        doc.data.objectives = {}
    end
    if not doc.data.objectives[objectiveId] then
        doc.data.objectives[objectiveId] = {}
    end

    doc:BeginChange()

    for field, value in pairs(properties) do
        doc.data.objectives[objectiveId][field] = value
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange(changeDescription or "Update objective properties", {undoable = true})
end

--- Gets a field value from a note
--- @param noteId string The GUID of the note
--- @param field string The field name to retrieve
--- @return any value The field value or nil
function QTQuestManager:GetNoteField(noteId, field)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if doc.data and doc.data.notes and doc.data.notes[noteId] then
        return doc.data.notes[noteId][field]
    end
    return nil
end

--- Updates a single field in a note
--- @param noteId string The GUID of the note
--- @param field string The field name to update
--- @param value any The new field value
function QTQuestManager:UpdateNoteField(noteId, field, value)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data.notes[noteId] then
        doc.data.notes[noteId] = {}
    end

    doc:BeginChange()
    doc.data.notes[noteId][field] = value
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
    doc:CompleteChange("Update note " .. field, {undoable = true})
end

--- Updates multiple fields in a note
--- @param noteId string The GUID of the note
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuestManager:UpdateNoteProperties(noteId, properties, changeDescription)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    if not doc.data.notes then
        doc.data.notes = {}
    end
    if not doc.data.notes[noteId] then
        doc.data.notes[noteId] = {}
    end

    doc:BeginChange()

    for field, value in pairs(properties) do
        doc.data.notes[noteId][field] = value
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange(changeDescription or "Update note properties", {undoable = true})
end

--- Adds an objective to a quest
--- @param questId string The GUID of the quest
--- @param objectiveId string The GUID of the objective to add
function QTQuestManager:AddObjectiveToQuest(questId, objectiveId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    doc:BeginChange()

    -- Ensure quest exists and has objective list
    if not doc.data.quests then
        doc.data.quests = {}
    end
    if not doc.data.quests[questId] then
        doc.data.quests[questId] = {}
    end
    if not doc.data.quests[questId].objectiveIds then
        doc.data.quests[questId].objectiveIds = {}
    end

    -- Add objective ID to quest
    table.insert(doc.data.quests[questId].objectiveIds, objectiveId)
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Added objective to quest", {undoable = true})
end

--- Removes an objective from a quest
--- @param questId string The GUID of the quest
--- @param objectiveId string The GUID of the objective to remove
function QTQuestManager:RemoveObjectiveFromQuest(questId, objectiveId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    doc:BeginChange()

    -- Remove from quest's objective list
    if doc.data.quests and doc.data.quests[questId] and doc.data.quests[questId].objectiveIds then
        local objectiveIds = doc.data.quests[questId].objectiveIds
        for i, id in ipairs(objectiveIds) do
            if id == objectiveId then
                table.remove(objectiveIds, i)
                break
            end
        end
    end

    -- Delete the objective data
    self:_deleteObjectiveData(doc, objectiveId)
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Removed objective from quest", {undoable = true})
end

--- Adds a note to a quest
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note to add
function QTQuestManager:AddNoteToQuest(questId, noteId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    doc:BeginChange()

    -- Ensure quest exists and has note list
    if not doc.data.quests then
        doc.data.quests = {}
    end
    if not doc.data.quests[questId] then
        doc.data.quests[questId] = {}
    end

    if not doc.data.quests[questId].noteIds then
        doc.data.quests[questId].noteIds = {}
    end

    -- Add note ID to list
    table.insert(doc.data.quests[questId].noteIds, noteId)
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Added note to quest", {undoable = true})
end

--- Removes a note from a quest
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note to remove
function QTQuestManager:RemoveNoteFromQuest(questId, noteId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    doc:BeginChange()

    if doc.data.quests and doc.data.quests[questId] and doc.data.quests[questId].noteIds then
        local noteIds = doc.data.quests[questId].noteIds
        for i, id in ipairs(noteIds) do
            if id == noteId then
                table.remove(noteIds, i)
                break
            end
        end
    end

    -- Delete the note data
    if doc.data.notes then
        doc.data.notes[noteId] = nil
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Removed note from quest", {undoable = true})
end

--- Adds a note to an objective
--- @param objectiveId string The GUID of the objective
--- @param noteId string The GUID of the note to add
--- @param noteType string Either "player" or "director"
function QTQuestManager:AddNoteToObjective(objectiveId, noteId, noteType)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    doc:BeginChange()

    -- Ensure objective exists and has note lists
    if not doc.data.objectives then
        doc.data.objectives = {}
    end
    if not doc.data.objectives[objectiveId] then
        doc.data.objectives[objectiveId] = {}
    end

    local noteListField = noteType == "player" and "playerNoteIds" or "directorNoteIds"
    if not doc.data.objectives[objectiveId][noteListField] then
        doc.data.objectives[objectiveId][noteListField] = {}
    end

    -- Add note ID to appropriate list
    table.insert(doc.data.objectives[objectiveId][noteListField], noteId)
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Added note to objective", {undoable = true})
end

--- Removes a note from an objective
--- @param objectiveId string The GUID of the objective
--- @param noteId string The GUID of the note to remove
function QTQuestManager:RemoveNoteFromObjective(objectiveId, noteId)
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    if not doc.data then
        return
    end

    doc:BeginChange()

    if doc.data.objectives and doc.data.objectives[objectiveId] then
        -- Remove from both player and director note lists
        local noteFields = {"playerNoteIds", "directorNoteIds"}
        for _, field in ipairs(noteFields) do
            if doc.data.objectives[objectiveId][field] then
                local noteIds = doc.data.objectives[objectiveId][field]
                for i, id in ipairs(noteIds) do
                    if id == noteId then
                        table.remove(noteIds, i)
                        break
                    end
                end
            end
        end
    end

    -- Delete the note data
    if doc.data.notes then
        doc.data.notes[noteId] = nil
    end
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

    doc:CompleteChange("Removed note from objective", {undoable = true})
end

--- Gets the path for document monitoring in UI
--- @return string path The document path for monitoring
function QTQuestManager:GetDocumentPath()
    return monitorDoc.path
end
