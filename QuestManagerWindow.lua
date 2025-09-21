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

    local notesPanel = gui.Panel{
        width = "100%",
        height = "100%",
        halign = "left",
        valign = "top",
        classes = {"hidden"},
        children = {
            gui.Label{
                text = "NOTES TAB CONTENT\n(placeholder)",
                width = "98%",
                fontSize = 20,
                color = Styles.textColor,
                textAlignment = "left",
                halign = "center",
                valign = "top"
            }
        }
    }

    local debugPanel = gui.Panel{
        width = "100%",
        height = "100%",
        flow = "vertical",
        valign = "top",
        classes = {"hidden"},
        borderWidth = 3,
        borderColor = "orange",
        children = {
            gui.Label{
                text = "DEBUG TAB: Panel has valign=top, flow=vertical",
                fontSize = 16,
                color = "yellow",
                bgcolor = "black",
                textAlignment = "left",
                width = "100%",
                height = 30,
                valign = "top",
            },
            gui.Label{
                text = "Test 1: This should appear at TOP if positioning works",
                fontSize = 14,
                color = "cyan",
                textAlignment = "left",
                width = "100%",
                height = 25,
                valign = "top",
            },
            -- gui.Label{
            --     text = "Test 2: This should appear BELOW Test 1",
            --     fontSize = 14,
            --     color = "lime",
            --     textAlignment = "left",
            --     width = "100%",
            --     height = 25
            -- },
            -- gui.Label{
            --     text = "Test 3: If all text appears CENTERED, the ContentPanel is centering us",
            --     fontSize = 14,
            --     color = "magenta",
            --     textAlignment = "left",
            --     width = "100%",
            --     height = 25
            -- },
            -- gui.Panel{
            --     width = "100%",
            --     height = 200,
            --     borderWidth = 2,
            --     borderColor = "white",
            --     children = {
            --         gui.Label{
            --             text = "NESTED PANEL: Should be at top of white border",
            --             fontSize = 12,
            --             color = "orange",
            --             textAlignment = "left",
            --             width = "100%",
            --             height = 20,
            --             valign = "top"
            --         }
            --     }
            -- }
        }
    }

    local tabPanels = {questPanel, objectivesPanel, notesPanel, debugPanel}

    -- Content panel that holds all tab panels
    local contentPanel = gui.Panel{
        width = "100%",
        height = "100%",
        flow = "none",
        valign = "top",
        borderWidth = 5,
        borderColor = "red",
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
        local index = tabName == "Quest" and 1 or tabName == "Objectives" and 2 or tabName == "Notes" and 3 or 4

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
            },
            gui.Label{
                classes = {"questTab"},
                text = "Debug",
                data = {tabName = "Debug"},
                press = function() selectTab("Debug") end,
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
        borderWidth = 5,
        borderColor = "blue",
        styles = QTQuestManagerWindow._getDialogStyles(),
        monitorGame = questManager:GetDocumentPath(),
        refreshGame = function(element)
            -- Rebuild objectives list when document changes
            local objectivesScrollArea = element:Get("objectivesScrollArea")
            if objectivesScrollArea then
                objectivesScrollArea.children = buildObjectivesList()
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
                        QTQuestManagerWindow.instance:FireEvent("refreshAll")
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
                    noteChildren[#noteChildren + 1] = gui.Divider { width = "90%" }
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
        height = "100%",
        flow = "vertical",
        hpad = 20,
        vpad = 20,
        styles = QTQuestManagerWindow._getDialogStyles(),
        monitorGame = questManager:GetDocumentPath(),
        refreshGame = function(element)
            -- Rebuild notes list when document changes
            local notesScrollArea = element:Get("notesScrollArea")
            if notesScrollArea then
                notesScrollArea.children = buildNotesList()
            end
        end,
        children = {
            -- Scrollable notes area
            gui.Panel{
                id = "notesScrollArea",
                width = "100%",
                height = "90%",
                flow = "vertical",
                vscroll = true,
                valign = "top",
                children = buildNotesList()
            },

            -- Add note button (always visible at bottom)
            gui.AddButton {
                halign = "right",
                vmargin = 5,
                hmargin = 100,
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

    -- Build delete button if user has permission
    local headerChildren = {
        gui.Label {
            text = "By: " .. authorId .. " at " .. displayTimestamp,
            width = "85%",
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
                local displayText = "Are you sure you want to delete this note?"
                local onConfirm = function()
                    quest:RemoveNote(note.id)
                end
                -- We'd need to expose the confirmation dialog somehow
                -- For now, let's create a simple confirmation
                QTQuestManagerWindow.ShowDeleteNoteConfirmation(quest, note.id)
            end
        }
    end

    return gui.Panel {
        width = "90%",
        height = "auto",
        flow = "vertical",
        vmargin = 5,
        children = {
            -- Header with author, timestamp, and delete button
            gui.Panel {
                width = "100%",
                height = 25,
                flow = "horizontal",
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
                local questWindow = QTQuestManagerWindow.instance.windowElement
                QTQuestManagerWindow.ShowDeleteObjectiveConfirmation(quest, objective.id, title, questWindow)
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
            -- Header with title, status, and delete button
            gui.Panel {
                width = "100%",
                height = 30,
                vmargin = 15,
                flow = "horizontal",
                valign = "top",
                children = {
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
                                -- Update quest modified timestamp
                                quest:UpdateProperties({}, "Updated objective title")
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
                                    QTQuestManagerWindow.instance:FireEvent("refreshAll")
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
                        -- Update quest modified timestamp
                        quest:UpdateProperties({}, "Updated objective description")
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
        id = "addNoteModal",
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
        styles = QTQuestManagerWindow._getDialogStyles(),

        children = {
            -- Title
            gui.Label{
                text = "Add Note",
                width = "100%",
                height = 30,
                classes = {"QTLabel", "QTBase"},
                textAlignment = "center",
                halign = "center"
            },

            -- Note content input (using a large input field as text area)
            gui.Input{

                -- width = "100%",
                -- height = 70,
                -- classes = {"QTInput", "QTBase"},
                -- text = quest:GetDescription() or "",
                -- placeholderText = "Enter quest description...",
                -- lineType = "MultiLine",
                -- textAlignment = "topleft"

                id = "noteContentInput",
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

            -- Button panel (matching main window structure)
            gui.Panel{
                width = "auto",
                height = 50,
                halign = "center",
                valign = "center",
                flow = "horizontal",
                children = {
                    -- Confirm button
                    gui.Button{
                        text = "Confirm",
                        width = 120,
                        height = 40,
                        hmargin = 40,
                        classes = {"QTButton", "QTBase"},
                        click = function(element)
                            if noteContent and noteContent:trim() ~= "" then
                                quest:AddNote(noteContent, dmhub.userid)
                                -- Use FireEvent refreshAll pattern like character sheet
                                if QTQuestManagerWindow.instance then
                                    QTQuestManagerWindow.instance:FireEvent("refreshAll")
                                end
                            end
                            element:Get("addNoteModal"):DestroySelf()
                        end
                    },
                    -- Cancel button
                    gui.Button{
                        text = "Cancel",
                        width = 120,
                        height = 40,
                        hmargin = 40,
                        classes = {"QTButton", "QTBase"},
                        escapeActivates = true,
                        click = function(element)
                            element:Get("addNoteModal"):DestroySelf()
                        end
                    }
                }
            }
        },

        -- ESC key support
        escape = function(element)
            element:DestroySelf()
        end
    }

    -- Add to main dialog panel
    if gamehud and gamehud.mainDialogPanel then
        gamehud.mainDialogPanel:AddChild(addNoteWindow)
    end
end

--- Shows confirmation dialog for deleting a note
--- @param quest QTQuest The quest object
--- @param noteId string The note ID to delete
function QTQuestManagerWindow.ShowDeleteNoteConfirmation(quest, noteId)
    local displayText = "Are you sure you want to delete this note?"
    local onConfirm = function()
        quest:RemoveNote(noteId)
        -- Use FireEvent refreshAll pattern like character sheet
        if QTQuestManagerWindow.instance then
            QTQuestManagerWindow.instance:FireEvent("refreshAll")
        end
    end

    -- Create a simple confirmation dialog
    local confirmationWindow = gui.Panel{
        id = "deleteNoteModal",
        width = 400,
        height = 150,
        halign = "center",
        valign = "center",
        floating = "true",
        bgcolor = "#111111ff",
        borderWidth = 2,
        borderColor = Styles.textColor,
        bgimage = "panels/square.png",
        flow = "vertical",
        hpad = 20,
        vpad = 20,

        children = {
            gui.Label{
                text = displayText,
                width = "100%",
                height = 60,
                fontSize = 14,
                color = Styles.textColor,
                textAlignment = "center",
                textWrap = true,
                halign = "center",
                vmargin =50
            },

            gui.Panel{
                width = "100%",
                height = 40,
                flow = "horizontal",
                halign = "center",
                valign = "center",
                children = {
                    gui.Button{
                        text = "Delete",
                        width = 80,
                        height = 30,
                        hmargin = 10,
                        fontSize = 14,
                        bgcolor = "#cc0000",
                        color = "white",
                        bold = true,
                        click = function(element)
                            onConfirm()
                            element:Get("deleteNoteModal"):DestroySelf()
                        end
                    },
                    gui.Button{
                        text = "Cancel",
                        width = 80,
                        height = 30,
                        hmargin = 10,
                        fontSize = 14,
                        color = Styles.textColor,
                        click = function(element)
                            element:Get("deleteNoteModal"):DestroySelf()
                        end
                    }
                }
            }
        },

        escape = function(element)
            element:DestroySelf()
        end
    }

    if gamehud and gamehud.mainDialogPanel then
        gamehud.mainDialogPanel:AddChild(confirmationWindow)
    end
end


--- Shows confirmation dialog for deleting an objective
--- @param quest QTQuest The quest object
--- @param objectiveId string The objective ID to delete
--- @param objectiveTitle string The objective title for display
function QTQuestManagerWindow.ShowDeleteObjectiveConfirmation(quest, objectiveId, objectiveTitle, parentWindow)
    local displayText = "Are you sure you want to delete objective \"" .. (objectiveTitle or "Untitled") .. "\"?"

    local confirmationWindow = gui.Panel{
        width = 400,
        height = 200,
        halign = "center",
        valign = "center",
        bgcolor = "#111111ff",
        borderWidth = 2,
        borderColor = Styles.textColor,
        bgimage = "panels/square.png",
        flow = "vertical",
        hpad = 20,
        vpad = 20,
        styles = QTQuestManagerWindow._getDialogStyles(),

        children = {
            -- Header
            gui.Label{
                text = "Delete Confirmation",
                width = "100%",
                height = 30,
                fontSize = 30,
                classes = {"QTLabel", "QTBase"},
                textAlignment = "center",
                halign = "center"
            },

            -- Confirmation message
            gui.Label{
                text = displayText,
                width = "100%",
                height = 80,
                classes = {"QTLabel", "QTBase"},
                textAlignment = "center",
                textWrap = true,
                halign = "center",
                valign = "center"
            },

            -- Button panel
            gui.Panel{
                width = "100%",
                height = 40,
                flow = "horizontal",
                halign = "center",
                valign = "center",
                children = {
                    -- Cancel button (first)
                    gui.Button{
                        text = "Cancel",
                        width = 120,
                        height = 40,
                        hmargin = 10,
                        classes = {"QTButton", "QTBase"},
                        click = function(element)
                            gui.CloseModal()
                        end
                    },
                    -- Delete button (second)
                    gui.Button{
                        text = "Delete",
                        width = 120,
                        height = 40,
                        hmargin = 10,
                        classes = {"QTButton", "QTBase"},
                        click = function(element)
                            quest:RemoveObjective(objectiveId)
                            if QTQuestManagerWindow.instance then
                                QTQuestManagerWindow.instance:FireEvent("refreshAll")
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

    gui.ShowModal(confirmationWindow)
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
        styles = QTQuestManagerWindow._getDialogStyles(),
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


            -- Timestamps row
            -- gui.Panel{
            --     width = "100%",
            --     height = 40,
            --     flow = "horizontal",
            --     vmargin = 5,
            --     children = {
            --         gui.Panel{
            --             width = "50%",
            --             height = 40,
            --             flow = "horizontal",
            --             valign = "center",
            --             children = {
            --                 gui.Label{
            --                     text = "Created:",
            --                     classes = {"field-label"},
            --                     width = "25%",
            --                     height = 30,
            --                     valign = "center"
            --                 },
            --                 createdTimestampLabel
            --             }
            --         },
            --         gui.Panel{
            --             width = "50%",
            --             height = 40,
            --             flow = "horizontal",
            --             valign = "center",
            --             children = {
            --                 gui.Label{
            --                     text = "Modified:",
            --                     classes = {"field-label"},
            --                     width = "25%",
            --                     height = 30,
            --                     valign = "center"
            --                 },
            --                 modifiedTimestampLabel
            --             }
            --         }
            --     }
            -- }
        }
    }
end

--- Gets the styling configuration for the dialog form
--- @return table styles Array of GUI styles for the dialog using QTBase inheritance
function QTQuestManagerWindow._getDialogStyles()
    return {
        -- QTBase: Foundation style for all Quest Manager controls
        gui.Style{
            selectors = {"QTBase"},
            fontSize = 18,
            fontFace = "Berling",
            color = Styles.textColor,
            height = 40,
        },

        -- QT Control Types: Inherit from QTBase, add specific properties
        gui.Style{
            selectors = {"QTLabel", "QTBase"},
            bold = true,
            textAlignment = "left"
        },
        gui.Style{
            selectors = {"QTInput", "QTBase"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"QTDropdown", "QTBase"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"QTCheck", "QTBase"},
            -- Inherits all QTBase properties
        },
        gui.Style{
            selectors = {"QTButton", "QTBase"},
            fontSize = 22,
            textAlignment = "center",
            bold = true,
            height = 35  -- Override QTBase height for buttons
        },

        -- Legacy dialog styles (kept for compatibility)
        gui.Style{
            selectors = {"dialog-header"},
            bgcolor = Styles.textColor,
            color = Styles.backgroundColor
        },
        gui.Style{
            selectors = {"dialog-title"},
            fontSize = 18,
            bold = true,
            textAlignment = "left"
        },
        gui.Style{
            selectors = {"dialog-content"}
        },
    }
end

--- Builds a single quest item for display
--- @param quest QTQuest The quest to display
--- @param questManager QTQuestManager The quest manager instance
--- @return table panel The quest item panel
function QTQuestManagerWindow._buildQuestItem(quest, questManager)
    local title = quest:GetTitle() or "Untitled Quest"
    local status = quest:GetStatus() or "unknown"
    local category = quest:GetCategory() or "unknown"
    local priority = quest:GetPriority() or "medium"

    -- Status display formatting
    local statusText = status:gsub("_", " "):gsub("(%l)(%w*)", function(a, b)
        return string.upper(a) .. b
    end)

    return gui.Panel{
        width = "100%",
        height = 60,
        flow = "horizontal",
        bgcolor = Styles.backgroundColor,
        borderWidth = 1,
        borderColor = Styles.textColor,
        vmargin = 2,
        click = function()
            QTQuestManagerWindow._showEditQuestDialog(questManager, quest.id)
        end,
        children = {
            -- Status indicator
            gui.Panel{
                width = 6,
                height = "100%",
                bgcolor = status == "active" and "green" or
                         status == "completed" and "blue" or
                         status == "failed" and "red" or
                         Styles.textColor
            },
            -- Quest content
            gui.Panel{
                width = "90%",
                height = "100%",
                flow = "vertical",
                hmargin = 10,
                children = {
                    gui.Label{
                        text = title,
                        width = "100%",
                        height = 30,
                        fontSize = 16,
                        color = Styles.textColor,
                        bold = true,
                        textAlignment = "left",
                        valign = "center"
                    },
                    gui.Panel{
                        width = "100%",
                        height = 25,
                        flow = "horizontal",
                        children = {
                            gui.Label{
                                text = statusText,
                                width = "33%",
                                height = 25,
                                fontSize = 12,
                                color = Styles.textColor,
                                textAlignment = "left",
                                valign = "center"
                            },
                            gui.Label{
                                text = category:gsub("_", " "),
                                width = "33%",
                                height = 25,
                                fontSize = 12,
                                color = Styles.textColor,
                                textAlignment = "center",
                                valign = "center"
                            },
                            gui.Label{
                                text = priority .. " priority",
                                width = "34%",
                                height = 25,
                                fontSize = 12,
                                color = Styles.textColor,
                                textAlignment = "right",
                                valign = "center"
                            }
                        }
                    }
                }
            },
            -- Action indicator
            gui.Panel{
                width = "10%",
                height = "100%",
                children = {
                    gui.Label{
                        text = "...",
                        width = "100%",
                        height = "100%",
                        fontSize = 14,
                        color = Styles.textColor,
                        bold = true,
                        halign = "center",
                        valign = "center",
                        textAlignment = "center"
                    }
                }
            }
        }
    }
end

--- Shows the quest dialog for creating new quests
--- @param questManager QTQuestManager The quest manager instance
function QTQuestManagerWindow._showNewQuestDialog(questManager)
    local dialog = QTQuestDialog:new(questManager)
    if dialog then
        dialog:Show()
    end
end

--- Shows the quest dialog for editing existing quests
--- @param questManager QTQuestManager The quest manager instance
--- @param questId string The ID of the quest to edit
function QTQuestManagerWindow._showEditQuestDialog(questManager, questId)
    local dialog = QTQuestDialog:new(questManager, questId)
    if dialog then
        dialog:Show()
    end
end