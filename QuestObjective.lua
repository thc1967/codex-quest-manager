--- Individual objective within a quest with status tracking and notes
--- Supports the same status progression as quests with player and director notes
--- @class QTQuestObjective
--- @field _manager QTQuestManager The quest manager for document operations
--- @field id string GUID identifier for this objective 
QTQuestObjective = RegisterGameType("QTQuestObjective")
QTQuestObjective.__index = QTQuestObjective

--- Valid status values for quest objectives
QTQuestObjective.STATUS = {
    NOT_STARTED = "not_started",
    ACTIVE = "active",
    COMPLETED = "completed",
    FAILED = "failed",
    ON_HOLD = "on_hold"
}

--- Creates a new quest objective instance
--- @param manager QTQuestManager The quest manager for document operations
--- @param objectiveId string GUID identifier for this objective
--- @return QTQuestObjective instance The new objective instance
function QTQuestObjective:new(manager, objectiveId)
    local instance = setmetatable({}, self)
    instance._manager = manager
    instance.id = objectiveId or dmhub.GenerateGuid()
    return instance
end

--- Gets the description text of this objective
--- @return string description The objective's description
function QTQuestObjective:GetDescription()
    return self._manager:GetObjectiveField(self.id, "description") or ""
end

--- Sets the description text of this objective
--- @param description string The new description for the objective
function QTQuestObjective:SetDescription(description)
    self._manager:UpdateObjectiveField(self.id, "description", description)
end

--- Gets the current status of this objective
--- @return string status One of QTQuestObjective.STATUS values
function QTQuestObjective:GetStatus()
    return self._manager:GetObjectiveField(self.id, "status") or QTQuestObjective.STATUS.NOT_STARTED
end

--- Sets the status of this objective
--- @param status string One of QTQuestObjective.STATUS values
function QTQuestObjective:SetStatus(status)
    if self:_isValidStatus(status) then
        self._manager:UpdateObjectiveField(self.id, "status", status)
        self._manager:UpdateObjectiveField(self.id, "modifiedTimestamp", os.date("!%Y-%m-%dT%H:%M:%SZ"))
    end
end

--- Gets the timestamp when this objective was created
--- @return string timestamp ISO 8601 UTC timestamp
function QTQuestObjective:GetCreatedTimestamp()
    return self._manager:GetObjectiveField(self.id, "createdTimestamp") or ""
end

--- Gets the timestamp when this objective was last modified
--- @return string timestamp ISO 8601 UTC timestamp
function QTQuestObjective:GetModifiedTimestamp()
    return self._manager:GetObjectiveField(self.id, "modifiedTimestamp") or ""
end

--- Gets all player notes for this objective
--- @return table notes Array of QTQuestNote instances
function QTQuestObjective:GetPlayerNotes()
    local noteIds = self._manager:GetObjectiveField(self.id, "playerNoteIds") or {}
    local notes = {}
    for _, noteId in ipairs(noteIds) do
        table.insert(notes, QTQuestNote:new(self._manager, noteId))
    end
    return notes
end

--- Adds a new player note to this objective
--- @param content string The note content
--- @param authorId string The Codex player ID of the author
--- @return QTQuestNote note The newly created note
function QTQuestObjective:AddPlayerNote(content, authorId)
    local note = QTQuestNote:new(self._manager)
    note:UpdateProperties(
        {
            content = content,
            authorId = authorId,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            visibleToPlayers = true
        },
        "Added player note to objective"
    )

    self._manager:AddNoteToObjective(self.id, note.id, "player")
    return note
end

--- Gets all director notes for this objective
--- @return table notes Array of QTQuestNote instances
function QTQuestObjective:GetDirectorNotes()
    local noteIds = self._manager:GetObjectiveField(self.id, "directorNoteIds") or {}
    local notes = {}
    for _, noteId in ipairs(noteIds) do
        table.insert(notes, QTQuestNote:new(self._manager, noteId))
    end
    return notes
end

--- Adds a new director note to this objective
--- @param content string The note content
--- @param authorId string The Codex player ID of the director
--- @param visibleToPlayers boolean Whether players can see this note
--- @return QTQuestNote note The newly created note
function QTQuestObjective:AddDirectorNote(content, authorId, visibleToPlayers)
    local note = QTQuestNote:new(self._manager)
    note:UpdateProperties(
        {
            content = content,
            authorId = authorId,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            visibleToPlayers = visibleToPlayers or false
        },
        "Added director note to objective"
    )

    self._manager:AddNoteToObjective(self.id, note.id, "director")
    return note
end

--- Removes a note from this objective
--- @param noteId string The GUID of the note to remove
function QTQuestObjective:RemoveNote(noteId)
    self._manager:RemoveNoteFromObjective(self.id, noteId)
end

--- Updates multiple objective properties in a single document transaction
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuestObjective:UpdateProperties(properties, changeDescription)
    if properties.status and not self:_isValidStatus(properties.status) then
        properties.status = nil -- Remove invalid status
    end

    -- Always update modified timestamp when updating properties
    properties.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    self._manager:UpdateObjectiveProperties(self.id, properties, changeDescription)
end

--- Validates if the given status is valid for objectives
--- @param status string The status to validate
--- @return boolean valid True if the status is valid
function QTQuestObjective:_isValidStatus(status)
    for _, validStatus in pairs(QTQuestObjective.STATUS) do
        if status == validStatus then
            return true
        end
    end
    return false
end


