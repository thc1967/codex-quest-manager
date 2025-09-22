--- Individual note attached to quests or objectives with author tracking
--- Supports both player notes and director notes with visibility controls
--- @class QMQuestNote
--- @field _manager QMQuestManager The quest manager for document operations
--- @field id string GUID identifier for this note
QMQuestNote = RegisterGameType("QMQuestNote")
QMQuestNote.__index = QMQuestNote

--- Creates a new quest note instance
--- @param manager QMQuestManager The quest manager for document operations
--- @param questId string GUID identifier for the parent quest
--- @param noteId string GUID identifier for this note
--- @return QMQuestNote instance The new note instance
function QMQuestNote:new(manager, questId, noteId)
    local instance = setmetatable({}, self)
    instance._manager = manager
    instance.questId = questId
    instance.id = noteId or dmhub.GenerateGuid()
    return instance
end

--- Gets the content text of this note
--- @return string content The note's text content
function QMQuestNote:GetContent()
    return self._manager:GetQuestNoteField(self.questId, self.id, "content") or ""
end

--- Sets the content text of this note
--- @param content string The new text content for the note
function QMQuestNote:SetContent(content)
    self._manager:UpdateQuestNoteField(self.questId, self.id, "content", content)
end

--- Gets the author ID who created this note
--- @return string authorId The Codex player ID of the note author
function QMQuestNote:GetAuthorId()
    return self._manager:GetQuestNoteField(self.questId, self.id, "authorId") or ""
end

--- Sets the author ID for this note
--- @param authorId string The Codex player ID of the note author
function QMQuestNote:SetAuthorId(authorId)
    self._manager:UpdateQuestNoteField(self.questId, self.id, "authorId", authorId)
end

--- Gets the timestamp when this note was created
--- @return string timestamp ISO 8601 UTC timestamp
function QMQuestNote:GetTimestamp()
    return self._manager:GetQuestNoteField(self.questId, self.id, "timestamp") or ""
end

--- Sets the timestamp for this note
--- @param timestamp string ISO 8601 UTC timestamp
function QMQuestNote:SetTimestamp(timestamp)
    self._manager:UpdateQuestNoteField(self.questId, self.id, "timestamp", timestamp)
end


--- Updates multiple note properties in a single document transaction
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QMQuestNote:UpdateProperties(properties, changeDescription)
    self._manager:UpdateQuestNote(self.questId, self.id, properties, changeDescription)
end


