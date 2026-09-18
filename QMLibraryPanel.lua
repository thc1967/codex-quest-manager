local mod = dmhub.GetModLoading()

--- The list of quests down the left of the Quest Manager window, filed under
--- the five fixed categories. Rows carry status and priority glyphs, the
--- player-visibility eye, the editing lock and a menu; a quest dragged onto a
--- folder moves there. Rows are built once and rebound, never rebuilt.
--- @class QMLibraryPanel
QMLibraryPanel = RegisterGameType("QMLibraryPanel")

--- Folder headers advertise themselves as drop targets with one class
local DROP_CLASS = "qmDropTarget"

--- The class the panel root wears so a row can find its controller
local ROOT_CLASS = "qmLibrary"

--- @param category string One of QMQuest.CATEGORY values
--- @return string prefKey Per-client key holding the folder's expanded state
local function FolderPrefKey(category)
    return string.format("questcategory:%s:%s", category, dmhub.gameid or "default")
end

--- Folders open unless this client closed them
--- @param category string
--- @return boolean expanded
local function FolderExpanded(category)
    return dmhub.GetPref(FolderPrefKey(category)) ~= false
end

--- A glyph with a placeholder icon; the bind dresses it
--- @return table panel
local function Glyph()
    return gui.Panel{
        width = QMConstants.rowIconSize,
        height = QMConstants.rowIconSize,
        halign = "left",
        valign = "center",
        lmargin = 4,
        bgimage = QMConstants.statusIcon[QMQuest.STATUS.NOT_STARTED],
    }
end

--- The standard delete confirmation, raised from a menu entry rather than a
--- delete button so it reads the same as every other delete in the app.
--- @param element table The panel that owns the modal
--- @param questTitle string
--- @param onDelete fun()
local function ConfirmDelete(element, questTitle, onDelete)
    gui.ModalMessage{
        owner = element,
        title = "Delete Quest",
        message = string.format("Delete \"%s\"? Its objectives and notes go with it.", questTitle),
        options = {
            {
                text = "Cancel",
                execute = function()
                    gui.CloseModal(element)
                end,
            },
            {
                text = "Delete",
                execute = function()
                    gui.CloseModal(element)
                    onDelete()
                end,
            },
        },
    }
end

