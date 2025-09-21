--- Main quest object containing all quest data, objectives, and notes
--- Represents a complete quest with status tracking, categorization, and progress management
--- @class QTQuest
--- @field _manager QTQuestManager The quest manager for document operations
--- @field id string GUID identifier for this quest
QTQuest = RegisterGameType("QTQuest")
QTQuest.__index = QTQuest

--- Valid status values for quests
QTQuest.STATUS = {
    NOT_STARTED = "not_started",
    ACTIVE = "active",
    COMPLETED = "completed",
    FAILED = "failed",
    ON_HOLD = "on_hold"
}

--- Valid category values for quests
QTQuest.CATEGORY = {
    MAIN = "Main",
    SIDE = "Side",
    PERSONAL = "Personal",
    FACTION = "Faction",
    TUTORIAL = "Tutorial"
}

--- Valid priority values for quests
QTQuest.PRIORITY = {
    HIGH = "High",
    MEDIUM = "Medium",
    LOW = "Low"
}

--- Creates a new quest instance
--- @param manager QTQuestManager The quest manager for document operations
--- @param questId string GUID identifier for this quest
--- @return QTQuest instance The new quest instance
function QTQuest:new(manager, questId)
    local instance = setmetatable({}, self)
    instance._manager = manager
    instance.id = questId or dmhub.GenerateGuid()
    return instance
end

--- Gets the title of this quest
--- @return string title The quest title
function QTQuest:GetTitle()
    return self._manager:GetQuestField(self.id, "title") or ""
end

--- Sets the title of this quest
--- @param title string The new title for the quest
function QTQuest:SetTitle(title)
    self._manager:UpdateQuestField(self.id, "title", title)
end

--- Gets the description of this quest
--- @return string description The quest description
function QTQuest:GetDescription()
    return self._manager:GetQuestField(self.id, "description") or ""
end

--- Sets the description of this quest
--- @param description string The new description for the quest
function QTQuest:SetDescription(description)
    self._manager:UpdateQuestField(self.id, "description", description)
end


--- Gets the category of this quest
--- @return string category One of QTQuest.CATEGORY values
function QTQuest:GetCategory()
    return self._manager:GetQuestField(self.id, "category") or QTQuest.CATEGORY.MAIN
end

--- Sets the category of this quest
--- @param category string One of QTQuest.CATEGORY values
function QTQuest:SetCategory(category)
    if self:_isValidCategory(category) then
        self._manager:UpdateQuestField(self.id, "category", category)
    end
end

--- Gets the status of this quest
--- @return string status One of QTQuest.STATUS values
function QTQuest:GetStatus()
    return self._manager:GetQuestField(self.id, "status") or QTQuest.STATUS.NOT_STARTED
end

--- Sets the status of this quest
--- @param status string One of QTQuest.STATUS values
function QTQuest:SetStatus(status)
    if self:_isValidStatus(status) then
        self._manager:UpdateQuestField(self.id, "status", status)
        self._manager:UpdateQuestField(self.id, "modifiedTimestamp", os.date("!%Y-%m-%dT%H:%M:%SZ"))
    end
end

--- Gets the priority of this quest
--- @return string priority One of QTQuest.PRIORITY values
function QTQuest:GetPriority()
    return self._manager:GetQuestField(self.id, "priority") or QTQuest.PRIORITY.MEDIUM
end

--- Sets the priority of this quest
--- @param priority string One of QTQuest.PRIORITY values
function QTQuest:SetPriority(priority)
    if self:_isValidPriority(priority) then
        self._manager:UpdateQuestField(self.id, "priority", priority)
    end
end

--- Gets the quest giver name
--- @return string questGiver The name/description of who gave this quest
function QTQuest:GetQuestGiver()
    return self._manager:GetQuestField(self.id, "questGiver") or ""
end

--- Sets the quest giver name
--- @param questGiver string The name/description of who gave this quest
function QTQuest:SetQuestGiver(questGiver)
    self._manager:UpdateQuestField(self.id, "questGiver", questGiver)
end

--- Gets the quest location
--- @return string location The location associated with this quest
function QTQuest:GetLocation()
    return self._manager:GetQuestField(self.id, "location") or ""
end

--- Sets the quest location
--- @param location string The location associated with this quest
function QTQuest:SetLocation(location)
    self._manager:UpdateQuestField(self.id, "location", location)
end

--- Gets the rewards description
--- @return string rewards The description of quest rewards
function QTQuest:GetRewards()
    return self._manager:GetQuestField(self.id, "rewards") or ""
end

--- Sets the rewards description
--- @param rewards string The description of quest rewards
function QTQuest:SetRewards(rewards)
    self._manager:UpdateQuestField(self.id, "rewards", rewards)
end

--- Gets whether rewards have been claimed
--- @return boolean claimed True if rewards have been claimed
function QTQuest:GetRewardsClaimed()
    return self._manager:GetQuestField(self.id, "rewardsClaimed") or false
end

--- Sets whether rewards have been claimed
--- @param claimed boolean True if rewards have been claimed
function QTQuest:SetRewardsClaimed(claimed)
    self._manager:UpdateQuestField(self.id, "rewardsClaimed", claimed)
end

--- Gets whether this quest is visible to players
--- @return boolean visible True if players can see this quest
function QTQuest:GetVisibleToPlayers()
    return self._manager:GetQuestField(self.id, "visibleToPlayers") or (not dmhub.isDM)
end

