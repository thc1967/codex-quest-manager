--- Quest Manager Window - Main windowed interface with tabbed layout
--- Provides a resizable, closable window with Quest, Objectives, and Notes tabs
--- @class QTQuestManagerWindow
--- @field questManager QTQuestManager The quest manager for data operations
QTQuestManagerWindow = RegisterGameType("QTQuestManagerWindow")
QTQuestManagerWindow.__index = QTQuestManagerWindow

local mod = dmhub.GetModLoading()

-- Windowed mode setting
setting{
    id = "quest:windowed",
    storage = "preference",
    default = false,
}

QTQuestManagerWindow.defaultTab = "Quest"

-- Tab styling similar to character sheet
QTQuestManagerWindow.TabsStyles = {
    gui.Style{
        selectors = {"questTabContainer"},
        height = 40,
        width = "100%",
        flow = "horizontal",
        bgcolor = "black",
        bgimage = "panels/square.png",
        borderColor = Styles.textColor,
        border = { y1 = 2 },
        vmargin = 1,
        hmargin = 2,
        halign = "center",
        valign = "top",
    },
    gui.Style{
        selectors = {"questTab"},
        fontFace = "Inter",
        fontWeight = "light",
        bold = false,
        bgcolor = "#111111ff",
        bgimage = "panels/square.png",
        brightness = 0.4,
        valign = "top",
        halign = "left",
        hpad = 20,
        width = 200,
        height = "100%",
        hmargin = 0,
        color = Styles.textColor,
        textAlignment = "center",
        fontSize = 26,
        minFontSize = 12,
    },
    gui.Style{
        selectors = {"questTab", "hover"},
        brightness = 1.2,
        transitionTime = 0.2,
    },
    gui.Style{
        selectors = {"questTab", "selected"},
        brightness = 1,
        transitionTime = 0.2,
    },
    gui.Style{
        selectors = {"questTabBorder"},
        width = "100%",
        height = "100%",
        border = {x1 = 2, x2 = 2, y1 = 2},
        borderColor = Styles.textColor,
        bgimage = "panels/square.png",
        bgcolor = "clear",
    },
    gui.Style{
        selectors = {"questTabBorder", "parent:selected"},
        border = {x1 = 2, x2 = 2, y1 = 0}
    },
}

QTQuestManagerWindow.TabOptions = {}

--- Registers a tab with the Quest Manager window
--- @param tab table Tab configuration with id, text, and panel function
function QTQuestManagerWindow.RegisterTab(tab)
    local index = #QTQuestManagerWindow.TabOptions + 1
    for i, t in ipairs(QTQuestManagerWindow.TabOptions) do
        if t.id == tab.id then
            index = i
        end
    end
    QTQuestManagerWindow.TabOptions[index] = tab
end

--- Creates a new Quest Manager window instance
--- @param questManager QTQuestManager The quest manager for data operations
--- @param quest QTQuest The quest object to edit (draft or existing)
--- @return QTQuestManagerWindow instance The new window instance
function QTQuestManagerWindow:new(questManager, quest)
    local instance = setmetatable({}, self)
    instance.questManager = questManager
    instance.quest = quest
    instance.isOpen = false

    -- Validate we have required dependencies
    if not instance.questManager or not instance.quest then
        return nil
    end


    -- Set as global instance for refresh events (like CharacterSheet.instance)
    QTQuestManagerWindow.instance = instance

    return instance
end

--- Fires an event on the window element (like CharacterSheet.instance:FireEvent)
--- @param eventName string The name of the event to fire
function QTQuestManagerWindow:FireEvent(eventName)
    if self.windowElement then
        self.windowElement:FireEvent(eventName)
    end
end

function QTQuestManagerWindow:FireEventTree(eventName)
    if self.windowElement then
        self.windowElement:FireEventTree(eventName)
    end
end

--- Creates and shows the Quest Manager window
function QTQuestManagerWindow:Show()
    if self.isOpen then
        return -- Already open
    end

    self.isOpen = true
    local questWindow = self:_createWindow()
    self.windowElement = questWindow

    -- Show as modal
    gui.ShowModal(questWindow)
end