--- A quest's row. Built once and handed a quest with `setQuest`; handed nil,
--- it collapses and waits. Stripe and selection are classes the bind toggles.
--- @param qm QMQuestManager
--- @param onSelect fun(questId: string)
--- @return table panel
local function CreateRow(qm, onSelect)
    --- @type {questId: string|nil, title: string|nil, category: string|nil, canEdit: boolean|nil}
    local bound = {}
    local statusState = {}
    local priorityState = {}

    --- Writes one field of the live quest
    --- @param fn fun(live: QMQuest)
    local function UpdateQuest(fn)
        if bound.questId == nil then
            return
        end
        local live = qm:GetQuest(bound.questId)
        if live == nil then
            return
        end
        qm:ExecuteUpdateFn(function()
            fn(live)
        end)
    end

    local statusGlyph = Glyph()
    local priorityGlyph = Glyph()

    local titleLabel = gui.Label{
        classes = {"sizeS"},
        width = "100% available",
        height = "auto",
        lmargin = 8,
        halign = "left",
        valign = "center",
        text = "",
    }

    local eye = QMUIUtils.EyeToggle{
        shown = false,
        size = QMConstants.rowIconSize,
        change = function(shown)
            UpdateQuest(function(live)
                live:SetVisibleToPlayers(shown)
            end)
        end,
    }

    local lock = QMUIUtils.LockToggle{
        unlocked = false,
        size = QMConstants.rowIconSize,
        change = function(unlocked)
            UpdateQuest(function(live)
                live:SetPlayersMayEdit(unlocked)
            end)
        end,
    }

    local gear = gui.Button{
        classes = {"sizeXs"},
        icon = QMConstants.iconGear,
        halign = "right",
        valign = "center",
        hmargin = 4,
        hover = THCWidgets.Tooltip("More"),
        click = function(element)
            local questId = bound.questId
            if questId == nil then
                return
            end

            local entries = {
                {
                    text = "Copy ID",
                    click = function()
                        element.popup = nil
                        dmhub.CopyToClipboard(questId)
                    end,
                },
            }

            if bound.canEdit then
                entries[#entries + 1] = {
                    text = "Delete",
                    click = function()
                        element.popup = nil
                        ConfirmDelete(element, bound.title or "", function()
                            qm:DeleteQuest(questId)
                        end)
                    end,
                }
            end

            element.popup = gui.ContextMenu{ entries = entries }
        end,
    }

    return gui.Panel{
        classes = {"row", "hoverable"},
        width = "100%",
        height = QMConstants.rowHeight,
        flow = "horizontal",
        halign = "left",
        valign = "top",

        --A drag by someone who may not edit finds no target, so it drops nowhere
        draggable = true,
        canDragOnto = function(element, target)
            return bound.canEdit == true and target ~= nil and target:HasClass(DROP_CLASS)
        end,
        drag = function(element, target)
            if target == nil or target.data.category == bound.category then
                return
            end
            UpdateQuest(function(live)
                live:SetCategory(target.data.category)
            end)
        end,

        click = function()
            if bound.questId ~= nil then
                onSelect(bound.questId)
            end
        end,

        --- @param item nil|{quest: QMQuest, index: number, selected: boolean}
        setQuest = function(element, item)
            element:SetClass("collapsed", item == nil)
            if item == nil then
                return
            end

            local quest = item.quest
            bound.questId = quest:GetID()
            bound.canEdit = quest:CanUserEdit()
            bound.category = quest:GetCategory()

            element:SetClass("oddRow", item.index % 2 == 1)
            element:SetClass("evenRow", item.index % 2 == 0)
            element:SetClass("selected", item.selected)

            local status = quest:GetStatus() or QMQuest.STATUS.NOT_STARTED
            local priority = quest:GetPriority() or QMQuest.PRIORITY.MEDIUM
            QMUIUtils.BindGlyph(statusGlyph, statusState,
                QMConstants.statusIcon[status], QMConstants.statusTone[status] or "bgFgMuted", status)
            QMUIUtils.BindGlyph(priorityGlyph, priorityState,
                QMConstants.priorityIcon[priority], QMConstants.priorityTone[priority] or "bgFgMuted",
                priority .. " priority")

            local title = quest:GetTitle() or ""
            local untitled = trim(title) == ""
            if untitled then
                title = "(New Quest)"
            end
            if bound.title ~= title then
                bound.title = title
                titleLabel.text = title
            end
            titleLabel:SetClass("fgMuted", untitled or QMConstants.resolvedStatuses[status] == true)

            --Editors get the eye and the lock. A player who cannot edit sees
            --neither: every quest they can see is visible, and locked to them.
            eye:SetClass("collapsed", not bound.canEdit)
            lock:SetClass("collapsed", not bound.canEdit)
            eye:FireEvent("setState", quest:GetVisibleToPlayers())
            lock:FireEvent("setState", quest:GetPlayersMayEdit())
        end,

        statusGlyph,
        priorityGlyph,
        titleLabel,
        eye,
        lock,
        gear,
    }
end

--- A category's folder: its header, with the name, how many quests it holds
--- and the drop target that files them into it, over the rows of those quests.
--- Built once per category and handed its rows with `setFolder`. Folders are
--- the fixed categories, so there is nothing here to rename or delete.
--- @param qm QMQuestManager
--- @param category string One of QMQuest.CATEGORY values
--- @param onSelect fun(questId: string)
--- @param onRebuild fun()
--- @return table panel
local function CreateFolderBlock(qm, category, onSelect, onRebuild)
    --- @type {count: string|nil}
    local bound = {}

    local rows = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        valign = "top",
    }

    --No classes key: an empty list wipes ExpandoArrow's own theme classes
    local arrow = gui.ExpandoArrow{
        click = function(element)
            local nowExpanded = not element:HasClass("expanded")
            element:SetClass("expanded", nowExpanded)
            dmhub.SetPref(FolderPrefKey(category), nowExpanded)
            onRebuild()
        end,
    }

    local countLabel = gui.Label{
        classes = {"sizeXs", "noBold", "fgMuted"},
        width = "auto",
        height = "auto",
        halign = "right",
        valign = "center",
        rmargin = 8,
        text = "0",
    }

    local header = gui.Panel{
        classes = {DROP_CLASS},
        width = "100%",
        height = QMConstants.folderHeaderHeight,
        flow = "horizontal",
        valign = "top",
        tmargin = 6,
        bgimage = "panels/square.png",
        dragTarget = true,

        data = { category = category },

        arrow,

        gui.Label{
            classes = {"tableLabel", "sizeXs"},
            width = "100% available",
            height = "auto",
            halign = "left",
            valign = "center",
            lmargin = 4,
            text = category,
        },

        countLabel,
    }

    return gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        valign = "top",

        --- @param items table[] {quest: QMQuest, index: number, selected: boolean} in display order
        setFolder = function(element, items)
            local count = tostring(#items)
            if bound.count ~= count then
                bound.count = count
                countLabel.text = count
            end

            local expanded = FolderExpanded(category)
            arrow:SetClass("expanded", expanded)
            rows:SetClass("collapsed", not expanded)

            --Folded rows stay bound, so an unfold is instant
            THCWidgets.BindList(rows, items, function()
                return CreateRow(qm, onSelect)
            end, "setQuest")
        end,

        header,
        rows,
    }
