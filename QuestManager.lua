--- Central manager for all quest operations. Quests are rows of a data table,
--- so a module can carry them; their notes stay in this game's shared document.
--- @class QMQuestManager
--- @field mod table The Codex mod loading instance
--- @field documentName string The document holding the notes
QMQuestManager = RegisterGameType("QMQuestManager")

local mod = dmhub.GetModLoading()

--- The data table the quests are rows of, which is also the heading the
--- Create Module picker shows them under
QMQuestManager.tableName = "Quests"

local documentName = "QMQuestLog"

--- Built on first use rather than at load, so nothing here depends on where
--- THCCore sits in the load order
local g_library = nil

--- Whether this session has already moved an older document's quests across
local g_migrated = false

--- @return THCLibrary
local function Library()
    if g_library == nil then
        g_library = THCLibrary.CreateNew{
            mod = mod,
            tableName = QMQuestManager.tableName,
            docId = documentName,
            noun = "quest",
            defaultName = "",
            CreateDefinition = function(name)
                return QMQuest.CreateNew():SetTitle(name)
            end,
        }
    end
    return g_library
end

--- Creates a new quest manager instance
--- @return QMQuestManager instance The new quest manager instance
function QMQuestManager.CreateNew()
    return QMQuestManager.new{
        mod = mod,
        documentName = documentName,
    }
end

--- Initializes the notes document with the default structure
--- forcing the initialization
--- WANRING!!! All data will be lost!
--- @return table doc The initialized document
function QMQuestManager:InitializeDocument()
    local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local doc = self.mod:GetDocumentSnapshot(self.documentName)
    doc:BeginChange()
    doc.data = {
        quests = {},
        notes = {},
        migrated = true,
        metadata = {
            campaignName = dmhub.gameid,
            version = 2,
            createdTimestamp = timestamp,
            modifiedTimestamp = timestamp
        }
    }
    doc:CompleteChange("Initialize quest log", {undoable = true})
    return doc
end

--- Quests authored before the table existed sit in the document. The first
--- Director to read them moves each across minus its notes, files the notes
--- under the quest's id, and stamps the document so it never runs again.
--- Rows go up first: a crash before the stamp re-uploads identical rows.
function QMQuestManager:_migrate()
    if g_migrated or not dmhub.isDM then
        return
    end
    g_migrated = true

    local doc = self:_safeDoc()
    if doc == nil or doc.data.migrated then
        return
    end

    local notes = doc.data.notes or {}
    for questId, quest in pairs(doc.data.quests) do
        local row = DeepCopy(quest)
        notes[questId] = row.notes or {}
        row.notes = nil
        row.name = row.title or ""
        dmhub.SetAndUploadTableItem(QMQuestManager.tableName, row)
    end

    doc:BeginChange()
    doc.data.notes = notes
    doc.data.quests = {}
    doc.data.migrated = true
    if doc.data.metadata then
        doc.data.metadata.version = 2
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
    doc:CompleteChange("Move quests to table", {undoable = false})
end

--- Creates and stores a quest in the table then returns it
--- @return QMQuest|nil quest The newly created quest or nil if we can't create or store one
function QMQuestManager:CreateQuest()
    self:_migrate()
    local quest = QMQuest.CreateNew()
    local library = Library()
    library:Mutate("Create quest", function(defs)
        quest:_setModifiedTimestamp()
        defs[quest:GetID()] = quest
        quest.slug = library:UniqueSlug(defs, quest:GetID(), quest.name)
    end)
    return self:GetQuest(quest:GetID())
end

--- Gets a quest by its ID with visibility checks applied
--- @param questId string The GUID of the quest
--- @return QMQuest|nil instance The quest instance or nil if not found or not visible
function QMQuestManager:GetQuest(questId)
    self:_migrate()
    local quest = Library():GetByID(questId)
    if quest ~= nil and QMQuestManager._questVisibleToUser(quest) then
        return quest
    end
    return nil
end

--- Gets a quest by its name (case insensitive) with visibility checks applied
--- @param questTitle string The name of the quest to find
--- @return QMQuest|nil instance The quest instance or nil if not found or not visible
function QMQuestManager:GetQuestByTitle(questTitle)
    if questTitle == nil then
        return nil
    end
    local lowerName = string.lower(questTitle)
    for _, quest in pairs(self:GetAllQuests()) do
        if string.lower(quest:GetTitle() or "") == lowerName then
            return quest
        end
    end
    return nil