--- Creates the main window structure - WITH QUEST TAB CONTENT
--- @return table panel The main window panel
function QTQuestManagerWindow:_createWindow()
    local questManagerWindow = self
    local selectedTab = "Quest"

    -- Common close function for Cancel button and X button
    local closeWindow = function()
        gui.CloseModal()
    end

    -- Tab content panels
    local questPanel = QTQuestManagerWindow.CreateQuestPanel(self.questManager, self.quest)

    local objectivesPanel = QTQuestManagerWindow.CreateObjectivesPanel(self.questManager, self.quest)
    objectivesPanel.classes = {"hidden"}

    local notesPanel = QTQuestManagerWindow.CreateNotesPanel(self.questManager, self.quest)
    notesPanel.classes = {"hidden"}

    local tabPanels = {questPanel, objectivesPanel, notesPanel}

    -- Content panel that holds all tab panels
    local contentPanel = gui.Panel{
        width = "100%",
        height = "100%",
        flow = "none",
        valign = "top",
        children = tabPanels,

        showTab = function(element, tabIndex)
            for i, p in ipairs(tabPanels) do
                if p ~= nil then
                    local hidden = (tabIndex ~= i)
                    p:SetClass("hidden", hidden)
                end
            end
        end,
    }

    -- Declare tabsPanel variable first
    local tabsPanel

    -- Tab selection function
    local selectTab = function(tabName)
        selectedTab = tabName
        local index = tabName == "Quest" and 1 or tabName == "Objectives" and 2 or 3

        -- Hide/show tab content
        contentPanel:FireEventTree("showTab", index)

        -- Update tab appearance
        for _, tab in ipairs(tabsPanel.children) do
            if tab.data and tab.data.tabName then
                tab:SetClass("selected", tab.data.tabName == tabName)
            end
        end
    end

    -- Create tabs panel
    tabsPanel = gui.Panel{
        classes = {"questTabContainer"},
        styles = {QTQuestManagerWindow.TabsStyles},
        children = {
            gui.Label{
                classes = {"questTab", "selected"},
                text = "Quest",
                data = {tabName = "Quest"},
                press = function() selectTab("Quest") end,
                gui.Panel{classes = {"questTabBorder"}},
            },
            gui.Label{
                classes = {"questTab"},
                text = "Objectives",
                data = {tabName = "Objectives"},
                press = function() selectTab("Objectives") end,
                gui.Panel{classes = {"questTabBorder"}},
            },
            gui.Label{
                classes = {"questTab"},
                text = "Notes",
                data = {tabName = "Notes"},
                press = function() selectTab("Notes") end,
                gui.Panel{classes = {"questTabBorder"}},
            }
        }
    }

    return gui.Panel{
        id = "questManagerWindow",
        width = 1200,
        height = 800,
        halign = "center",
        valign = "center",
        borderWidth = 2,
        borderColor = Styles.textColor,
        bgimage = "panels/square.png",
        bgcolor = "#111111ff",
        opacity = 1.0,
        flow = "vertical",
        styles = {
            Styles.Default,
            Styles.Panel,
            QTQuestManagerWindow.TabsStyles
        },
        children = {
            -- Main content area (full height, no footer)
            gui.Panel{
                width = "100%",
                height = "100%",
                flow = "vertical",
                children = {
                    tabsPanel,
                    contentPanel
                }
            },

            -- X Close button (top right)
            gui.Panel{
                flow = "horizontal",
                floating = true,
                width = "auto",
                height = 40,
                halign = "right",
                valign = "top",
                children = {
                    gui.CloseButton{
                        width = 32,
                        height = 32,
                        valign = "center",
                        click = function(element)
                            closeWindow()
                        end,
                    }
                }
            }
        }
    }
end

-- Register default tabs
QTQuestManagerWindow.RegisterTab{
    id = "Quest",
    text = "Quest",
    order = 1,
    panel = function(questManager, quest)
        return QTQuestManagerWindow.CreateQuestPanel(questManager, quest)
    end
}

QTQuestManagerWindow.RegisterTab{
    id = "Objectives",
    text = "Objectives",
    order = 2,
    panel = function(questManager, quest)
        return QTQuestManagerWindow.CreateObjectivesPanel(questManager, quest)
    end
}

