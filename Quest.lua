--- Main quest object containing all quest data, objectives, and notes
--- Represents a complete quest with status tracking, categorization, and progress management
--- @class QMQuest
--- @field _manager QMQuestManager The quest manager for document operations
--- @field id string GUID identifier for this quest
--- @field title string The title of this quest
--- @field description string The description of this quest
--- @field category string The category of this quest
--- @field status string The status of this quest
--- @field priority string The priority of this quest
--- @field questGiver string The quest giver of this quest
--- @field location string The location of this quest
--- @field rewards string The rewards for completing this quest
--- @field rewardsClaimed boolean Whether the rewards for this quest have been claimed
--- @field visibleToPlayers boolean Whether this quest is visible to non-Directors
--- @field objectives table The list of objectives (QMObjective) for this quest
--- @field notes table The list of notes (QMNote) for this quest
--- @field createdBy string GUID identifier of the user who created this objective
--- @field createdAt string|osdate The ISO 8601 UTC timestamp
--- @field modifiedAt string|osdate The ISO 8601 UTC timestamp
QMQuest = RegisterGameType("QMQuest")
QMQuest.__index = QMQuest

--- Valid status values for quests
QMQuest.STATUS = {
    NOT_STARTED = "Not Started",
    ACTIVE = "Active",
    COMPLETED = "Completed",
    FAILED = "Failed",
    ON_HOLD = "On Hold"
}

--- Valid category values for quests
QMQuest.CATEGORY = {
    MAIN = "Main",
    SIDE = "Side",
    PERSONAL = "Personal",
    FACTION = "Faction",
    TUTORIAL = "Tutorial"
}

--- Valid priority values for quests
QMQuest.PRIORITY = {
    HIGH = "High",
    MEDIUM = "Medium",
    LOW = "Low"
}

--- Creates a new quest instance
--- @param questId? string GUID identifier for this quest
--- @return QMQuest instance The new quest instance
function QMQuest:new(questId)
    local instance = setmetatable({}, self)

    instance.id = questId or dmhub.GenerateGuid()
    instance.title = ""
    instance.description = ""
    instance.category = QMQuest.CATEGORY.MAIN
    instance.status = QMQuest.STATUS.NOT_STARTED
    instance.priority = QMQuest.PRIORITY.MEDIUM
    instance.questGiver = ""
    instance.location = ""
    instance.rewards = ""
    instance.rewardsClaimed = false
    instance.visibleToPlayers = (not dmhub.isDM)
    instance.objectives = {}
    instance.notes = {}
    instance.createdBy = dmhub.userid
    instance.createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
    instance.modifiedAt = nil

    return instance
end

--- Gets the identifier of this quest
--- @return string id GUID id of this quest
function QMQuest:GetID()
    return self.id
end

--- Gets the title of this quest
--- @return string title The quest title
function QMQuest:GetTitle()
    return self.title
end

--- Sets the title of this quest
--- @param title string The new title for the quest
--- @return QMQuest self For chaining
function QMQuest:SetTitle(title)
    self.title = title or ""
    return self
end

--- Gets the description of this quest
--- @return string description The quest description
function QMQuest:GetDescription()
    return self.description or ""
end

--- Sets the description of this quest
--- @param description string The new description for the quest
--- @return QMQuest self For chaining
function QMQuest:SetDescription(description)
    self.description = description or ""
    return self
end


--- Gets the category of this quest
--- @return string category One of QMQuest.CATEGORY values
function QMQuest:GetCategory()
    return self.category
end

--- Sets the category of this quest
--- @param category string One of QMQuest.CATEGORY values
--- @return QMQuest self For chaining
function QMQuest:SetCategory(category)
    if self:_isValidCategory(category) then
        self.category = category
    end
    return self
end

--- Gets the status of this quest
--- @return string status One of QMQuest.STATUS values
function QMQuest:GetStatus()
    return self.status
end

--- Sets the status of this quest
--- @param status string One of QMQuest.STATUS values
--- @return QMQuest self For chaining
function QMQuest:SetStatus(status)
    if self:_isValidStatus(status) then
        self.status = status
    end
    return self
end

--- Gets the priority of this quest
--- @return string priority One of QMQuest.PRIORITY values
function QMQuest:GetPriority()
    return self.priority
end

--- Sets the priority of this quest
--- @param priority string One of QMQuest.PRIORITY values
--- @return QMQuest self For Chaining
function QMQuest:SetPriority(priority)
    if self:_isValidPriority(priority) then
        self.priority = priority
    end
    return self
end

--- Gets the quest giver name
--- @return string questGiver The name/description of who gave this quest
function QMQuest:GetQuestGiver()
    return self.questGiver
end

--- Sets the quest giver name
--- @param questGiver string The name/description of who gave this quest
--- @return QMQuest self For chaining
function QMQuest:SetQuestGiver(questGiver)
    self.questGiver = questGiver or ""
    return self
end

--- Gets the quest location
--- @return string location The location associated with this quest
function QMQuest:GetLocation()
    return self.location
end

--- Sets the quest location
--- @param location string The location associated with this quest
--- @return QMQuest self For chaining
function QMQuest:SetLocation(location)
    self.location = location or ""
    return self
end

--- Gets the rewards description
--- @return string rewards The description of quest rewards
function QMQuest:GetRewards()
    return self.rewards
end

--- Sets the rewards description
--- @param rewards string The description of quest rewards
--- @return QMQuest self For chaining
function QMQuest:SetRewards(rewards)
    self.rewards = rewards or ""
    return self