--- Sets whether this quest is visible to players
--- @param visible boolean True if players should see this quest
function QTQuest:SetVisibleToPlayers(visible)
    self._manager:UpdateQuestField(self.id, "visibleToPlayers", visible)
end

--- Gets who created this quest
--- @return string createdBy The Codex player ID of the quest creator
function QTQuest:GetCreatedBy()
    return self._manager:GetQuestField(self.id, "createdBy") or ""
end

--- Gets when this quest was created
--- @return string timestamp ISO 8601 UTC timestamp
function QTQuest:GetCreatedTimestamp()
    return self._manager:GetQuestField(self.id, "createdTimestamp") or ""
end

--- Gets when this quest was last modified
--- @return string timestamp ISO 8601 UTC timestamp
function QTQuest:GetModifiedTimestamp()
    return self._manager:GetQuestField(self.id, "modifiedTimestamp") or ""
end

--- Gets the highest order number among all objectives for this quest
--- @return number maxOrder The highest order number, or 0 if no objectives exist
function QTQuest:GetMaxObjectiveOrder()
    local objectiveIds = self._manager:GetQuestField(self.id, "objectiveIds") or {}
    local maxOrder = 0

    for _, objectiveId in ipairs(objectiveIds) do
        local objective = QTQuestObjective:new(self._manager, objectiveId)
        local order = objective:GetOrder()
        if order > maxOrder then
            maxOrder = order
        end
    end

    return maxOrder
end

--- Gets all objectives for this quest sorted by order (lowest to highest)
--- @return table objectives Array of QTQuestObjective instances sorted by order
function QTQuest:GetObjectives()
    local objectiveIds = self._manager:GetQuestField(self.id, "objectiveIds") or {}
    local objectives = {}
    for _, objectiveId in ipairs(objectiveIds) do
        table.insert(objectives, QTQuestObjective:new(self._manager, objectiveId))
    end

    -- Sort objectives by order field (lowest to highest)
    table.sort(objectives, function(a, b)
        return a:GetOrder() < b:GetOrder()
    end)

    return objectives
end

--- Adds a new objective to this quest
--- @param description string The objective description
--- @return QTQuestObjective objective The newly created objective
function QTQuest:AddObjective(description)
    local objective = QTQuestObjective:new(self._manager)

    -- Get the next order number by finding the highest existing order and adding 1
    local nextOrder = self:GetMaxObjectiveOrder() + 1

    objective:UpdateProperties(
        {
            description = description,
            order = nextOrder
        },
        "Added objective to quest",
        true  -- Apply defaults
    )

    self._manager:AddObjectiveToQuest(self.id, objective.id)
    return objective
end

--- Removes an objective from this quest
--- @param objectiveId string The GUID of the objective to remove
function QTQuest:RemoveObjective(objectiveId)
    self._manager:RemoveObjectiveFromQuest(self.id, objectiveId)
end

--- Gets all notes for this quest sorted by timestamp (newest first)
--- @return table notes Array of QTQuestNote instances
function QTQuest:GetNotes()
    local noteIds = self._manager:GetQuestField(self.id, "noteIds") or {}
    local notes = {}
    for _, noteId in ipairs(noteIds) do
        table.insert(notes, QTQuestNote:new(self._manager, noteId))
    end

    -- Sort by timestamp descending (newest first)
    table.sort(notes, function(a, b)
        local timestampA = a:GetTimestamp()
        local timestampB = b:GetTimestamp()
        return timestampA > timestampB
    end)

    return notes
end

--- Adds a new note to this quest
--- @param content string The note content
--- @param authorId string The Codex player ID of the author
--- @return QTQuestNote note The newly created note
function QTQuest:AddNote(content, authorId)
    local note = QTQuestNote:new(self._manager)
    note:UpdateProperties(
        {
            content = content,
            authorId = authorId,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        },
        "Added note to quest"
    )

    self._manager:AddNoteToQuest(self.id, note.id)
    return note
end

--- Removes a note from this quest
--- @param noteId string The GUID of the note to remove
function QTQuest:RemoveNote(noteId)
    self._manager:RemoveNoteFromQuest(self.id, noteId)
end

--- Updates multiple quest properties in a single document transaction
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
function QTQuest:UpdateProperties(properties, changeDescription)
    -- Validate enums
    if properties.status and not self:_isValidStatus(properties.status) then
        properties.status = nil
    end
    if properties.category and not self:_isValidCategory(properties.category) then
        properties.category = nil
    end
    if properties.priority and not self:_isValidPriority(properties.priority) then
        properties.priority = nil
    end

    -- Always update modified timestamp when updating properties
    properties.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")

    self._manager:UpdateQuestProperties(self.id, properties, changeDescription)
end

--- Validates if the given status is valid for quests
--- @param status string The status to validate
--- @return boolean valid True if the status is valid
function QTQuest:_isValidStatus(status)
    for _, validStatus in pairs(QTQuest.STATUS) do
        if status == validStatus then
            return true
        end
    end
    return false
end

--- Validates if the given category is valid for quests
--- @param category string The category to validate
--- @return boolean valid True if the category is valid
function QTQuest:_isValidCategory(category)
    for _, validCategory in pairs(QTQuest.CATEGORY) do
        if category == validCategory then
            return true
        end
    end
    return false
end

--- Validates if the given priority is valid for quests
--- @param priority string The priority to validate
--- @return boolean valid True if the priority is valid
function QTQuest:_isValidPriority(priority)
    for _, validPriority in pairs(QTQuest.PRIORITY) do
        if priority == validPriority then
            return true
        end
    end
    return false
end