QTQuestManagerWindow.RegisterTab{
    id = "Notes",
    text = "Notes",
    order = 3,
    panel = function(questManager, quest)
        return QTQuestManagerWindow.CreateNotesPanel(questManager, quest)
    end
}

--- Creates the Quest tab panel
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object to display/edit
--- @return table panel The quest panel
function QTQuestManagerWindow.CreateQuestPanel(questManager, quest)
    return gui.Panel{
        id = "questPanel",
        width = "100%",
        height = "100%",
        flow = "vertical",
        styles = {
            gui.Style{
                selectors = {"#questPanel"},
                bgcolor = "#111111ff",
                borderWidth = 2,
                borderColor = Styles.textColor,
                opacity = 1.0,
            }
        },
        children = {
            QTQuestManagerWindow._buildQuestForm(questManager, quest)
        }
    }
end

--- Creates the Objectives tab panel
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object to display/edit
--- @return table panel The objectives panel
function QTQuestManagerWindow.CreateObjectivesPanel(questManager, quest)
    local function buildObjectivesList()
        local objectives = quest:GetObjectives()
        local objectiveChildren = {}

        if #objectives == 0 then
            objectiveChildren[#objectiveChildren + 1] = gui.Label {
                text = "No objectives yet. Click 'Add Objective' to create the first objective!",
                width = "100%",
                height = "100%",
                halign = "center",
                valign = "center",
                textAlignment = "center",
                classes = {"QTLabel", "QTBase"},
                bold = false
            }
        else
            for i, objective in ipairs(objectives) do
                -- Add divider before objective (except first one)
                if i > 1 then
                    objectiveChildren[#objectiveChildren + 1] = gui.Divider { width = "90%", vmargin = 2 }
                end

                -- Objective item
                objectiveChildren[#objectiveChildren + 1] = QTQuestManagerWindow.CreateObjectiveItem(questManager, quest, objective)
            end
        end

        return objectiveChildren
    end

    return gui.Panel{
        id = "objectivesPanel",
        width = "100%-6",
        height = "90%",
        flow = "vertical",
        valign = "top",
        hpad = 20,
        vpad = 20,
        styles = QTUIUtils.GetDialogStyles(),
        refreshObjectives = function(element)
            local scrollArea = element:Get("objectivesScrollArea")
            if scrollArea then
                scrollArea.children = buildObjectivesList()
            end
        end,
        children = {
            -- Scrollable objectives area
            gui.Panel{
                width = "100%",
                height = "100%-60",
                valign = "top",
                vscroll = true,
                children = {
                    gui.Panel{
                        id = "objectivesScrollArea",
                        width = "100%",
                        height = "auto",
                        flow = "vertical",
                        valign = "top",
                        children = {
                            table.unpack(buildObjectivesList())
                        }
                    },
                }
            },

            -- Add objective button
            gui.AddButton {
                halign = "right",
                vmargin = 5,
                hmargin = 40,
                linger = function(element)
                    gui.Tooltip("Add a new objective")(element)
                end,
                click = function(element)
                    -- Add new empty objective directly (character sheet pattern)
                    quest:AddObjective("")
                    -- Refresh to show the new objective
                    if QTQuestManagerWindow.instance then
                        QTQuestManagerWindow.instance:FireEventTree("refreshObjectives")
                    end
                end
            }
        }
    }
end

--- Creates the Notes tab panel
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object to display/edit
--- @return table panel The notes panel
function QTQuestManagerWindow.CreateNotesPanel(questManager, quest)
    local function buildNotesList()
        local notes = quest:GetNotes()
        local noteChildren = {}

        if #notes == 0 then
            noteChildren[#noteChildren + 1] = gui.Label {
                text = "No notes yet. Click 'Add Note' to create the first note.",
                width = "100%",
                height = "100%",
                halign = "center",
                valign = "center",
                textAlignment = "center",
                classes = {"QTLabel", "QTBase"},
                bold = false
            }
        else
            for i, note in ipairs(notes) do
                -- Add divider before note (except first one)
                if i > 1 then
                    noteChildren[#noteChildren + 1] = gui.Divider { width = "90%", vmargin = 2 }
                end

                -- Note item
                noteChildren[#noteChildren + 1] = QTQuestManagerWindow.CreateNoteItem(questManager, quest, note)
            end
        end

        return noteChildren
    end

    return gui.Panel{
        id = "notesPanel",
        width = "98%",
        height = "90%",
        flow = "vertical",
        valign = "top",
        hpad = 20,
        vpad = 20,
        styles = QTUIUtils.GetDialogStyles(),
        refreshNotes = function(element)
            local scrollArea = element:Get("notesScrollArea")
            if scrollArea then
                scrollArea.children = buildNotesList()
            end
        end,
        children = {
            -- Scrollable notes area
            gui.Panel{
                width = "100%",
                height = "100%-60",
                valign = "top",
                vscroll = true,
                children = {
                    gui.Panel{
                        id = "notesScrollArea",
                        width = "100%",
                        height = "auto",
                        flow = "vertical",
                        valign = "top",
                        children = buildNotesList()
                    }
                }
            },

            -- Add note button (always visible at bottom)
            gui.AddButton {
                halign = "right",
                vmargin = 5,
                hmargin = 40,
                linger = function(element)
                    gui.Tooltip("Add a new note")(element)
                end,
                click = function(element)
                    QTQuestManagerWindow.ShowAddNoteDialog(questManager, quest)
                end
            }
        }
    }
end


--- Creates a single note item display
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object
--- @param note QTQuestNote The note to display
--- @return table panel The note item panel
function QTQuestManagerWindow.CreateNoteItem(questManager, quest, note)
    local content = note:GetContent() or ""
    local authorId = note:GetAuthorId() or "Unknown"
    local timestamp = note:GetTimestamp() or ""

    -- Format timestamp for display
    local displayTimestamp = timestamp
    if timestamp and timestamp ~= "" then
        -- Simple format: just show date and time
        displayTimestamp = timestamp:gsub("T", " "):gsub("Z", ""):gsub("%-", "/")
    end

    -- Get player display name
    local authorDisplayName = QTUIUtils.GetPlayerDisplayName(authorId)

    -- Build delete button if user has permission
    local headerChildren = {
        gui.Label {
            text = "By: " .. authorDisplayName .. " at " .. displayTimestamp,
            width = "100%",
            height = 20,
            classes = {"QTLabel", "QTBase"},
            textAlignment = "left"
        }
    }

    -- Add delete button for author or DM
    if dmhub.isDM or note:GetAuthorId() == dmhub.userid then
        headerChildren[#headerChildren + 1] = gui.DeleteItemButton {
            width = 20,
            height = 20,
            halign = "right",
            valign = "center",
            click = function()
                QTUIUtils.ShowDeleteConfirmation("note", "this note", function()
                    quest:RemoveNote(note.id)
                    if QTQuestManagerWindow.instance then
                        QTQuestManagerWindow.instance:FireEventTree("refreshNotes")
                    end
                end)
            end
        }
    end

    return gui.Panel {
        width = "90%",
        height = "auto",
        flow = "vertical",
        valign = "top",
        vmargin = 5,
        children = {
            -- Header with author, timestamp, and delete button
            gui.Panel {
                width = "100%",
                height = 25,
                flow = "horizontal",
                valign = "top",
                children = headerChildren
            },
            -- Note content
            gui.Label {
                text = content,
                width = "100%",
                height = "auto",
                classes = {"QTLabel", "QTBase"},
                textAlignment = "left",
                textWrap = true,
                vmargin = 5,
                bold = false
            }
        }
    }
end

--- Handles drag and drop reordering of objectives
--- @param element table The dragged element
--- @param target table The drop target element
local DragObjective = function(element, target)
    if not element or not target or element == target then
        return
    end

    local draggedData = element.data
    local targetData = target.data

    if not draggedData or not targetData or
       not draggedData.objective or not targetData.objective or
       not draggedData.quest or not targetData.quest then
        return
    end

    -- Must be same quest
    if draggedData.quest.id ~= targetData.quest.id then
        return
    end

    local quest = draggedData.quest
    local draggedObjective = draggedData.objective
    local targetObjective = targetData.objective

    -- Get all objectives sorted by current order
    local objectives = quest:GetObjectives()

    -- Find indices of dragged and target objectives
    local draggedIndex, targetIndex
    for i, obj in ipairs(objectives) do
        if obj.id == draggedObjective.id then
            draggedIndex = i
        end
        if obj.id == targetObjective.id then
            targetIndex = i
        end
    end

    if not draggedIndex or not targetIndex or draggedIndex == targetIndex then
        return
    end

    -- Create new order array
    local newObjectivesOrder = {}

    -- Build new array with dragged objective inserted before target
    for i, obj in ipairs(objectives) do
        if i == targetIndex then
            -- Insert dragged objective before target
            table.insert(newObjectivesOrder, draggedObjective)
        end
        if i ~= draggedIndex then
            -- Add all objectives except the dragged one (it's been inserted above)
            table.insert(newObjectivesOrder, obj)
        end
    end

    -- Renumber all objectives with new order
    for newOrder, objective in ipairs(newObjectivesOrder) do
        if objective:GetOrder() ~= newOrder then
            objective:SetOrder(newOrder)
        end
    end

    -- Refresh UI to show new order
    if QTQuestManagerWindow.instance then
        QTQuestManagerWindow.instance:FireEventTree("refreshObjectives")
    end
end

--- Creates a drag handle for an objective that serves as both drag source and drop target
--- @param quest QTQuest The quest object
--- @param objective QTQuestObjective The objective this handle belongs to
--- @return table panel The drag handle panel
local CreateObjectiveDragHandle = function(quest, objective)
    return gui.Panel{
        classes = {"objective-drag-handle"},
        width = 24,
        height = 24,
        halign = "left",
        valign = "center",
        hmargin = 4,
        draggable = true,
        dragTarget = true,
        canDragOnto = function(element, target)
            return target:HasClass("objective-drag-handle")
        end,
        drag = DragObjective,
        data = {
            objective = objective,
            quest = quest
        },
        linger = function(element)
            gui.Tooltip("Drag to reorder objectives")(element)
        end
    }
end

--- Creates a single objective item with in-place editing
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object
--- @param objective QTQuestObjective The objective to display
--- @return table panel The objective item panel
function QTQuestManagerWindow.CreateObjectiveItem(questManager, quest, objective)
    local title = objective:GetTitle() or ""
    local status = objective:GetStatus() or QTQuestObjective.STATUS.NOT_STARTED
    local description = objective:GetDescription() or ""

    -- Status display formatting
    local statusText = status:gsub("_", " "):gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)

    -- Status options for dropdown (using same pattern as main quest tab)
    local statusOptions = {
        {id = QTQuestObjective.STATUS.NOT_STARTED, text = "Not Started"},
        {id = QTQuestObjective.STATUS.ACTIVE, text = "Active"},
        {id = QTQuestObjective.STATUS.COMPLETED, text = "Completed"},
        {id = QTQuestObjective.STATUS.FAILED, text = "Failed"},
        {id = QTQuestObjective.STATUS.ON_HOLD, text = "On Hold"}
    }

    -- Drag handle for reordering (always visible)
    local dragHandle = CreateObjectiveDragHandle(quest, objective)

    -- Delete button (only for DM or objective creator - for now, allow DM to delete any)
    local deleteButton = nil
    if dmhub.isDM then
        deleteButton = gui.DeleteItemButton {
            width = 20,
            height = 20,
            halign = "right",
            valign = "top",
            hmargin = 5,
            vmargin = 5,
            click = function()
                QTUIUtils.ShowDeleteConfirmation("objective", title, function()
                    quest:RemoveObjective(objective.id)
                    if QTQuestManagerWindow.instance then
                        QTQuestManagerWindow.instance:FireEventTree("refreshObjectives")
                    end
                end)
            end
        }
    end

    return gui.Panel {
        width = "100%",
        height = "auto",
        flow = "vertical",
        valign = "top",
        vmargin = 5,
        classes = {"objective-item", "status-" .. status},
        children = {
            -- Header with drag handle, title, status, and delete button
            gui.Panel {
                width = "100%",
                height = 30,
                vmargin = 15,
                flow = "horizontal",
                valign = "top",
                children = {
                    -- Drag handle (first element)
                    dragHandle,

                    -- Title input (in-place editing)
                    gui.Input {
                        width = "50%",
                        height = 25,
                        classes = {"QTInput", "QTBase"},
                        text = title,
                        placeholderText = "Enter objective title...",
                        editlag = 0.25,
                        edit = function(element)
                            if objective:GetTitle() ~= element.text then
                                objective:SetTitle(element.text)
                            end
                        end
                    },

                    -- Status dropdown (in-place editing)
                    gui.Dropdown {
                        width = "40%",
                        height = 25,
                        hmargin = 10,
                        classes = {"QTDropdown", "QTBase"},
                        options = statusOptions,
                        idChosen = status,
                        change = function(element)
                            local newStatus = element.idChosen
                            if objective:GetStatus() ~= newStatus then
                                objective:SetStatus(newStatus)
                                -- Update quest modified timestamp
                                quest:UpdateProperties({}, "Updated objective status")
                                -- Refresh to update styling
                                if QTQuestManagerWindow.instance then
                                    QTQuestManagerWindow.instance:FireEventTree("refreshObjectives")
                                end
                            end
                        end
                    },

                    -- Delete button (if allowed)
                    deleteButton
                }
            },

            -- Description text area (in-place editing)
            gui.Input {
                width = "96%",
                height = 80,
                classes = {"QTInput", "QTBase"},
                text = description,
                placeholderText = "Enter objective description...",
                lineType = "MultiLine",
                textAlignment = "topleft",
                editlag = 0.25,
                vmargin = 5,
                edit = function(element)
                    if objective:GetDescription() ~= element.text then
                        objective:SetDescription(element.text)
                    end
                end
            }
        }
    }
end

--- Shows the add note dialog
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object
function QTQuestManagerWindow.ShowAddNoteDialog(questManager, quest)
    local noteContent = ""

    local addNoteWindow = gui.Panel{
        width = 500,
        height = 300,
        halign = "center",
        valign = "center",
        bgcolor = "#111111ff",
        borderWidth = 2,
        borderColor = Styles.textColor,
        bgimage = "panels/square.png",
        flow = "vertical",
        hpad = 20,
        vpad = 20,
        styles = QTUIUtils.GetDialogStyles(),

        children = {
            -- Title
            gui.Label{
                text = "Add Note",
                width = "100%",
                height = 30,
                fontSize = "24",
                classes = {"QTLabel", "QTBase"},
                textAlignment = "center",
                halign = "center"
            },

            -- Note content input
            gui.Input{
                width = "95%",
                height = 150,
                classes = {"QTInput", "QTBase"},
                textAlignment = "topleft",
                placeholderText = "Enter your note here...",
                lineType = "MultiLine",
                vmargin = 5,
                change = function(element)
                    noteContent = element.text or ""
                end
            },

            -- Button panel
            gui.Panel{
                width = "100%",
                height = 50,
                halign = "center",
                valign = "center",
                flow = "horizontal",
                children = {
                    -- Cancel button (first)
                    gui.Button{
                        text = "Cancel",
                        width = 120,
                        height = 40,
                        hmargin = 20,
                        classes = {"QTButton", "QTBase"},
                        click = function(element)
                            gui.CloseModal()
                        end
                    },
                    -- Confirm button (second)
                    gui.Button{
                        text = "Add Note",
                        width = 120,
                        height = 40,
                        hmargin = 20,
                        classes = {"QTButton", "QTBase"},
                        click = function(element)
                            if noteContent and noteContent:trim() ~= "" then
                                quest:AddNote(noteContent, dmhub.userid)
                                if QTQuestManagerWindow.instance then
                                    QTQuestManagerWindow.instance:FireEventTree("refreshNotes")
                                end
                            end
                            gui.CloseModal()
                        end
                    }
                }
            }
        },

        escape = function(element)
            gui.CloseModal()
        end
    }

    gui.ShowModal(addNoteWindow)
end


--- Builds the quest form for the Quest tab
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object to display/edit
--- @return table panel The quest form panel
function QTQuestManagerWindow._buildQuestForm(questManager, quest)

    -- Create form field elements
    local titleField = gui.Input{
        width = "100%",
        classes = {"QTInput", "QTBase"},
        text = quest:GetTitle() or "New Quest",
        placeholderText = "Enter quest title...",
        lineType = "Single",
        editlag = 0.25,
        edit = function(element)
            if quest:GetTitle() ~= element.text then
                quest:SetTitle(element.text)
            end
        end
    }

    local descriptionField = gui.Input{
        width = "100%",
        height = 100,
        classes = {"QTInput", "QTBase"},
        text = quest:GetDescription() or "",
        placeholderText = "Enter quest description...",
        lineType = "MultiLine",
        textAlignment = "topleft",
        editlag = 0.25,
        edit = function(element)
            if quest:GetDescription() ~= element.text then
                quest:SetDescription(element.text)
            end
        end
    }

    local questGiverField = gui.Input{
        width = "100%",
        classes = {"QTInput", "QTBase"},
        text = quest:GetQuestGiver() or "",
        placeholderText = "Who gave this quest?",
        lineType = "Single",
        editlag = 0.25,
        edit = function(element)
            if quest:GetQuestGiver() ~= element.text then
                quest:SetQuestGiver(element.text)
            end
        end
    }

    local locationField = gui.Input{
        width = "100%",
        classes = {"QTInput", "QTBase"},
        text = quest:GetLocation() or "",
        placeholderText = "Where does this quest take place?",
        lineType = "Single",
        editlag = 0.25,
        edit = function(element)
            if quest:GetLocation() ~= element.text then
                quest:SetLocation(element.text)
            end
        end
    }

    local rewardsField = gui.Input{
        width = "100%",
        classes = {"QTInput", "QTBase"},
        text = quest:GetRewards() or "",
        placeholderText = "What rewards does this quest offer?",
        lineType = "Single",
        editlag = 0.25,
        edit = function(element)
            if quest:GetRewards() ~= element.text then
                quest:SetRewards(element.text)
            end
        end
    }

    -- Category options
    local categoryOptions = {
        {id = QTQuest.CATEGORY.MAIN, text = "Main Quest"},
        {id = QTQuest.CATEGORY.SIDE, text = "Side Quest"},
        {id = QTQuest.CATEGORY.PERSONAL, text = "Personal Quest"},
        {id = QTQuest.CATEGORY.FACTION, text = "Faction Quest"},
        {id = QTQuest.CATEGORY.TUTORIAL, text = "Tutorial"}
    }

    -- Priority options
    local priorityOptions = {
        {id = QTQuest.PRIORITY.HIGH, text = "High Priority"},
        {id = QTQuest.PRIORITY.MEDIUM, text = "Medium Priority"},
        {id = QTQuest.PRIORITY.LOW, text = "Low Priority"}
    }

    -- Status options
    local statusOptions = {
        {id = QTQuest.STATUS.NOT_STARTED, text = "Not Started"},
        {id = QTQuest.STATUS.ACTIVE, text = "Active"},
        {id = QTQuest.STATUS.COMPLETED, text = "Completed"},
        {id = QTQuest.STATUS.FAILED, text = "Failed"},
        {id = QTQuest.STATUS.ON_HOLD, text = "On Hold"}
    }

    -- Create dropdown elements
    local categoryDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        classes = {"QTDropdown", "QTBase"},
        options = categoryOptions,
        idChosen = quest:GetCategory() or QTQuest.CATEGORY.MAIN,
        change = function(element)
            local newCategory = element.idChosen
            if quest:GetCategory() ~= newCategory then
                quest:SetCategory(newCategory)
            end
        end
    }

    local priorityDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        classes = {"QTDropdown", "QTBase"},
        options = priorityOptions,
        idChosen = quest:GetPriority() or QTQuest.PRIORITY.MEDIUM,
        change = function(element)
            local newPriority = element.idChosen
            if quest:GetPriority() ~= newPriority then
                quest:SetPriority(newPriority)
            end
        end
    }

    local statusDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        classes = {"QTDropdown", "QTBase"},
        options = statusOptions,
        idChosen = quest:GetStatus() or QTQuest.STATUS.NOT_STARTED,
        change = function(element)
            local newStatus = element.idChosen
            if quest:GetStatus() ~= newStatus then
                quest:SetStatus(newStatus)
            end
        end
    }

    local rewardsClaimedCheckbox = gui.Check{
        text = "Rewards Claimed",
        width = 160,
        halign = "left",
        valign = "center",
        classes = {"QTCheck", "QTBase"},
        value = quest:GetRewardsClaimed() or false,
        change = function(element)
            if quest:GetRewardsClaimed() ~= element.value then
                quest:SetRewardsClaimed(element.value)
            end
        end
    }

    local visibleToPlayersCheckbox = gui.Check{
        text = "Visible to Players",
        width = 160,
        halign = "left",
        valign = "center",
        classes = {"QTCheck", "QTBase"},
        value = quest:GetVisibleToPlayers() or (not dmhub.isDM),
        change = function(element)
            if quest:GetVisibleToPlayers() ~= element.value then
                quest:SetVisibleToPlayers(element.value)
            end
        end
    }


    -- Build the form layout with simplest possible structure
    return gui.Panel{
        width = "100%",
        height = "90%",
        flow = "vertical",
        valign = "top",
        styles = QTUIUtils.GetDialogStyles(),
        hpad = 20,
        vpad = 10,
        children = {
            -- Title row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "vertical",
                vmargin = 5,
                children = {
                    gui.Label{
                        text = "Quest Title:",
                        classes = {"QTLabel", "QTBase"},
                        width = "100%",
                        height = 20
                    },
                    titleField
                }
            },

            -- Visible to Players row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "horizontal",
                children = {
                    gui.Panel{
                        width = "25%",
                        height = 60,
                        halign = "left",
                        valign = "center",
                        children = {
                            visibleToPlayersCheckbox
                        }
                    }
                },
            },

            -- Description field
            gui.Panel{
                width = "95%",
                height = 120,
                flow = "vertical",
                vmargin = 5,
                children = {
                    gui.Label{
                        text = "Description:",
                        classes = {"QTLabel", "QTBase"},
                        width = "100%",
                        height = 20
                    },
                    descriptionField
                }
            },

            -- Category, Priority, and Status row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "horizontal",
                vmargin = 5,
                children = {
                    gui.Panel{
                        width = "33%",
                        height = 60,
                        flow = "vertical",
                        hmargin = 5,
                        children = {
                            gui.Label{
                                text = "Category:",
                                classes = {"QTLabel", "QTBase"},
                                width = "100%",
                                height = 20
                            },
                            categoryDropdown
                        }
                    },
                    gui.Panel{
                        width = "33%",
                        height = 60,
                        flow = "vertical",
                        hmargin = 5,
                        children = {
                            gui.Label{
                                text = "Priority:",
                                classes = {"QTLabel", "QTBase"},
                                width = "100%",
                                height = 20
                            },
                            priorityDropdown
                        }
                    },
                    gui.Panel{
                        width = "34%",
                        height = 60,
                        flow = "vertical",
                        hmargin = 5,
                        children = {
                            gui.Label{
                                text = "Status:",
                                classes = {"QTLabel", "QTBase"},
                                width = "100%",
                                height = 20
                            },
                            statusDropdown
                        }
                    }
                }
            },

            -- Quest Giver row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "vertical",
                vmargin = 5,
                children = {
                    gui.Label{
                        text = "Quest Giver:",
                        classes = {"QTLabel", "QTBase"},
                        width = "100%",
                        height = 20
                    },
                    questGiverField
                }
            },

            -- Location row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "vertical",
                vmargin = 5,
                children = {
                    gui.Label{
                        text = "Location:",
                        classes = {"QTLabel", "QTBase"},
                        width = "100%",
                        height = 20
                    },
                    locationField
                }
            },

            -- Rewards and Rewards Claimed row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "vertical",
                vmargin = 5,
                children = {
                    gui.Label{
                        text = "Rewards:",
                        classes = {"QTLabel", "QTBase"},
                        width = "100%",
                        height = 20
                    },
                    rewardsField
                }
            },

            -- Rewards Claimed row
            gui.Panel{
                width = "95%",
                height = 60,
                flow = "vertical",
                vmargin = 5,
                children = {
                    rewardsClaimedCheckbox
                }
            },
        }
    }
end
