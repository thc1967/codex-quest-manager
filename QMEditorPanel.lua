local mod = dmhub.GetModLoading()

--- The right pane of the Quest Manager window: the selected quest's form, its
--- objectives and its notes. Whoever may edit the quest gets controls; anyone
--- else gets the same information as text, and can still add a note. Rows are
--- built once and rebound, never rebuilt.
--- @class QMEditorPanel
QMEditorPanel = RegisterGameType("QMEditorPanel")

--- The class an objective's drag handle wears so a drop can find another handle
local HANDLE_CLASS = "qmObjectiveHandle"

--- Indent of an objective's description, so it lines up under the title input
local OBJECTIVE_INDENT = QMConstants.objectiveDragHandleSize + QMConstants.objectiveIconSize + 12

--- @param values table Ordered list of strings
--- @return table options Dropdown options in that order
local function DropdownOptions(values)
    local options = {}
    for _, value in ipairs(values) do
        options[#options + 1] = { id = value, text = value }
    end
    return options
end

--- @param timestamp string|nil ISO 8601 UTC timestamp
--- @return string display The timestamp as date and time
local function DisplayTimestamp(timestamp)
    if timestamp == nil or timestamp == "" then
        return ""
    end
    return (timestamp:gsub("T", " "):gsub("Z", ""):gsub("%-", "/"))
end

--- An objective's status glyph with a placeholder icon; the bind dresses it
--- @return table panel
local function StatusGlyph()
    return gui.Panel{
        width = QMConstants.objectiveIconSize,
        height = QMConstants.objectiveIconSize,
        halign = "left",
        valign = "center",
        rmargin = 4,
        bgimage = QMConstants.statusIcon[QMQuest.STATUS.NOT_STARTED],
    }
end

--- Dresses an objective's status glyph
--- @param glyph table
--- @param state table The glyph's own memory between binds
--- @param status string One of QMQuestObjective.STATUS values
local function BindStatusGlyph(glyph, state, status)
    QMUIUtils.BindGlyph(glyph, state,
        QMConstants.statusIcon[status] or QMConstants.statusIcon[QMQuest.STATUS.NOT_STARTED],
        QMConstants.statusTone[status] or "bgFgMuted", status)
end

--- A label-over-text pair for the read-only form, refilled through the value label
--- @param labelText string
--- @param width string
--- @param lmargin number|nil Overrides the theme's row margin; 0 for a column inside a group
--- @return table row The row panel
--- @return table value The label the bind writes into
local function ReadField(labelText, width, lmargin)
    local value = gui.Label{
        classes = {"sizeS", "noBold"},
        width = "98%",
        height = "auto",
        halign = "left",
        textAlignment = "topLeft",
        textWrap = true,
        text = "",
    }

    local row = gui.Panel{
        classes = {"formStackedRow"},
        width = width,
        lmargin = lmargin,
        children = {
            gui.Label{
                classes = {"formStacked", "sizeS"},
                text = labelText,
            },
            value,
        },
    }

    return row, value
end

--- @param text string
--- @return table panel A muted "nothing here" line
local function EmptyLine(text)
    return gui.Label{
        classes = {"sizeXs", "noBold", "fgMuted"},
        width = "100%",
        height = "auto",
        halign = "left",
        valign = "top",
        vmargin = 8,
        textAlignment = "left",
        text = text,
    }
end

--- Creates the editor pane
--- @param qm QMQuestManager The quest manager for document operations
--- @return table panel The editor panel
function QMEditorPanel.Create(qm)
    local m_questId = nil

    --- @return QMQuest|nil quest The selected quest, live from the document
    local function Live()
        if m_questId == nil then
            return nil
        end
        return qm:GetQuest(m_questId)
    end

    --- Runs a write against the live quest inside a document change
    --- @param fn fun(quest: QMQuest)
    local function Update(fn)
        local quest = Live()
        if quest == nil then
            return
        end
        qm:ExecuteUpdateFn(function()
            fn(quest)
        end)
    end

    --- Text field write that skips the change when nothing changed
    --- @param getter fun(quest: QMQuest): string
    --- @param setter fun(quest: QMQuest, value: string)
    --- @return fun(element: table)
    local function TextChange(getter, setter)
        return function(element)
            local quest = Live()
            if quest == nil or getter(quest) == element.text then
                return
            end
            Update(function(live)
                setter(live, element.text)
            end)
        end
    end

    --- Dropdown write that skips the change when nothing changed
    --- @param getter fun(quest: QMQuest): string
    --- @param setter fun(quest: QMQuest, value: string)
    --- @return fun(element: table)
    local function ChoiceChange(getter, setter)
        return function(element)
            local quest = Live()
            if quest == nil or getter(quest) == element.idChosen then
                return
            end
            Update(function(live)
                setter(live, element.idChosen)
            end)
        end
    end

    -- Quest form, built once and refilled

    local titleInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        placeholderText = "Quest title",
        change = TextChange(QMQuest.GetTitle, QMQuest.SetTitle),
    }

    local categoryDropdown = gui.Dropdown{
        classes = {"formStacked", "sizeS"},
        width = QMConstants.choiceWidth,
        height = 26,
        options = DropdownOptions(QMConstants.categoryOrder),
        change = ChoiceChange(QMQuest.GetCategory, QMQuest.SetCategory),
    }

    local priorityDropdown = gui.Dropdown{
        classes = {"formStacked", "sizeS"},
        width = QMConstants.choiceWidth,
        height = 26,
        options = DropdownOptions(QMConstants.priorityOrder),
        change = ChoiceChange(QMQuest.GetPriority, QMQuest.SetPriority),
    }

    local statusDropdown = gui.Dropdown{
        classes = {"formStacked", "sizeS"},
        width = QMConstants.choiceWidth,
        height = 26,
        options = DropdownOptions(QMConstants.statusOrder),
        change = ChoiceChange(QMQuest.GetStatus, QMQuest.SetStatus),
    }

    local questGiverInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        width = QMConstants.shortInputWidth,
        placeholderText = "Who gave this quest?",
        change = TextChange(QMQuest.GetQuestGiver, QMQuest.SetQuestGiver),
    }

    local locationInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        width = QMConstants.shortInputWidth,
        placeholderText = "Where does this quest take place?",
        change = TextChange(QMQuest.GetLocation, QMQuest.SetLocation),
    }

    local rewardsInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        placeholderText = "What does this quest offer?",
        change = TextChange(QMQuest.GetRewards, QMQuest.SetRewards),
    }

    --Labelled by its form row, so the box itself carries no text
    local rewardsClaimedCheck = gui.Check{
        classes = {"sizeS"},
        text = "",
        value = false,
        height = 30,
        halign = "left",
        valign = "center",
        change = function(element)
            local quest = Live()
            if quest == nil or quest:GetRewardsClaimed() == element.value then
                return
            end
            Update(function(live)
                live:SetRewardsClaimed(element.value)
            end)
        end,
    }

    local descriptionInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        height = QMConstants.descriptionHeight,
        multiline = true,
        textAlignment = "topLeft",
        characterLimit = QMConstants.characterLimit,
        placeholderText = "What this quest is about.",
        change = TextChange(QMQuest.GetDescription, QMQuest.SetDescription),
    }

    local formPanel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",

        QMUIUtils.FormRow("Title", QMConstants.formRowWidth, titleInput),

        QMUIUtils.FormColumns{
            QMUIUtils.FormRow("Category", "33%", categoryDropdown, 0),
            QMUIUtils.FormRow("Priority", "33%", priorityDropdown, 0),
            QMUIUtils.FormRow("Status", "34%", statusDropdown, 0),
        },

        QMUIUtils.FormColumns{
            QMUIUtils.FormRow("Quest Giver", "50%", questGiverInput, 0),
            QMUIUtils.FormRow("Location", "50%", locationInput, 0),
        },

        QMUIUtils.FormRow("Description", QMConstants.formRowWidth, descriptionInput),

        QMUIUtils.FormColumns{
            QMUIUtils.FormRow("Rewards", QMConstants.rewardsWidth, rewardsInput, 0),
            QMUIUtils.FormRow("Claimed", QMConstants.claimedWidth, rewardsClaimedCheck, 0),
        },
    }

    -- The text-only form for a viewer who may not edit, built once and refilled

    local readTitleRow, readTitle = ReadField("Title", QMConstants.formRowWidth)
    local readCategoryRow, readCategory = ReadField("Category", "33%", 0)
    local readPriorityRow, readPriority = ReadField("Priority", "33%", 0)
    local readStatusRow, readStatus = ReadField("Status", "34%", 0)
    local readGiverRow, readGiver = ReadField("Quest Giver", "50%", 0)
    local readLocationRow, readLocation = ReadField("Location", "50%", 0)
    local readDescriptionRow, readDescription = ReadField("Description", QMConstants.formRowWidth)
    local readRewardsRow, readRewards = ReadField("Rewards", QMConstants.rewardsWidth, 0)
    local readClaimedRow, readClaimed = ReadField("Claimed", QMConstants.claimedWidth, 0)

    local readPanel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",

        readTitleRow,
        QMUIUtils.FormColumns{ readCategoryRow, readPriorityRow, readStatusRow },
        QMUIUtils.FormColumns{ readGiverRow, readLocationRow },
        readDescriptionRow,
        QMUIUtils.FormColumns{ readRewardsRow, readClaimedRow },
    }

    -- Objectives

    --- Moves the dragged objective in front of the target and renumbers the rest
    --- @param draggedId string
    --- @param targetId string
    local function ReorderObjective(draggedId, targetId)
        if draggedId == targetId then
            return
        end

        Update(function(live)
            local objectives = live:GetObjectivesSorted()

            local draggedIndex, targetIndex
            for i, objective in ipairs(objectives) do
                if objective:GetID() == draggedId then
                    draggedIndex = i
                end
                if objective:GetID() == targetId then
                    targetIndex = i
                end
            end

            if draggedIndex == nil or targetIndex == nil then
                return
            end

            local newOrder = {}
            for i, objective in ipairs(objectives) do
                if i == targetIndex then
                    newOrder[#newOrder + 1] = objectives[draggedIndex]
                end
                if i ~= draggedIndex then
                    newOrder[#newOrder + 1] = objective
                end
            end

            for order, objective in ipairs(newOrder) do
                objective:SetOrder(order)
            end
        end)
    end

    --- An editable objective row. Built once and handed an objective with
    --- `setObjective`; handed nil, it collapses. Text is refilled only when the
    --- stored value moved, so typing in progress survives another client's change.
    --- @return table panel
    local function CreateEditObjectiveRow()
        --- @type {objectiveId: string|nil, title: string|nil, description: string|nil, status: string|nil}
        local bound = {}
        local glyphState = {}

        --- @param fn fun(objective: QMQuestObjective)
        local function UpdateObjective(fn)
            if bound.objectiveId == nil then
                return
            end
            Update(function(live)
                local target = live:GetObjective(bound.objectiveId)
                if target ~= nil then
                    fn(target)
                end
            end)
        end

        local handle = gui.Panel{
            classes = {HANDLE_CLASS},
            width = QMConstants.objectiveDragHandleSize,
            height = QMConstants.objectiveDragHandleSize,
            halign = "left",
            valign = "center",
            rmargin = 4,
            bgimage = mod.images.qmHandle,
            bgcolor = "white",
            draggable = true,
            dragTarget = true,
            data = { objectiveId = nil },
            canDragOnto = function(element, target)
                return target ~= nil and target:HasClass(HANDLE_CLASS)
            end,
            drag = function(element, target)
                if target ~= nil and bound.objectiveId ~= nil then
                    ReorderObjective(bound.objectiveId, target.data.objectiveId)
                end
            end,
            hover = THCWidgets.Tooltip("Drag to reorder"),
        }

        local glyph = StatusGlyph()

        local objectiveTitle = gui.Input{
            classes = {"formStacked", "sizeXs"},
            width = "100% available",
            height = 24,
            halign = "left",
            valign = "center",
            placeholderText = "Objective title",
            text = "",
            change = function(element)
                if element.text == bound.title then
                    return
                end
                UpdateObjective(function(target)
                    target:SetTitle(element.text)
                end)
            end,
        }

        local objectiveStatus = gui.Dropdown{
            classes = {"formStacked", "sizeXs"},
            width = QMConstants.objectiveStatusWidth,
            height = 24,
            halign = "left",
            valign = "center",
            hmargin = 4,
            options = DropdownOptions(QMConstants.statusOrder),
            idChosen = QMQuest.STATUS.NOT_STARTED,
            change = function(element)
                if element.idChosen == bound.status then
                    return
                end
                UpdateObjective(function(target)
                    target:SetStatus(element.idChosen)
                end)
            end,
        }

        local eye = QMUIUtils.EyeToggle{
            shown = false,
            size = QMConstants.rowIconSize,
            change = function(shown)
                UpdateObjective(function(target)
                    target:SetVisibleToPlayers(shown)
                end)
            end,
        }

        local trash = gui.Button{
            classes = {"deleteButton", "sizeXs"},
            requireConfirm = true,
            halign = "right",
            valign = "center",
            hmargin = 2,
            hover = THCWidgets.Tooltip("Remove this objective"),
            click = function()
                local objectiveId = bound.objectiveId
                if objectiveId == nil then
                    return
                end
                Update(function(live)
                    live:RemoveObjective(objectiveId)
                end)
            end,
        }

        local objectiveDescription = gui.Input{
            classes = {"formStacked", "sizeXs"},
            width = string.format("100%%-%d", OBJECTIVE_INDENT),
            height = QMConstants.multilineHeight,
            halign = "right",
            tmargin = 4,
            multiline = true,
            textAlignment = "topLeft",
            characterLimit = QMConstants.characterLimit,
            placeholderText = "What needs doing.",
            text = "",
            change = function(element)
                if element.text == bound.description then
                    return
                end
                UpdateObjective(function(target)
                    target:SetDescription(element.text)
                end)
            end,
        }

        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            halign = "left",
            valign = "top",
            vmargin = 4,

            --- @param objective QMQuestObjective|nil
            setObjective = function(element, objective)
                element:SetClass("collapsed", objective == nil)
                if objective == nil then
                    return
                end

                bound.objectiveId = objective:GetID()
                handle.data.objectiveId = bound.objectiveId

                local status = objective:GetStatus() or QMQuestObjective.STATUS.NOT_STARTED
                bound.status = status
                BindStatusGlyph(glyph, glyphState, status)
                if objectiveStatus.idChosen ~= status then
                    objectiveStatus.idChosen = status
                end

                local title = objective:GetTitle() or ""
                if bound.title ~= title then
                    bound.title = title
                    if objectiveTitle.text ~= title then
                        objectiveTitle.text = title
                    end
                end

                local description = objective:GetDescription() or ""
                if bound.description ~= description then
                    bound.description = description
                    if objectiveDescription.text ~= description then
                        objectiveDescription.text = description
                    end
                end

                eye:FireEvent("setState", objective:GetVisibleToPlayers())
            end,

            gui.Panel{
                width = "100%",
                height = 26,
                flow = "horizontal",
                halign = "left",
                valign = "top",

                handle,
                glyph,
                objectiveTitle,
                objectiveStatus,
                eye,
                trash,
            },

            objectiveDescription,
        }
    end

    --- A text-only objective row, bound the same way
    --- @return table panel
    local function CreateReadObjectiveRow()
        local glyphState = {}
        local glyph = StatusGlyph()

        local titleLabel = gui.Label{
            classes = {"sizeXs", "noBold"},
            width = "100% available",
            height = "auto",
            halign = "left",
            valign = "center",
            text = "",
        }

        local descriptionLabel = gui.Label{
            classes = {"sizeXs", "noBold", "fgMuted"},
            width = string.format("100%%-%d", QMConstants.objectiveIconSize + 4),
            height = "auto",
            halign = "right",
            textAlignment = "topLeft",
            textWrap = true,
            text = "",
        }

        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            halign = "left",
            valign = "top",
            vmargin = 4,

            --- @param objective QMQuestObjective|nil
            setObjective = function(element, objective)
                element:SetClass("collapsed", objective == nil)
                if objective == nil then
                    return
                end

                BindStatusGlyph(glyph, glyphState,
                    objective:GetStatus() or QMQuestObjective.STATUS.NOT_STARTED)

                titleLabel.text = objective:GetTitle() or ""

                local description = objective:GetDescription() or ""
                descriptionLabel.text = description
                descriptionLabel:SetClass("collapsed", description == "")
            end,

            gui.Panel{
                width = "100%",
                height = "auto",
                flow = "horizontal",
                halign = "left",
                valign = "top",

                glyph,
                titleLabel,
            },

            descriptionLabel,
        }
    end

    local editObjectives = gui.Panel{
        width = QMConstants.sectionWidth,
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
    }

    local readObjectives = gui.Panel{
        width = QMConstants.sectionWidth,
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
    }

    local noObjectives = EmptyLine("None yet.")

    local addObjectiveButton = gui.Button{
        classes = {"addButton", "sizeXs"},
        halign = "left",
        valign = "center",
        lmargin = 6,
        hover = THCWidgets.Tooltip("Add an objective"),
        click = function()
            Update(function(live)
                live:AddObjective()
            end)
        end,
    }

    local objectivesHeader = QMUIUtils.SectionHeader{
        text = "Objectives",
        trailing = addObjectiveButton,
    }

    -- Notes

    local noteInput = gui.Input{
        classes = {"formStacked", "sizeXs"},
        width = "100%",
        height = QMConstants.multilineHeight,
        halign = "left",
        multiline = true,
        textAlignment = "topLeft",
        characterLimit = QMConstants.characterLimit,
        placeholderText = "Write a note.",
    }

    local noteComposer = gui.Panel{
        width = QMConstants.sectionWidth,
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
        tmargin = 6,

        noteInput,

        gui.Button{
            classes = {"sizeS"},
            text = "Add Note",
            halign = "right",
            valign = "top",
            tmargin = 4,
            click = function()
                local content = trim(noteInput.text or "")
                if content == "" then
                    return
                end
                Update(function(live)
                    live:AddNote(content)
                end)
                noteInput.text = ""
            end,
        },
    }

    --- One note with its byline. Built once and handed a note with `setNote`.
    --- @return table panel
    local function CreateNoteRow()
        --- @type {noteId: string|nil, byline: string|nil, content: string|nil}
        local bound = {}

        local bylineLabel = gui.Label{
            classes = {"sizeXxs", "noBold", "fgMuted"},
            width = "100% available",
            height = "auto",
            halign = "left",
            valign = "center",
            text = "",
        }

        local deleteButton = gui.Button{
            classes = {"deleteButton", "sizeXs"},
            requireConfirm = true,
            halign = "right",
            valign = "center",
            hover = THCWidgets.Tooltip("Remove this note"),
            click = function()
                local noteId = bound.noteId
                if noteId == nil then
                    return
                end
                Update(function(live)
                    live:RemoveNote(noteId)
                end)
            end,
        }

        local contentLabel = gui.Label{
            classes = {"sizeXs", "noBold"},
            width = "100%",
            height = "auto",
            halign = "left",
            textAlignment = "topLeft",
            textWrap = true,
            text = "",
        }

        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            halign = "left",
            valign = "top",
            vmargin = 4,

            --- @param note QMQuestNote|nil
            setNote = function(element, note)
                element:SetClass("collapsed", note == nil)
                if note == nil then
                    return
                end

                bound.noteId = note:GetID()
                local authorId = note:GetAuthorId() or ""

                local byline = string.format("By %s at %s",
                    QMUIUtils.GetPlayerDisplayName(authorId),
                    DisplayTimestamp(note:GetCreatedAt()))
                if bound.byline ~= byline then
                    bound.byline = byline
                    bylineLabel.text = byline
                end

                deleteButton:SetClass("collapsed", not (dmhub.isDM or authorId == dmhub.userid))

                local content = note:GetContent() or ""
                if bound.content ~= content then
                    bound.content = content
                    contentLabel.text = content
                end
            end,

            gui.Panel{
                width = "100%",
                height = QMConstants.noteHeaderHeight,
                flow = "horizontal",
                halign = "left",
                valign = "top",

                bylineLabel,
                deleteButton,
            },

            contentLabel,
        }
    end

    local notesBody = gui.Panel{
        width = QMConstants.sectionWidth,
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
    }

    local noNotes = EmptyLine("No notes yet.")

    local contentPanel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",

        formPanel,
        readPanel,
        objectivesHeader,
        editObjectives,
        readObjectives,
        noObjectives,
        QMUIUtils.SectionHeader{ text = "Notes" },
        noteComposer,
        notesBody,
        noNotes,
    }

    local emptyNotice = THCWidgets.Notice("Select a quest on the left, or add one.")

    --- Refills a text control only when its value moved, so typing in progress survives
    --- @param control table
    --- @param value string
    local function Refill(control, value)
        if control.text ~= value then
            control.text = value
        end
    end

    --- @param control table A dropdown
    --- @param value string
    local function RefillChoice(control, value)
        if control.idChosen ~= value then
            control.idChosen = value
        end
    end

    --- @param quest QMQuest
    local function FillForm(quest)
        Refill(titleInput, quest:GetTitle() or "")
        RefillChoice(categoryDropdown, quest:GetCategory() or QMQuest.CATEGORY.MAIN)
        RefillChoice(priorityDropdown, quest:GetPriority() or QMQuest.PRIORITY.MEDIUM)
        RefillChoice(statusDropdown, quest:GetStatus() or QMQuest.STATUS.NOT_STARTED)
        Refill(questGiverInput, quest:GetQuestGiver() or "")
        Refill(locationInput, quest:GetLocation() or "")
        Refill(rewardsInput, quest:GetRewards() or "")
        Refill(descriptionInput, quest:GetDescription() or "")
        if rewardsClaimedCheck.value ~= (quest:GetRewardsClaimed() or false) then
            rewardsClaimedCheck.value = quest:GetRewardsClaimed() or false
        end
    end

    --- @param quest QMQuest
    local function FillReadForm(quest)
        Refill(readTitle, quest:GetTitle() or "")
        Refill(readCategory, quest:GetCategory() or "")
        Refill(readPriority, quest:GetPriority() or "")
        Refill(readStatus, quest:GetStatus() or "")
        Refill(readGiver, quest:GetQuestGiver() or "")
        Refill(readLocation, quest:GetLocation() or "")
        Refill(readDescription, quest:GetDescription() or "")
        Refill(readRewards, quest:GetRewards() or "")
        Refill(readClaimed, cond(quest:GetRewardsClaimed(), "Yes", "No"))
    end

    --What the list column leaves; "100%" here would be the whole working
    --width and push the pane off the window's right edge.
    local resultPanel
    resultPanel = gui.Panel{
        width = "100% available",
        height = "100%",
        flow = "vertical",
        halign = "left",
        valign = "top",
        vscroll = true,

        setQuest = function(element, questId)
            m_questId = questId
            element:FireEvent("rebuild")
        end,

        questsChanged = function(element)
            element:FireEvent("rebuild")
        end,

        rebuild = function()
            local quest = Live()

            contentPanel:SetClass("collapsed", quest == nil)
            emptyNotice:SetClass("collapsed", quest ~= nil)

            if quest == nil then
                return
            end

            local canEdit = quest:CanUserEdit()
            formPanel:SetClass("collapsed", not canEdit)
            readPanel:SetClass("collapsed", canEdit)
            addObjectiveButton:SetClass("collapsed", not canEdit)

            if canEdit then
                FillForm(quest)
            else
                FillReadForm(quest)
            end

            --The inactive list is handed nothing, so its rows collapse rather
            --than sit bound to a quest the viewer has moved on from.
            local objectives = quest:GetObjectivesForUser()
            local none = {}
            editObjectives:SetClass("collapsed", not canEdit)
            readObjectives:SetClass("collapsed", canEdit)
            THCWidgets.BindList(editObjectives, cond(canEdit, objectives, none),
                CreateEditObjectiveRow, "setObjective")
            THCWidgets.BindList(readObjectives, cond(canEdit, none, objectives),
                CreateReadObjectiveRow, "setObjective")
            noObjectives:SetClass("collapsed", #objectives > 0)

            local notes = quest:GetNotes()
            THCWidgets.BindList(notesBody, notes, CreateNoteRow, "setNote")
            noNotes:SetClass("collapsed", #notes > 0)
        end,

        create = function(element)
            element:FireEvent("rebuild")
        end,

        contentPanel,
        emptyNotice,
    }

    return resultPanel
end
