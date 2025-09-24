--- Individual objective within a quest with status tracking and notes
--- Supports the same status progression as quests with player and director notes
--- @class QMQuestObjective
--- @field id string GUID identifier for this objective 
--- @field order number The sort order for this objective
--- @field title string The title of this objective
--- @field description string The description of this objective
--- @field status string The status of this objective
--- @field createdBy string GUID identifier of the user who created this objective
--- @field createdAt string|osdate The ISO 8601 UTC timestamp
QMQuestObjective = RegisterGameType("QMQuestObjective")
QMQuestObjective.__index = QMQuestObjective

--- Valid status values for quest objectives
QMQuestObjective.STATUS = {
    NOT_STARTED = "Not Started",
    ACTIVE = "Active",
    COMPLETED = "Completed",
    FAILED = "Failed",
    ON_HOLD = "On Hold"
}

--- Creates a new quest objective instance
--- @param sortOrder number The sort order for this note
--- @return QMQuestObjective instance The new objective instance
function QMQuestObjective:new(sortOrder)
    local instance = setmetatable({}, self)
    instance.id = dmhub.GenerateGuid()
    instance.order = sortOrder
    instance.title = ""
    instance.description = ""
    instance.status = QMQuestObjective.STATUS.NOT_STARTED
    instance.createdBy = dmhub.userid
    instance.createdAt = os.date("!%Y-%m-%dT%H:%M:%SZ")
    return instance
end

--- Gets the unique identifier for this objective
--- @return string id The unique identifier for this objective
function QMQuestObjective:GetID()
    return self.id
end

--- Gets the description text of this objective
--- @return string description The objective's description
function QMQuestObjective:GetDescription()
    return self.description
end

--- Sets the description text of this objective
--- @param description string The new description for the objective
--- @return QMQuestObjective self For chaining
function QMQuestObjective:SetDescription(description)
    self.description = description or ""
    return self
end

--- Gets the order position of this objective within its quest
--- @return number order The order position (starting at 1)
function QMQuestObjective:GetOrder()
    return self.order
end

--- Sets the order position of this objective within its quest
--- @param order number The new order position
--- @return QMQuestObjective self For chaining
function QMQuestObjective:SetOrder(order)
    self.order = order
    return self
end

--- Gets the current status of this objective
--- @return string status One of QMQuestObjective.STATUS values
function QMQuestObjective:GetStatus()
    return self.status
end

--- Sets the status of this objective
--- @param status string One of QMQuestObjective.STATUS values
--- @return QMQuestObjective self For chaining
function QMQuestObjective:SetStatus(status)
    if self:_isValidStatus(status) then
        self.status = status
    end
    return self
end

--- Gets the title of this objective
--- @return string title The objective's title
function QMQuestObjective:GetTitle()
    return self.title
end

--- Sets the title of this objective
--- @param title string The new title for the objective
--- @return QMQuestObjective self For chaining
function QMQuestObjective:SetTitle(title)
    self.title = title or ""
    return self
end

--- Gets the user ID who created the objective
--- @return string createdBy The GUID id of the objective's creator
function QMQuestObjective:GetCreatedBy()
    return self.createdBy
end

--- Gets the timestamp when this objective was created
--- @return string|osdate timestamp ISO 8601 UTC timestamp
function QMQuestObjective:GetCreatedTimestamp()
    return self.createdAt
end

--- Validates if the given status is valid for objectives
--- @param status string The status to validate
--- @return boolean valid True if the status is valid
function QMQuestObjective:_isValidStatus(status)
    for _, validStatus in pairs(QMQuestObjective.STATUS) do
        if status == validStatus then
            return true
        end
    end
    return false
end
