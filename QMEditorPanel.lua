local mod = dmhub.GetModLoading()

--- The right pane of the Quest Manager window: the selected quest's form, its
--- objectives and its notes. Whoever may edit the quest gets controls; anyone
--- else gets the same information as text, and can still add a note.
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

--- @param status string One of QMQuestObjective.STATUS values
--- @return table panel The tinted status glyph
local function StatusGlyph(status)
    return gui.Panel{
        classes = { QMConstants.statusTone[status] or "bgFgMuted" },
        width = QMConstants.objectiveIconSize,
        height = QMConstants.objectiveIconSize,
        halign = "left",
        valign = "center",
        rmargin = 4,
        bgimage = QMConstants.statusIcon[status] or QMConstants.statusIcon[QMQuest.STATUS.NOT_STARTED],
        hover = gui.Tooltip(status),
    }
end

--- A label-over-text pair for the read-only form
--- @param labelText string
--- @param width string
--- @param value string
--- @param lmargin number|nil Overrides the theme's row margin; 0 for a column inside a group
--- @return table panel
local function ReadField(labelText, width, value, lmargin)
    return gui.Panel{
        classes = {"formStackedRow"},
        width = width,
        lmargin = lmargin,
        children = {
            gui.Label{
                classes = {"formStacked", "sizeS"},
                text = labelText,
            },
            gui.Label{
                classes = {"sizeS", "noBold"},
                width = "98%",
                height = "auto",
                halign = "left",
                textAlignment = "topLeft",
                textWrap = true,
                text = value or "",
            },
        },
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
        width = "100%",
        height = 26,
        options = DropdownOptions(QMConstants.categoryOrder),
        change = ChoiceChange(QMQuest.GetCategory, QMQuest.SetCategory),
    }

    local priorityDropdown = gui.Dropdown{
        classes = {"formStacked", "sizeS"},
        width = "100%",
        height = 26,
        options = DropdownOptions(QMConstants.priorityOrder),
        change = ChoiceChange(QMQuest.GetPriority, QMQuest.SetPriority),
    }

    local statusDropdown = gui.Dropdown{
        classes = {"formStacked", "sizeS"},
        width = "100%",
        height = 26,
        options = DropdownOptions(QMConstants.statusOrder),
        change = ChoiceChange(QMQuest.GetStatus, QMQuest.SetStatus),
    }

    local questGiverInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        placeholderText = "Who gave this quest?",
        change = TextChange(QMQuest.GetQuestGiver, QMQuest.SetQuestGiver),
    }

    local locationInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        placeholderText = "Where does this quest take place?",
        change = TextChange(QMQuest.GetLocation, QMQuest.SetLocation),
    }

    local rewardsInput = gui.Input{
        classes = {"formStacked", "sizeS"},
        placeholderText = "What does this quest offer?",
        change = TextChange(QMQuest.GetRewards, QMQuest.SetRewards),
    }

    local rewardsClaimedCheck = gui.Check{
        classes = {"sizeS"},
        text = "Rewards Claimed",
        value = false,
        halign = "left",
        lmargin = 12,
        bmargin = 8,
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

        QMUIUtils.FormRow("Rewards", QMConstants.formRowWidth, rewardsInput),
        rewardsClaimedCheck,
        QMUIUtils.FormRow("Description", QMConstants.formRowWidth, descriptionInput),
    }

    --- The text-only form for a viewer who may not edit; rebuilt per quest
    local readPanel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
    }

    -- Objectives

    local objectivesBody = gui.Panel{
        width = QMConstants.sectionWidth,
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
    }

    local addObjectiveButton = gui.Button{
        classes = {"addButton", "sizeXs"},
        halign = "left",
        valign = "center",
        lmargin = 6,
        hover = gui.Tooltip("Add an objective"),
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

    --- @param objective QMQuestObjective
    --- @return table panel An editable objective row
    local function EditObjectiveRow(objective)
        local objectiveId = objective:GetID()
        local status = objective:GetStatus() or QMQuestObjective.STATUS.NOT_STARTED

        --- @param fn fun(objective: QMQuestObjective)
        local function UpdateObjective(fn)
            Update(function(live)
                local target = live:GetObjective(objectiveId)
                if target ~= nil then
                    fn(target)
                end
            end)
        end

        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            halign = "left",
            valign = "top",
            vmargin = 4,

            gui.Panel{
                width = "100%",
                height = 26,
                flow = "horizontal",
                halign = "left",
                valign = "top",

                gui.Panel{
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
                    data = { objectiveId = objectiveId },
                    canDragOnto = function(element, target)
                        return target ~= nil and target:HasClass(HANDLE_CLASS)
                    end,
                    drag = function(element, target)
                        if target ~= nil then
                            ReorderObjective(objectiveId, target.data.objectiveId)
                        end
                    end,
                    hover = gui.Tooltip("Drag to reorder"),
                },

                StatusGlyph(status),

                gui.Input{
                    classes = {"formStacked", "sizeXs"},
                    width = "100% available",
                    height = 24,
                    halign = "left",
                    valign = "center",
                    placeholderText = "Objective title",
                    text = objective:GetTitle() or "",
                    change = function(element)
                        if element.text == objective:GetTitle() then
                            return
                        end
                        UpdateObjective(function(target)
                            target:SetTitle(element.text)
                        end)
                    end,
                },

                gui.Dropdown{
                    classes = {"formStacked", "sizeXs"},
                    width = QMConstants.objectiveStatusWidth,
                    height = 24,
                    halign = "left",
                    valign = "center",
                    hmargin = 4,
                    options = DropdownOptions(QMConstants.statusOrder),
                    idChosen = status,
                    change = function(element)
                        if element.idChosen == objective:GetStatus() then
                            return
                        end
                        UpdateObjective(function(target)
                            target:SetStatus(element.idChosen)
                        end)
                    end,
                },

                QMUIUtils.EyeToggle{
                    shown = objective:GetVisibleToPlayers(),
                    size = QMConstants.rowIconSize,
                    change = function(shown)
                        UpdateObjective(function(target)
                            target:SetVisibleToPlayers(shown)
                        end)
                    end,
                },

                gui.Button{
                    classes = {"deleteButton", "sizeXs"},
                    requireConfirm = true,
                    halign = "right",
                    valign = "center",
                    hmargin = 2,
                    hover = gui.Tooltip("Remove this objective"),
                    click = function()
                        Update(function(live)
                            live:RemoveObjective(objectiveId)
                        end)
                    end,
                },
            },

            gui.Input{
                classes = {"formStacked", "sizeXs"},
                width = string.format("100%%-%d", OBJECTIVE_INDENT),
                height = QMConstants.multilineHeight,
                halign = "right",
                multiline = true,
                textAlignment = "topLeft",
                characterLimit = QMConstants.characterLimit,
                placeholderText = "What needs doing.",
                text = objective:GetDescription() or "",
                change = function(element)
                    if element.text == objective:GetDescription() then
                        return
                    end
                    UpdateObjective(function(target)
                        target:SetDescription(element.text)
                    end)
                end,
            },
        }
    end

    --- @param objective QMQuestObjective
    --- @return table panel A text-only objective row
    local function ReadObjectiveRow(objective)
        local status = objective:GetStatus() or QMQuestObjective.STATUS.NOT_STARTED
        local description = objective:GetDescription() or ""

        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            halign = "left",
            valign = "top",
            vmargin = 4,

            gui.Panel{
                width = "100%",
                height = "auto",
                flow = "horizontal",
                halign = "left",
                valign = "top",

                StatusGlyph(status),

                gui.Label{
                    classes = {"sizeXs", "noBold"},
                    width = "100% available",
                    height = "auto",
                    halign = "left",
                    valign = "center",
                    text = objective:GetTitle() or "",
                },
            },

            gui.Label{
                classes = {"sizeXs", "noBold", "fgMuted", cond(description == "", "collapsed")},
                width = string.format("100%%-%d", QMConstants.objectiveIconSize + 4),
                height = "auto",
                halign = "right",
                textAlignment = "topLeft",
                textWrap = true,
                text = description,
            },
        }
    end

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

    local notesBody = gui.Panel{
        width = QMConstants.sectionWidth,
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
    }

    --- @param note QMQuestNote
    --- @return table panel One note with its byline
    local function NoteRow(note)
        local noteId = note:GetID()
        local authorId = note:GetAuthorId() or ""

        local headerChildren = {
            gui.Label{
                classes = {"sizeXxs", "noBold", "fgMuted"},
                width = "100% available",
                height = "auto",
                halign = "left",
                valign = "center",
                text = string.format("By %s at %s",
                    QMUIUtils.GetPlayerDisplayName(authorId),
                    DisplayTimestamp(note:GetCreatedAt())),
            },
        }

        if dmhub.isDM or authorId == dmhub.userid then
            headerChildren[#headerChildren + 1] = gui.Button{
                classes = {"deleteButton", "sizeXs"},
                requireConfirm = true,
                halign = "right",
                valign = "center",
                hover = gui.Tooltip("Remove this note"),
                click = function()
                    Update(function(live)
                        live:RemoveNote(noteId)
                    end)
                end,
            }
        end

        return gui.Panel{
            width = "100%",
            height = "auto",
            flow = "vertical",
            halign = "left",
            valign = "top",
            vmargin = 4,

            gui.Panel{
                width = "100%",
                height = QMConstants.noteHeaderHeight,
                flow = "horizontal",
                halign = "left",
                valign = "top",
                children = headerChildren,
            },

            gui.Label{
                classes = {"sizeXs", "noBold"},
                width = "100%",
                height = "auto",
                halign = "left",
                textAlignment = "topLeft",
                textWrap = true,
                text = note:GetContent() or "",
            },
        }
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

    local contentPanel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",

        formPanel,
        readPanel,
        objectivesHeader,
        objectivesBody,
        QMUIUtils.SectionHeader{ text = "Notes" },
        noteComposer,
        notesBody,
    }

    local emptyLabel = gui.Label{
        classes = {"sizeS", "fgMuted"},
        width = "100%",
        height = "auto",
        halign = "center",
        valign = "center",
        textAlignment = "center",
        text = "Select a quest on the left, or add one.",
    }

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
        readPanel.children = {
            ReadField("Title", QMConstants.formRowWidth, quest:GetTitle()),

            QMUIUtils.FormColumns{
                ReadField("Category", "33%", quest:GetCategory(), 0),
                ReadField("Priority", "33%", quest:GetPriority(), 0),
                ReadField("Status", "34%", quest:GetStatus(), 0),
            },

            QMUIUtils.FormColumns{
                ReadField("Quest Giver", "50%", quest:GetQuestGiver(), 0),
                ReadField("Location", "50%", quest:GetLocation(), 0),
            },

            ReadField("Rewards", QMConstants.formRowWidth, cond(quest:GetRewardsClaimed(),
                (quest:GetRewards() or "") .. " (claimed)", quest:GetRewards())),
            ReadField("Description", QMConstants.formRowWidth, quest:GetDescription()),
        }
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
            emptyLabel:SetClass("collapsed", quest ~= nil)

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

            local objectives = quest:GetObjectivesForUser()
            local objectiveRows = {}
            for _, objective in ipairs(objectives) do
                if canEdit then
                    objectiveRows[#objectiveRows + 1] = EditObjectiveRow(objective)
                else
                    objectiveRows[#objectiveRows + 1] = ReadObjectiveRow(objective)
                end
            end
            if #objectiveRows == 0 then
                objectiveRows[1] = EmptyLine("None yet.")
            end
            objectivesBody.children = objectiveRows

            local noteRows = {}
            for _, note in ipairs(quest:GetNotes()) do
                noteRows[#noteRows + 1] = NoteRow(note)
            end
            if #noteRows == 0 then
                noteRows[1] = EmptyLine("No notes yet.")
            end
            notesBody.children = noteRows
        end,

        create = function(element)
            element:FireEvent("rebuild")
        end,

        contentPanel,
        emptyLabel,
    }

    return resultPanel
end
