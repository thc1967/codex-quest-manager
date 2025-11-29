local mod = dmhub.GetModLoading()

--- Quest Tracker Panel - Main dockable panel for quest management
--- Provides the primary interface for viewing and managing quests in the Codex VTT
--- @class QMQuestTrackerPanel
--- @field questManager QMQuestManager The quest manager instance for data operations
QMQuestTrackerPanel = RegisterGameType("QMQuestTrackerPanel")
QMQuestTrackerPanel.__index = QMQuestTrackerPanel

--- Creates a new Quest Tracker Panel instance
--- @param questManager QMQuestManager The quest manager instance for data operations
--- @return QMQuestTrackerPanel|nil instance The new panel instance
function QMQuestTrackerPanel:new(questManager)
    if not questManager then return nil end

    local instance = setmetatable({}, self)
    instance.questManager = questManager
    return instance
end

--- Registers the dockable panel with the Codex UI system
--- Creates and configures the main quest tracker interface
function QMQuestTrackerPanel:Register()
    local questTrackerPanel = self
    DockablePanel.Register {
        name = "Quest Manager",
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
function QMQuestTrackerPanel:_buildMainPanel()
    local questTrackerPanel = self
    return gui.Panel {
        id = "questTrackerController",
        classes = {"questTrackerController"},
        width = "96%",
        height = "auto",
        flow = "vertical",
        styles = questTrackerPanel:_getMainStyles(),
        monitorGame = questTrackerPanel.questManager:GetDocumentPath(),
        refreshGame = function(element)
            questTrackerPanel:_refreshPanelContent(element)
        end,
        show = function(element)
            questTrackerPanel:_refreshPanelContent(element)
        end,
        openQuest = function(element, questId)
            local quest = questTrackerPanel.questManager:GetQuest(questId)
            if quest then
                local questManagerWindow = QMQuestManagerWindow:new(quest)
                if questManagerWindow then
                    questManagerWindow:Show()
                end
            end
        end,
        children = {
            self:_buildHeaderPanel(),
            self:_buildContentPanel()
        }
    }
end

--- Builds the header panel containing title and controls
--- @return table panel The header panel with title and action buttons
function QMQuestTrackerPanel:_buildHeaderPanel()
    local questCount = 0
    if self.questManager then
        _, questCount = self.questManager:GetAllQuests()
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
                width = "40%"
            },
            -- gui.Button{
            --     text = "INIT",
            --     width = 60,
            --     height = 30,
            --     halign = "right",
            --     valign = "center",
            --     hmargin = 5,
            --     linger = function(element)
            --         gui.Tooltip("Clear all data.")(element)
            --     end,
            --     click = function(element)
            --         self.questManager:InitializeDocument()
            --     end
            -- },
            -- gui.Button {
            --     text = "DEBUG",
            --     width = 60,
            --     height = 30,
            --     halign = "right",
            --     valign = "center",
            --     hmargin = 5,
            --     linger = function(element)
            --         gui.Tooltip("Debug document contents")(element)
            --     end,
            --     click = function(element)
            --         print("THC::", element)
            --         self:_debugDocument()
            --     end
            -- },
            gui.AddButton {
                halign = "right",
                valign = "center",
                linger = function(element)
                    gui.Tooltip("Add a new quest")(element)
                end,
                click = function(element)
                    local quest = self.questManager:CreateQuest()
                    if quest then
                        local controller = element:FindParentWithClass("questTrackerController")
                        if controller then
                            dmhub.Schedule(0.3, function()
                                controller:FireEvent("openQuest", quest:GetID())
                            end)
                        end
                    end
                end
            }
        }
    }
end

