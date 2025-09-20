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
        minHeight = 18,
        maxHeight = 18,
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
            local headerPanel = questTrackerPanel:_buildHeaderPanel()
            local contentPanel = questTrackerPanel:_buildContentPanel()
            element.children = {headerPanel, contentPanel}
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
    return gui.Panel {
        width = "100%",
        height = "40",
        flow = "horizontal",
        halign = "center",
        children = {
            gui.Label {
                text = "Quest Tracker",
                classes = {"header-title"},
                width = "75%"
            },
            gui.Button {
                text = "+ New",
                classes = {"header-button"},
                width = "25%",
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
            -- Header for quest list
            questChildren[#questChildren + 1] =
                gui.Label {
                text = "Active Quests (" .. #allQuests .. ")",
                classes = {"quest-list-header"},
                width = "100%",
                height = 25
            }

            -- Display each quest
            for _, quest in ipairs(allQuests) do
                questChildren[#questChildren + 1] = self:_buildQuestItem(quest)
            end
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
        height = "300",
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
            -- Action button (placeholder for future edit functionality)
            gui.Panel {
                width = "10%",
                height = "100%",
                children = {
                    gui.Label {
                        text = "...",
                        classes = {"quest-actions"},
                        width = "100%",
                        height = "100%",
                        halign = "center",
                        valign = "center",
                        textAlignment = "center"
                    }
                }
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
