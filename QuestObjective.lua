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

--- Gets the title of this objective
--- @return string title The objective's title
function QTQuestObjective:GetTitle()
    return self._manager:GetObjectiveField(self.id, "title") or ""
end

--- Sets the title of this objective
--- @param title string The new title for the objective
function QTQuestObjective:SetTitle(title)
    self._manager:UpdateObjectiveField(self.id, "title", title)
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

--- Gets the order position of this objective within its quest
--- @return number order The order position (starting at 1)
function QTQuestObjective:GetOrder()
    return self._manager:GetObjectiveField(self.id, "order") or 1
end

--- Sets the order position of this objective within its quest
--- @param order number The new order position
function QTQuestObjective:SetOrder(order)
    self._manager:UpdateObjectiveField(self.id, "order", order)
end


--- Sets default properties for a new objective
--- @param properties table Optional properties to override defaults
--- @return table properties The properties with defaults applied
function QTQuestObjective:_applyDefaults(properties)
    local defaults = {
        title = "",
        description = "",
        status = QTQuestObjective.STATUS.NOT_STARTED,
        order = 1,  -- Will be overridden by Quest:AddObjective() with correct value
        createdTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }

    -- Merge provided properties with defaults
    local result = {}
    for key, value in pairs(defaults) do
        result[key] = value
    end
    if properties then
        for key, value in pairs(properties) do
            result[key] = value
        end
    end

    return result
end

--- Updates multiple objective properties in a single document transaction
--- @param properties table Key-value pairs of properties to update
--- @param changeDescription string Optional description for the change
--- @param applyDefaults boolean Whether to apply defaults for new objectives
function QTQuestObjective:UpdateProperties(properties, changeDescription, applyDefaults)
    -- Apply defaults if this is a new objective
    if applyDefaults then
        properties = self:_applyDefaults(properties)
    end

    if properties.status and not self:_isValidStatus(properties.status) then
        properties.status = nil -- Remove invalid status
    end

    -- Always update modified timestamp when updating properties (unless already set by defaults)
    if not applyDefaults then
        properties.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end

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


