local mod = dmhub.GetModLoading()

--- Quest Tracker Panel - Main dockable panel for quest management
--- Provides the primary interface for viewing and managing quests in the Codex VTT
--- @class QTQuestTrackerPanel
--- @field questManager QTQuestManager The quest manager instance for data operations
QTQuestTrackerPanel = RegisterGameType("QTQuestTrackerPanel")
QTQuestTrackerPanel.__index = QTQuestTrackerPanel

--- Creates a new Quest Tracker Panel instance
--- @param questManager QTQuestManager The quest manager instance for data operations
--- @return QTQuestTrackerPanel|nil instance The new panel instance
function QTQuestTrackerPanel:new(questManager)
    local instance = setmetatable({}, self)
    instance.questManager = questManager

    -- Validate we have required dependencies
    if not instance.questManager then
        return nil
    end

    return instance
end

--- Registers the dockable panel with the Codex UI system
--- Creates and configures the main quest tracker interface
function QTQuestTrackerPanel:Register()
    local questTrackerPanel = self
    DockablePanel.Register {
        name = "Quest Tracker",
        icon = mod.images.questManager,
        minHeight = 100,
        maxHeight = 600,
        content = function()
            local panel = questTrackerPanel:_buildMainPanel()
            questTrackerPanel.panelElement = panel
            return panel
        end
    }
end

--- Builds the main panel structure for the quest tracker
--- @return table panel The main GUI panel containing all quest tracker elements
function QTQuestTrackerPanel:_buildMainPanel()
    local questTrackerPanel = self
    return gui.Panel {
        width = "100%",
        height = "auto",
        flow = "vertical",
        styles = questTrackerPanel:_getMainStyles(),
        monitorGame = questTrackerPanel.questManager:GetDocumentPath(),
        refreshGame = function(element)
            questTrackerPanel:_refreshPanelContent(element)
        end,
        show = function(element)
            -- Refresh content when panel becomes visible
            questTrackerPanel:_refreshPanelContent(element)
        end,
        children = {
            self:_buildHeaderPanel(),
            self:_buildContentPanel()
        }
    }
end

--- Builds the header panel containing title and controls
--- @return table panel The header panel with title and action buttons
function QTQuestTrackerPanel:_buildHeaderPanel()
    local questCount = 0
    if self.questManager then
        local allQuests = self.questManager:GetAllQuests()
        questCount = #allQuests
    end

    return gui.Panel {
        width = "100%",
        height = "40",
        flow = "horizontal",
        halign = "center",
        children = {
            gui.Label {
                text = "Active Quests (" .. questCount .. ")",
                classes = {"header-title"},
                width = "75%"
            },
            gui.AddButton {
                -- width = "25%",
                -- hmargin = 15,
                halign = "right",
                valign = "center",
                linger = function(element)
                    gui.Tooltip("Add a new quest")(element)
                end,
                click = function(element)
                    self:_showNewQuestDialog()
                end
            }
        }
    }
end

