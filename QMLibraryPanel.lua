local mod = dmhub.GetModLoading()

--- The list of quests down the left of the Quest Manager window, filed under
--- the five fixed categories. Rows carry status and priority glyphs, the
--- player-visibility eye, and a menu; a quest dragged onto a folder moves there.
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

--- @param icon string
--- @param tone string A bg* tint class
--- @param tooltip string
--- @return table panel A tinted glyph
local function Glyph(icon, tone, tooltip)
    return gui.Panel{
        classes = { tone },
        width = QMConstants.rowIconSize,
        height = QMConstants.rowIconSize,
        halign = "left",
        valign = "center",
        lmargin = 4,
        bgimage = icon,
        hover = THCWidgets.Tooltip(tooltip),
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

--- @param qm QMQuestManager
--- @param quest QMQuest
--- @param index number Position in the list, for row striping
--- @param selectedId string|nil
--- @param onSelect fun(questId: string)
--- @return table panel
local function CreateRow(qm, quest, index, selectedId, onSelect)
    local questId = quest:GetID()
    local canEdit = quest:CanUserEdit()
    local status = quest:GetStatus() or QMQuest.STATUS.NOT_STARTED
    local priority = quest:GetPriority() or QMQuest.PRIORITY.MEDIUM

    local title = quest:GetTitle() or ""
    local untitled = trim(title) == ""
    if untitled then
        title = "(New Quest)"
    end

    local titleClasses = {"sizeS"}
    if untitled or QMConstants.resolvedStatuses[status] then
        titleClasses[#titleClasses + 1] = "fgMuted"
    end

    local children = {
        Glyph(QMConstants.statusIcon[status], QMConstants.statusTone[status] or "bgFgMuted", status),
        Glyph(QMConstants.priorityIcon[priority], QMConstants.priorityTone[priority] or "bgFgMuted",
            priority .. " priority"),

        gui.Label{
            classes = titleClasses,
            width = "100% available",
            height = "auto",
            lmargin = 8,
            halign = "left",
            valign = "center",
            text = title,
        },
    }

    --- Writes one field of the live quest
    --- @param fn fun(live: QMQuest)
    local function UpdateQuest(fn)
        local live = qm:GetQuest(questId)
        if live == nil then
            return
        end
        qm:ExecuteUpdateFn(function()
            fn(live)
        end)
    end

    --Editors get the eye and the lock. A player who cannot edit sees neither:
    --every quest they can see is visible by definition, and locked to them.
    if canEdit then
        children[#children + 1] = QMUIUtils.EyeToggle{
            shown = quest:GetVisibleToPlayers(),
            size = QMConstants.rowIconSize,
            change = function(shown)
                UpdateQuest(function(live)
                    live:SetVisibleToPlayers(shown)
                end)
            end,
        }

        children[#children + 1] = QMUIUtils.LockToggle{
            unlocked = quest:GetPlayersMayEdit(),
            size = QMConstants.rowIconSize,
            change = function(unlocked)
                UpdateQuest(function(live)
                    live:SetPlayersMayEdit(unlocked)
                end)
            end,
        }
    end

    children[#children + 1] = gui.Button{
        classes = {"sizeXs"},
        icon = QMConstants.iconGear,
        halign = "right",
        valign = "center",
        hmargin = 4,
        hover = THCWidgets.Tooltip("More"),
        click = function(element)
            local entries = {
                {
                    text = "Copy ID",
                    click = function()
                        element.popup = nil
                        dmhub.CopyToClipboard(questId)
                    end,
                },
            }

            if canEdit then
                entries[#entries + 1] = {
                    text = "Delete",
                    click = function()
                        element.popup = nil
                        ConfirmDelete(element, title, function()
                            qm:DeleteQuest(questId)
                        end)
                    end,
                }
            end

            element.popup = gui.ContextMenu{ entries = entries }
        end,
    }

    return gui.Panel{
        classes = {
            "row",
            "hoverable",
            cond(index % 2 == 1, "oddRow", "evenRow"),
            cond(questId == selectedId, "selected"),
        },
        width = "100%",
        height = QMConstants.rowHeight,
        flow = "horizontal",
        halign = "left",
        valign = "top",

        draggable = canEdit,
        canDragOnto = function(element, target)
            return target ~= nil and target:HasClass(DROP_CLASS)
        end,
        drag = function(element, target)
            if target == nil or target.data.category == quest:GetCategory() then
                return
            end
            local live = qm:GetQuest(questId)
            if live == nil then
                return
            end
            qm:ExecuteUpdateFn(function()
                live:SetCategory(target.data.category)
            end)
        end,

        click = function()
            onSelect(questId)
        end,

        children = children,
    }
end

--- A folder's header: its name, how many quests it holds, and the drop target
--- that files a quest into it. Folders are the fixed categories, so there is
--- nothing here to rename or delete.
--- @param category string One of QMQuest.CATEGORY values
--- @param count number
--- @param onRebuild fun()
--- @return table panel
local function CreateFolderHeader(category, count, onRebuild)
    local prefKey = FolderPrefKey(category)

    local arrowArgs = {}
    if FolderExpanded(category) then
        arrowArgs.classes = {"expanded"}
    end
    arrowArgs.click = function(element)
        local nowExpanded = not element:HasClass("expanded")
        element:SetClass("expanded", nowExpanded)
        dmhub.SetPref(prefKey, nowExpanded)
        onRebuild()
    end

    return gui.Panel{
        classes = {DROP_CLASS},
        width = "100%",
        height = QMConstants.folderHeaderHeight,
        flow = "horizontal",
        valign = "top",
        tmargin = 6,
        bgimage = "panels/square.png",
        dragTarget = true,

        data = { category = category },

        gui.ExpandoArrow(arrowArgs),

        gui.Label{
            classes = {"tableLabel", "sizeXs"},
            width = "100% available",
            height = "auto",
            halign = "left",
            valign = "center",
            lmargin = 4,
            text = category,
        },

        gui.Label{
            classes = {"sizeXs", "noBold", "fgMuted"},
            width = "auto",
            height = "auto",
            halign = "right",
            valign = "center",
            rmargin = 8,
            text = tostring(count),
        },
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
    }

    local resultPanel
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

        rebuild = function(element)
            local quests = qm:GetAllQuests()

            --The selection can vanish under us: deleted here or elsewhere, or
            --hidden from this player by the Director.
            if m_selected ~= nil and qm:GetQuest(m_selected) == nil then
                m_selected = nil
                onSelect(nil)
            end

            local function Select(questId)
                element:FireEvent("select", questId)
            end
            local function Rebuild()
                element:FireEvent("rebuild")
            end

            local byCategory = {}
            for _, quest in pairs(quests) do
                local category = quest:GetCategory() or QMQuest.CATEGORY.MAIN
                byCategory[category] = byCategory[category] or {}
                local bucket = byCategory[category]
                bucket[#bucket + 1] = quest
            end

            local children = {}
            local index = 0

            for _, category in ipairs(QMConstants.categoryOrder) do
                local bucket = byCategory[category] or {}
                SortQuests(bucket)

                children[#children + 1] = CreateFolderHeader(category, #bucket, Rebuild)

                if FolderExpanded(category) then
                    for _, quest in ipairs(bucket) do
                        index = index + 1
                        children[#children + 1] = CreateRow(qm, quest, index, m_selected, Select)
                    end
                end
            end

            listPanel.children = children
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
                click = function(element)
                    local quest = qm:CreateQuest()
                    if quest == nil then
                        return
                    end
                    local controller = element:FindParentWithClass(ROOT_CLASS)
                    if controller ~= nil then
                        controller:FireEvent("select", quest:GetID())
                    end
                end,
            },
        },
    }

    return resultPanel
end