end

--- Live work first, then alphabetical
--- @param quests table Array of QMQuest
local function SortQuests(quests)
    table.sort(quests, function(a, b)
        local rankA = QMConstants.statusSortRank[a:GetStatus()] or 99
        local rankB = QMConstants.statusSortRank[b:GetStatus()] or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return string.lower(a:GetTitle() or "") < string.lower(b:GetTitle() or "")
    end)
end

--- Creates the list pane
--- @param qm QMQuestManager The quest manager for document operations
--- @param onSelect fun(questId: string|nil) Called when the selection changes
--- @return table panel The library panel
function QMLibraryPanel.Create(qm, onSelect)
    local m_selected = nil

    local resultPanel

    local function Select(questId)
        resultPanel:FireEvent("select", questId)
    end

    local function Rebuild()
        resultPanel:FireEvent("rebuild")
    end

    local blocks = {}
    local blockPanels = {}
    for _, category in ipairs(QMConstants.categoryOrder) do
        blocks[category] = CreateFolderBlock(qm, category, Select, Rebuild)
        blockPanels[#blockPanels + 1] = blocks[category]
    end

    --The only scroller in this column is the bordered box itself, so the bar
    --rides the list's own right edge.
    local listPanel = gui.Panel{
        classes = {"bordered"},
        pad = 4,
        width = "100%",
        height = "100%-44",
        flow = "vertical",
        valign = "top",
        vscroll = true,
        children = blockPanels,
    }

    resultPanel = gui.Panel{
        classes = {ROOT_CLASS},
        width = "100%",
        height = "100%",
        flow = "vertical",
        valign = "top",

        --- Select a quest and tell the editor about it
        select = function(element, questId)
            m_selected = questId
            onSelect(questId)
            element:FireEvent("rebuild")
        end,

        questsChanged = function(element)
            element:FireEvent("rebuild")
        end,

        rebuild = function()
            local quests = qm:GetAllQuests()

            --The selection can vanish under us: deleted here or elsewhere, or
            --hidden from this player by the Director.
            if m_selected ~= nil and qm:GetQuest(m_selected) == nil then
                m_selected = nil
                onSelect(nil)
            end

            local byCategory = {}
            for _, quest in pairs(quests) do
                local category = quest:GetCategory() or QMQuest.CATEGORY.MAIN
                byCategory[category] = byCategory[category] or {}
                local bucket = byCategory[category]
                bucket[#bucket + 1] = quest
            end

            --Only visible rows take a stripe; folded ones stay bound for the unfold
            local index = 0
            for _, category in ipairs(QMConstants.categoryOrder) do
                local bucket = byCategory[category] or {}
                SortQuests(bucket)

                local expanded = FolderExpanded(category)
                local items = {}
                for _, quest in ipairs(bucket) do
                    if expanded then
                        index = index + 1
                    end
                    items[#items + 1] = {
                        quest = quest,
                        index = index,
                        selected = quest:GetID() == m_selected,
                    }
                end

                blocks[category]:FireEvent("setFolder", items)
            end
        end,

        create = function(element)
            element:FireEvent("rebuild")
        end,

        listPanel,

        gui.Panel{
            width = "100%",
            height = 40,
            flow = "horizontal",
            valign = "bottom",

            gui.Button{
                classes = {"addButton", "sizeS"},
                halign = "right",
                valign = "center",
                hover = THCWidgets.Tooltip("Add a quest"),
                click = function()
                    local quest = qm:CreateQuest()
                    if quest ~= nil then
                        Select(quest:GetID())
                    end
                end,
            },
        },
    }

    return resultPanel
end