--- Builds the main content panel for quest display
--- @return table panel The content panel containing quest list and details
function QTQuestTrackerPanel:_buildContentPanel()
    local questChildren = {}

    if self.questManager then
        local allQuests = self.questManager:GetAllQuests()

        if #allQuests == 0 then
            questChildren[#questChildren + 1] =
                gui.Label {
                text = "No quests yet. Click '+ New' to create your first quest!",
                classes = {"empty-state"},
                width = "100%",
                height = "100%",
                halign = "center",
                valign = "center",
                textAlignment = "center"
            }
        else
            -- Top divider
            questChildren[#questChildren + 1] = gui.Divider { width = "80%" }

            -- Display each quest with dividers between them
            for i, quest in ipairs(allQuests) do
                -- Add divider before quest (except first one)
                if i > 1 then
                    questChildren[#questChildren + 1] = gui.Divider { width = "80%" }
                end
                -- Quest item
                questChildren[#questChildren + 1] = self:_buildQuestItem(quest)
            end

            -- Bottom divider
            questChildren[#questChildren + 1] = gui.Divider { width = "80%" }
        end
    else
        questChildren[#questChildren + 1] =
            gui.Label {
            text = "Quest Manager not available",
            classes = {"error-state"},
            width = "100%",
            height = "100%"
        }
    end

    return gui.Panel {
        width = "100%",
        height = "auto",
        flow = "vertical",
        styles = self:_getContentStyles(),
        children = questChildren
    }
end

--- Builds a single quest item display
--- @param quest QTQuest The quest to display
--- @return table panel The quest item panel
function QTQuestTrackerPanel:_buildQuestItem(quest)
    local title = quest:GetTitle() or "Untitled Quest"
    local status = quest:GetStatus() or "unknown"
    local category = quest:GetCategory() or "unknown"
    local priority = quest:GetPriority() or "medium"

    -- Status display formatting
    local statusText =
        status:gsub("_", " "):gsub(
        "(%l)(%w*)",
        function(a, b)
            return string.upper(a) .. b
        end
    )

    -- Build action buttons array conditionally
    local actionButtons = {
        -- Edit button (always visible)
        gui.SettingsButton {
            width = 20,
            height = 20,
            halign = "center",
            valign = "center",
            hmargin = 2,
            classes = {"quest-edit-button"},
            press = function()
                self:_showEditQuestDialog(quest.id)
            end
        }
    }

    -- Add delete button only for DM or quest creator
    local questCreator = quest:GetCreatedBy()
    if dmhub.isDM or dmhub.userid == questCreator then
        actionButtons[#actionButtons + 1] = gui.DeleteItemButton {
            width = 20,
            height = 20,
            halign = "center",
            valign = "center",
            hmargin = 2,
            classes = {"quest-delete-button"},
            click = function()
                self:_showDeleteConfirmation(quest.id, title)
            end
        }
    end

    return gui.Panel {
        width = "100%",
        height = 50,
        flow = "horizontal",
        classes = {"quest-item", "quest-" .. status, "priority-" .. priority},
        click = function()
            self:_showEditQuestDialog(quest.id)
        end,
        children = {
            -- Status indicator
            gui.Panel {
                width = 4,
                height = "100%",
                classes = {"status-indicator", "status-" .. status}
            },
            -- Quest content
            gui.Panel {
                width = "90%",
                height = "100%",
                flow = "vertical",
                children = {
                    gui.Label {
                        text = title,
                        classes = {"quest-title"},
                        width = "100%",
                        height = 25,
                        textAlignment = "left"
                    },
                    gui.Panel {
                        width = "100%",
                        height = 20,
                        flow = "horizontal",
                        children = {
                            gui.Label {
                                text = statusText,
                                classes = {"quest-status"},
                                width = "33%",
                                height = 20,
                                textAlignment = "left"
                            },
                            gui.Label {
                                text = category:gsub("_", " "),
                                classes = {"quest-category"},
                                width = "33%",
                                height = 20,
                                textAlignment = "center"
                            },
                            gui.Label {
                                text = priority .. " priority",
                                classes = {"quest-priority"},
                                width = "34%",
                                height = 20,
                                textAlignment = "right"
                            }
                        }
                    }
                }
            },
            -- Action buttons (edit and delete)
            gui.Panel {
                width = "10%",
                height = "100%",
                flow = "horizontal",
                halign = "center",
                valign = "center",
                children = actionButtons
            }
        }
    }
end

--- Gets additional styling for content elements
--- @return table styles Array of GUI styles for content
function QTQuestTrackerPanel:_getContentStyles()
    return {
        gui.Style {
            selectors = {"empty-state"},
            color = Styles.textColor,
            fontSize = 14,
            -- fontStyle = "italic"
        },
        gui.Style {
            selectors = {"error-state"},
            color = "red",
            fontSize = 14,
            bold = true
        },
        gui.Style {
            selectors = {"quest-list-header"},
            color = Styles.textColor,
            fontSize = 16,
            bold = true,
            textAlignment = "left",
            -- padding = 5
        },
        gui.Style {
            selectors = {"quest-item"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor,
            margin = 2,
            -- padding = 5
        },
        gui.Style {
            selectors = {"quest-item", "hover"},
            bgcolor = Styles.textColor,
            color = Styles.backgroundColor,
            brightness = 0.9
        },
        gui.Style {
            selectors = {"status-indicator"},
            bgcolor = Styles.textColor
        },
        gui.Style {
            selectors = {"status-indicator", "status-active"},
            bgcolor = "green"
        },
        gui.Style {
            selectors = {"status-indicator", "status-completed"},
            bgcolor = "blue"
        },
        gui.Style {
            selectors = {"status-indicator", "status-failed"},
            bgcolor = "red"
        },
        gui.Style {
            selectors = {"quest-title"},
            fontSize = 14,
            bold = true,
            color = Styles.textColor
        },
        gui.Style {
            selectors = {"quest-status"},
            fontSize = 11,
            color = Styles.textColor
        },
        gui.Style {
            selectors = {"quest-category"},
            fontSize = 11,
            color = Styles.textColor,
            -- fontStyle = "italic"
        },
        gui.Style {
            selectors = {"quest-priority"},
            fontSize = 11,
            color = Styles.textColor
        },
        gui.Style {
            selectors = {"quest-actions"},
            fontSize = 12,
            color = Styles.textColor,
            bold = true
        }
    }
end

--- Gets the styling configuration for the main panel
--- @return table styles Array of GUI styles for the quest tracker interface
function QTQuestTrackerPanel:_getMainStyles()
    return {
        gui.Style {
            selectors = {"header-title"},
            color = Styles.textColor,
            fontSize = 18,
            bold = true,
            valign = "center",
            halign = "left",
            textAlignment = "left"
        },
        gui.Style {
            selectors = {"header-button"},
            color = Styles.textColor,
            fontSize = 14,
            textAlignment = "center",
            valign = "center",
            halign = "center",
            bgimage = "panels/square.png",
            borderWidth = 1,
            borderColor = Styles.black
        },
        gui.Style {
            selectors = {"header-button", "hover"},
            bgcolor = Styles.textColor,
            color = "black",
            brightness = 0.9
        },
        gui.Style {
            selectors = {"content-placeholder"},
            color = Styles.textColor,
            fontSize = 14,
            valign = "center",
            halign = "center",
            textAlignment = "center",
            bgimage = "panels/square.png",
            borderWidth = 1,
            borderColor = Styles.black
        }
    }
end

--- Shows the quest dialog for creating new quests
function QTQuestTrackerPanel:_showNewQuestDialog()
    local draftQuest = self.questManager:CreateDraftQuest("New Quest", dmhub.playerId)
    local questManagerWindow = QTQuestManagerWindow:new(self.questManager, draftQuest)
    if questManagerWindow then
        questManagerWindow:Show()
    end
end

--- Shows the quest dialog for editing existing quests
--- @param questId string The ID of the quest to edit
function QTQuestTrackerPanel:_showEditQuestDialog(questId)
    local quest = self.questManager:GetQuest(questId)
    if quest then
        local questManagerWindow = QTQuestManagerWindow:new(self.questManager, quest)
        if questManagerWindow then
            questManagerWindow:Show()
        end
    end
end

--- Shows a reusable confirmation dialog
--- @param displayText string The message to show in the confirmation dialog
--- @param onConfirm function The callback function to call if user confirms
function QTQuestTrackerPanel:_showConfirmationDialog(displayText, onConfirm)
    local confirmationWindow = gui.Panel{
        id = "deleteConfirmationModal",
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

        children = {
            -- Title
            gui.Label{
                text = "Confirm Action",
                width = "100%",
                height = 30,
                fontSize = 18,
                bold = true,
                color = Styles.textColor,
                textAlignment = "center",
                halign = "center"
            },

            -- Confirmation message
            gui.Label{
                text = displayText,
                width = "100%",
                height = 60,
                fontSize = 14,
                color = Styles.textColor,
                textAlignment = "center",
                textWrap = true,
                halign = "center",
                vmargin = 10
            },

            -- Button panel
            gui.Panel{
                width = "100%",
                height = 40,
                flow = "horizontal",
                halign = "center",
                valign = "center",
                children = {
                    -- Confirm button
                    gui.Button{
                        text = "Confirm",
                        width = 80,
                        height = 30,
                        hmargin = 10,
                        fontSize = 14,
                        bgcolor = "#cc0000",
                        color = "white",
                        bold = true,
                        click = function(element)
                            onConfirm()
                            element:Get("deleteConfirmationModal"):DestroySelf()
                        end
                    },
                    -- Cancel button
                    gui.Button{
                        text = "Cancel",
                        width = 80,
                        height = 30,
                        hmargin = 10,
                        fontSize = 14,
                        color = Styles.textColor,
                        click = function(element)
                            element:Get("deleteConfirmationModal"):DestroySelf()
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
        gamehud.mainDialogPanel:AddChild(confirmationWindow)
    end
end

--- Shows a confirmation dialog before deleting a quest
--- @param questId string The ID of the quest to delete
--- @param questTitle string The title of the quest for confirmation message
function QTQuestTrackerPanel:_showDeleteConfirmation(questId, questTitle)
    local displayText = "Are you sure you want to delete quest " .. questTitle .. "?"
    local onConfirm = function()
        self.questManager:DeleteQuest(questId)
    end

    self:_showConfirmationDialog(displayText, onConfirm)
end

--- Shows the Quest Manager window
function QTQuestTrackerPanel:_showQuestManagerWindow()
    local questManagerWindow = QTQuestManagerWindow:new(self.questManager)
    if questManagerWindow then
        questManagerWindow:Show()
    end
end

--- Refreshes the panel display to show updated quest data
function QTQuestTrackerPanel:_refreshDisplay()
    -- The panel will automatically refresh when the document changes
    -- via the monitorGame and refreshGame mechanism
end

--- Refreshes the panel content (used by both refreshGame and show events)
--- @param element table The main panel element to refresh
function QTQuestTrackerPanel:_refreshPanelContent(element)
    local headerPanel = self:_buildHeaderPanel()
    local contentPanel = self:_buildContentPanel()
    element.children = {headerPanel, contentPanel}
end