end

--- Gets whether rewards have been claimed
--- @return boolean claimed True if rewards have been claimed
function QMQuest:GetRewardsClaimed()
    return self.rewardsClaimed
end

--- Sets whether rewards have been claimed
--- @param claimed boolean True if rewards have been claimed
--- @return QMQuest self For chaining
function QMQuest:SetRewardsClaimed(claimed)
    self.rewardsClaimed = claimed or false
    return self
end

--- Gets whether this quest is visible to players
--- @return boolean visible True if players can see this quest
function QMQuest:GetVisibleToPlayers()
    return self.visibleToPlayers
end

--- Sets whether this quest is visible to players
--- @param visible boolean True if players should see this quest
--- @return QMQuest self For chaining
function QMQuest:SetVisibleToPlayers(visible)
    self.visibleToPlayers = visible or false
    return self
end

--- Gets who created this quest
--- @return string createdBy The Codex player ID of the quest creator
function QMQuest:GetCreatedBy()
    return self.createdBy
end

--- Gets when this quest was created
--- @return string|osdate timestamp ISO 8601 UTC timestamp
function QMQuest:GetCreatedTimestamp()
    return self.createdAt
end

--- Gets when this quest was last modified
--- @return string|osdate timestamp ISO 8601 UTC timestamp
function QMQuest:GetModifiedTimestamp()
    return self.modifiedAt
end

--- Set the modified timestamp to the current time
--- @return QMQuest self For chaining
function QMQuest:_setModifiedTimestamp()
    self.modifiedAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
    return self
end

--- Returns the objective matching the key or nil if not found
--- @param objectiveId string The GUID identifier of the objective to return
--- @return QMQuestObjective|nil The objective referenced by the key or nil if it doesn't exist
function QMQuest:GetObjective(objectiveId)
    return self.objectives[objectiveId or ""]
end

--- Gets all objectives for this quest
--- @return table objectives Array of QMQuestObjective instances
function QMQuest:GetObjectives()
    return self.objectives
end

-- Returns the list of objectives sorted by order (lowest to highest)
--- @return table objectives Array of QMQuestObjective instances sorted by order
function QMQuest:GetObjectivesSorted()
    -- Convert hash table to array
    local objectivesArray = {}
    for _, objective in pairs(self.objectives) do
        objectivesArray[#objectivesArray + 1] = objective
    end

    -- Sort the array
    table.sort(objectivesArray, function(a, b)
        return a:GetOrder() < b:GetOrder()
    end)

    return objectivesArray
end

--- Adds a new objective to this quest
--- @return QMQuestObjective objective The newly created objective
function QMQuest:AddObjective()
    local nextOrder = self:_maxObjectiveOrder() + 1
    local objective = QMQuestObjective:new(nextOrder)
    self.objectives[objective:GetID()] = objective
    return objective
end

--- Removes an objective from this quest
--- @param objectiveId string The GUID of the objective to remove
--- @return QMQuest self For chaining
function QMQuest:RemoveObjective(objectiveId)
    print("THC:: QUEST:: REMOVEOBJECTIVE::", objectiveId)
    if self.objectives[objectiveId] then
        print("THC:: REMOVING::")
        self.objectives[objectiveId] = nil
    end
    return self
end

--- Gets all notes for this quest sorted by timestamp (newest first)
--- @return table notes Array of QMQuestNote instances
function QMQuest:GetNotes()
    local notesArray = {}
    for _, note in pairs(self.notes) do
        notesArray [#notesArray+1] = note
    end

    table.sort(notesArray, function(a, b)
        return a:GetCreatedAt() > b:GetCreatedAt()
    end)
    return notesArray
end

--- Adds a new note to this quest
--- @param content string The note content
--- @return QMQuestNote note The newly created note
function QMQuest:AddNote(content)
    local note = QMQuestNote:new(content)
    self.notes[note.id] = note
    return note
end

--- Removes a note from this quest
--- @param noteId string The GUID of the note to remove
--- @return QMQuest self For chaining
function QMQuest:RemoveNote(noteId)
    if self.notes[noteId] then
        self.notes[noteId] = nil
    end
    return self
end

--- Validates if the given status is valid for quests
--- @param status string The status to validate
--- @return boolean valid True if the status is valid
--- @private
function QMQuest:_isValidStatus(status)
    for _, validStatus in pairs(QMQuest.STATUS) do
        if status == validStatus then
            return true
        end
    end
    return false
end

--- Validates if the given category is valid for quests
--- @param category string The category to validate
--- @return boolean valid True if the category is valid
--- @private
function QMQuest:_isValidCategory(category)
    for _, validCategory in pairs(QMQuest.CATEGORY) do
        if category == validCategory then
            return true
        end
    end
    return false
end

--- Validates if the given priority is valid for quests
--- @param priority string The priority to validate
--- @return boolean valid True if the priority is valid
--- @private
function QMQuest:_isValidPriority(priority)
    for _, validPriority in pairs(QMQuest.PRIORITY) do
        if priority == validPriority then
            return true
        end
    end
    return false
end

--- Gets the highest order number among all objectives for this quest
--- @return number maxOrder The highest order number, or 0 if no objectives exist
--- @private
function QMQuest:_maxObjectiveOrder()
    local maxOrder = 0

    for _, objective in pairs(self.objectives) do
        local order = objective:GetOrder()
        if order > maxOrder then
            maxOrder = order
        end
    end

    return maxOrder
end