end

--- Return the timestamp the quest was last modified or nil if not found
--- @param questId string The GUID identifier of the quest to evaluate
--- @return string|osdate|nil lastModified The timestampe the quest was last modified or nil of not found
function QMQuestManager:GetQuestLastModified(questId)
    local quest = self:GetQuest(questId)
    if quest ~= nil then
        return quest:GetModifiedTimestamp()
    end
    return nil
end

--- Changes a quest as one step. The callback gets the live row, and only a
--- row whose content moved is uploaded.
--- @param questId string The GUID of the quest
--- @param fn fun(quest: QMQuest) The change to make
function QMQuestManager:UpdateQuest(questId, fn)
    Library():Mutate("Update quest", function(defs)
        local quest = defs[questId]
        if quest == nil then
            return
        end
        local before = json(quest)
        fn(quest)
        if json(quest) ~= before then
            quest:_setModifiedTimestamp()
        end
    end)
end

--- Deletes a quest and its notes
--- @param questId string The GUID of the quest to delete
function QMQuestManager:DeleteQuest(questId)
    Library():Delete(questId)

    local doc = self:_safeDoc()
    if doc and doc.data.notes and doc.data.notes[questId] then
        doc:BeginChange()
        doc.data.notes[questId] = nil
        doc:CompleteChange("Delete quest notes", {undoable = false})
    end
end

--- Gets all quests visible to the current user
--- @return table quests Hash table of QMQuest instances keyed by id
--- @return number questCount Number of quests in the hash table
function QMQuestManager:GetAllQuests()
    self:_migrate()
    local quests = {}
    local questCount = 0

    for _, quest in ipairs(Library():GetAll()) do
        if QMQuestManager._questVisibleToUser(quest) then
            quests[quest:GetID()] = quest
            questCount = questCount + 1
        end
    end

    return quests, questCount
end

--- Gets a quest's notes, newest first
--- @param questId string The GUID of the quest
--- @return table notes Array of QMQuestNote instances
function QMQuestManager:GetNotes(questId)
    local notesArray = {}

    local doc = self:_safeDoc()
    local notes = doc and doc.data.notes and doc.data.notes[questId] or nil
    if notes ~= nil then
        for _, note in pairs(notes) do
            notesArray[#notesArray + 1] = note
        end
    end

    table.sort(notesArray, function(a, b)
        return a:GetCreatedAt() > b:GetCreatedAt()
    end)
    return notesArray
end

--- Adds a note to a quest
--- @param questId string The GUID of the quest
--- @param content string The note content
--- @return QMQuestNote|nil note The new note, or nil without a document
function QMQuestManager:AddNote(questId, content)
    local doc = self:_safeDoc()
    if doc == nil then
        return nil
    end

    local note = QMQuestNote.CreateNew(content)
    doc:BeginChange()
    doc.data.notes = doc.data.notes or {}
    doc.data.notes[questId] = doc.data.notes[questId] or {}
    doc.data.notes[questId][note:GetID()] = note
    self:_touchDocument(doc)
    doc:CompleteChange("Add quest note", {undoable = false})
    return note
end

--- Removes a note from a quest
--- @param questId string The GUID of the quest
--- @param noteId string The GUID of the note
function QMQuestManager:RemoveNote(questId, noteId)
    local doc = self:_safeDoc()
    local notes = doc and doc.data.notes and doc.data.notes[questId] or nil
    if notes == nil or notes[noteId] == nil then
        return
    end

    doc:BeginChange()
    notes[noteId] = nil
    self:_touchDocument(doc)
    doc:CompleteChange("Remove quest note", {undoable = false})
end

--- Stamps the document's modified time inside an open change
--- @param doc table The document snapshot
function QMQuestManager:_touchDocument(doc)
    if doc.data.metadata then
        doc.data.metadata.modifiedTimestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
end

--- Initializes the notes document with default structure
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

--- Gets the path for document monitoring in UI. Notes live here; quest rows
--- are table data, watched with monitorAssets.
--- @return string path The document path for monitoring
function QMQuestManager:GetDocumentPath()
    return self.mod:GetDocumentSnapshot(self.documentName).path
end