--- Builds the main content panel for quest display
--- @return table panel The content panel containing categorized quest sections
function QMQuestTrackerPanel:_buildContentPanel()
    local questChildren = {}

    if self.questManager then
        local allQuests, questCount = self.questManager:GetAllQuests()

        if questCount == 0 then
            questChildren[#questChildren + 1] =
                gui.Label {
                text = "No quests yet.",
                classes = {"empty-state"},
                width = "100%",
                height = "100%",
                halign = "center",
                valign = "center",
                textAlignment = "center"
            }
        else
            -- Separate quests into titled and untitled
            local titledQuests = {}
            local untitledQuests = {}
            for _, quest in pairs(allQuests) do
                if self:_isQuestUntitled(quest) then
                    table.insert(untitledQuests, quest)
                else
                    table.insert(titledQuests, quest)
                end
            end

            local hasAnyContent = false

            -- Add untitled quests section first (if any)
            if #untitledQuests > 0 then
                questChildren[#questChildren + 1] = self:_buildUntitledQuestsSection(untitledQuests)
                hasAnyContent = true
            end

            -- Group titled quests by category
            local questsByCategory = {}
            for _, quest in pairs(titledQuests) do
                local category = quest:GetCategory() or QMQuest.CATEGORY.MAIN
                if not questsByCategory[category] then
                    questsByCategory[category] = {}
                end
                table.insert(questsByCategory[category], quest)
            end

            -- Define display order for categories
            local categoryOrder = {
                QMQuest.CATEGORY.MAIN,
                QMQuest.CATEGORY.SIDE,
                QMQuest.CATEGORY.PERSONAL,
                QMQuest.CATEGORY.FACTION,
                QMQuest.CATEGORY.TUTORIAL
            }

            -- Create collapsible sections for each category that has quests
            for _, categoryId in ipairs(categoryOrder) do
                local categoryQuests = questsByCategory[categoryId]
                if categoryQuests and #categoryQuests > 0 then
                    if hasAnyContent then
                        -- Add spacing between sections
                        questChildren[#questChildren + 1] = gui.Divider { width = "80%" }
                    end
                    questChildren[#questChildren + 1] = self:_buildCategorySection(categoryId, categoryQuests)
                    hasAnyContent = true
                end
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
        height = "auto",
        flow = "vertical",
        styles = self:_getContentStyles(),
        children = questChildren
    }
end

--- Checks if a quest is considered untitled (nil, empty, or whitespace-only title)
--- @param quest QMQuest The quest to check
--- @return boolean true if the quest is untitled
function QMQuestTrackerPanel:_isQuestUntitled(quest)
    local title = quest:GetTitle()
    return not title or title:trim() == ""
end

--- Builds a single quest item display
--- @param quest QMQuest The quest to display
--- @param untitledDisplayText string Optional display text for untitled quests
--- @return table panel The quest item panel
function QMQuestTrackerPanel:_buildQuestItem(quest, untitledDisplayText)
    local title = quest:GetTitle()
    if self:_isQuestUntitled(quest) then
        title = untitledDisplayText or "Untitled Quest"
    end
    local status = quest:GetStatus() or "unknown"
    local priority = quest:GetPriority() or "unknown"

    -- Build action buttons array conditionally
    local actionButtons = {
        gui.SettingsButton {
            width = 20,
            height = 20,
            halign = "center",
            valign = "center",
            hmargin = 2,
            classes = {"quest-edit-button"},
            press = function(element)
                element:FireEventOnParents("openQuest", quest:GetID())
            end
        }
    }

    -- Add delete button only for DM or quest creator
    if dmhub.isDM or dmhub.userid == quest:GetCreatedBy() then
        actionButtons[#actionButtons + 1] = gui.DeleteItemButton {
            width = 20,
            height = 20,
            halign = "center",
            valign = "center",
            hmargin = 2,
            classes = {"quest-delete-button"},
            click = function()
                QMUIUtils.ShowDeleteConfirmation("quest", title, function()
                    self.questManager:DeleteQuest(quest:GetID())
                end)
            end
        }
    end

    return gui.Panel {
        width = "96%",
        height = 50,
        flow = "horizontal",
        classes = {"quest-item", "quest-" .. status, "priority-" .. priority},
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
                        height = 20,
                        textAlignment = "left"
                    },
                    gui.Panel {
                        width = "100%",
                        height = 15,
                        flow = "horizontal",
                        children = {
                            gui.Label {
                                text = string.format("%s; %s Priority", status, priority),
                                classes = {"quest-status"},
                                width = "100%",
                                height = 15,
                                textAlignment = "left"
                            },
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

--- Builds a section for untitled quests without a category header
--- @param untitledQuests table Array of QMQuest instances that are untitled
--- @return table panel The untitled quests section panel
function QMQuestTrackerPanel:_buildUntitledQuestsSection(untitledQuests)
    local questChildren = {}

    -- Add quest items with dividers
    for i, quest in ipairs(untitledQuests) do
        -- Add divider before quest (except first one)
        if i > 1 then
            questChildren[#questChildren + 1] = gui.Divider { width = "80%" }
        end
        -- Quest item with "(New Quest)" display text
        questChildren[#questChildren + 1] = self:_buildQuestItem(quest, "(New Quest)")
    end

    return gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        classes = {"untitled-quests-section"},
        children = questChildren
    }
end

--- Maps quest category IDs to user-friendly display names
--- @param categoryId string The category ID from QMQuest.CATEGORY
--- @return string displayName The user-friendly category name
function QMQuestTrackerPanel:_getCategoryDisplayName(categoryId)
    if not categoryId or categoryId == "" then
        return "Other Quests"
    end

    return categoryId .. " Quests"
end

-- Triangle icon styles (based on MapsPanel pattern)
local triangleStyles = {
    gui.Style{
        selectors = {"category-triangle"},
        bgimage = "panels/triangle.png",
        bgcolor = "white",
        hmargin = 4,
        halign = "left",
        valign = "center",
        height = 12,
        width = 12,
        rotate = 90,
    },
    gui.Style{
        selectors = {"category-triangle", "expanded"},
        rotate = 0,
        transitionTime = 0.2,
    },
    gui.Style{
        selectors = {"category-triangle", "hover"},
        bgcolor = "yellow",
    },
    gui.Style{
        selectors = {"category-triangle", "press"},
        bgcolor = "gray",
    },
}

--- Builds a collapsible header for a quest category
--- @param categoryId string The category ID from QMQuest.CATEGORY
--- @param questCount number The number of quests in this category
--- @param contentPanel table The content panel that this header will toggle
--- @return table panel The category header panel with triangle and label
function QMQuestTrackerPanel:_buildCategoryHeader(categoryId, questCount, contentPanel)
    local categoryName = self:_getCategoryDisplayName(categoryId)
    local prefKey = string.format("questcategory:%s:%s", categoryId, dmhub.gameid or "default")
    local isExpanded = dmhub.GetPref(prefKey) or false

    local triangle = gui.Panel{
        classes = {"category-triangle", isExpanded and "expanded" or nil},
        styles = triangleStyles,
        click = function(element)
            local isExpanded = not element:HasClass("expanded") -- Toggle current state
            element:SetClass("expanded", isExpanded)
            if contentPanel then
                contentPanel:SetClass("collapsed", not isExpanded)
            end
            dmhub.SetPref(prefKey, isExpanded)
        end
    }

    return gui.Panel{
        width = "100%",
        height = 30,
        flow = "horizontal",
        classes = {"category-header"},
        children = {
            triangle,
            gui.Label{
                text = categoryName .. " (" .. questCount .. ")",
                classes = {"category-title"},
                width = "auto",
                height = "100%",
                valign = "center",
                hmargin = 8
            }
        }
    }
end

--- Builds the collapsible content area for a quest category
--- @param categoryQuests table Array of QMQuest instances for this category
--- @param categoryId string The category ID to check collapse state
--- @return table panel The content panel containing quest items
function QMQuestTrackerPanel:_buildCategoryContent(categoryQuests, categoryId)
    local questChildren = {}

    -- Add quest items with dividers
    for i, quest in ipairs(categoryQuests) do
        -- Add divider before quest (except first one)
        if i > 1 then
            questChildren[#questChildren + 1] = gui.Divider { width = "80%" }
        end
        -- Quest item
        questChildren[#questChildren + 1] = self:_buildQuestItem(quest)
    end

    -- Check collapse state from preferences
    local prefKey = string.format("questcategory:%s:%s", categoryId, dmhub.gameid or "default")
    local isExpanded = dmhub.GetPref(prefKey) or false

    -- Build CSS classes array with conditional collapsed class
    local classes = {"category-content"}
    if not isExpanded then
        table.insert(classes, "collapsed")
    end

    return gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        classes = classes,
        children = questChildren
    }
end

--- Builds a complete collapsible section for a quest category
--- @param categoryId string The category ID from QMQuest.CATEGORY
--- @param categoryQuests table Array of QMQuest instances for this category
--- @return table panel The complete category section with header and collapsible content
function QMQuestTrackerPanel:_buildCategorySection(categoryId, categoryQuests)
    local questCount = #categoryQuests

    -- Build content panel first so we can pass it to header for collapse control
    local contentPanel = self:_buildCategoryContent(categoryQuests, categoryId)

    -- Build header with reference to content panel
    local headerPanel = self:_buildCategoryHeader(categoryId, questCount, contentPanel)

    return gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        classes = {"category-section"},
        children = {
            headerPanel,
            contentPanel
        }
    }
end

--- Gets additional styling for content elements
--- @return table styles Array of GUI styles for content
function QMQuestTrackerPanel:_getContentStyles()
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
        -- Category section styling
        gui.Style {
            selectors = {"category-section"},
            width = "100%",
            margin = 2
        },
        gui.Style {
            selectors = {"category-header"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor,
            height = 30,
            margin = 1
        },
        gui.Style {
            selectors = {"category-header", "hover"},
            bgcolor = Styles.textColor,
            color = Styles.backgroundColor,
            brightness = 0.9
        },
        gui.Style {
            selectors = {"category-title"},
            fontSize = 16,
            bold = true,
            color = Styles.textColor,
            textAlignment = "left"
        },
        -- Category content styling
        gui.Style {
            selectors = {"category-content"},
            width = "98%",
            halign = "right",
            transitionTime = 0.2
        },
        gui.Style {
            selectors = {"category-content", "collapsed"},
            height = 0,
            hidden = 1
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
function QMQuestTrackerPanel:_getMainStyles()
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

--- Refreshes the panel display to show updated quest data
function QMQuestTrackerPanel:_refreshDisplay()
    -- The panel will automatically refresh when the document changes
    -- via the monitorGame and refreshGame mechanism
end

--- Refreshes the panel content (used by both refreshGame and show events)
--- @param element table The main panel element to refresh
function QMQuestTrackerPanel:_refreshPanelContent(element)
    local headerPanel = self:_buildHeaderPanel()
    local contentPanel = self:_buildContentPanel()
    element.children = {headerPanel, contentPanel}
end

--- Debug method to print the raw document contents from persistence
function QMQuestTrackerPanel:_debugDocument()
    local doc = self.questManager.mod:GetDocumentSnapshot("QMQuestLog")
    print("THC:: PERSISTED::", json(doc.data))
end
