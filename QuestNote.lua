--- Individual note attached to quests or objectives with author tracking
--- Supports both player notes and director notes with visibility controls
--- @class QMQuestNote
--- @field _manager QMQuestManager The quest manager for document operations
--- @field id string GUID identifier for this note
--- @field authorId string GUID identifier for this note's creator
--- @field content string The content of the note
--- @field createdAt string|osdate ISO 8601 UTC timestamp
QMQuestNote = RegisterGameType("QMQuestNote")
QMQuestNote.__index = QMQuestNote

--- Creates a new quest note instance
--- @param manager QMQuestManager The quest manager for document operations
--- @return QMQuestNote instance The new note instance
function QMQuestNote:new(content)
    local instance = setmetatable({}, self)
    instance.id = dmhub.GenerateGuid()
    instance.content = content or ""
    instance.authorId = dmhub.userid
    instance.createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
    return instance
end

--- Gets the author ID who created this note
--- @return string authorId The Codex player ID of the note author
function QMQuestNote:GetAuthorId()
    return self.authorId
end

--- Gets the content text of this note
--- @return string content The note's text content
function QMQuestNote:GetContent()
    return self.content
end

--- Sets the content text of this note
--- @param content string The new text content for the note
function QMQuestNote:SetContent(content)
    self.content = content
end

--- Gets the timestamp when this note was created
--- @return string|osdate timestamp ISO 8601 UTC timestamp
function QMQuestNote:GetCreatedAt()
    return self.createdAt
end
