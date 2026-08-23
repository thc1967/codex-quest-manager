local mod = dmhub.GetModLoading()

--- Quest Tracker Panel - Main dockable panel for quest management
--- Provides the primary interface for viewing and managing quests in the Codex VTT
--- @class QMQuestTrackerPanel
--- @field questManager QMQuestManager The quest manager instance for data operations
--- @field panelElement table|nil The registered panel's root element, set once the dock builds it
QMQuestTrackerPanel = RegisterGameType("QMQuestTrackerPanel")

--- Maps a quest status to the class that colors its left-edge stripe
local STATUS_STRIPE_CLASS = {
    [QMQuest.STATUS.ACTIVE] = "statusActive",
    [QMQuest.STATUS.COMPLETED] = "statusCompleted",
    [QMQuest.STATUS.FAILED] = "statusFailed",
    [QMQuest.STATUS.ON_HOLD] = "statusOnHold"
}

--- Maps a quest status to the theme token tinting its word in the meta line
local STATUS_TEXT_TOKEN = {
    [QMQuest.STATUS.ACTIVE] = "@success",
    [QMQuest.STATUS.COMPLETED] = "@info",
    [QMQuest.STATUS.FAILED] = "@danger",
    [QMQuest.STATUS.ON_HOLD] = "@warning"
}

--- Display order for quests within a category; lower sorts first
local STATUS_SORT_RANK = {
    [QMQuest.STATUS.ACTIVE] = 1,
    [QMQuest.STATUS.NOT_STARTED] = 2,
    [QMQuest.STATUS.ON_HOLD] = 3,
    [QMQuest.STATUS.COMPLETED] = 4,
    [QMQuest.STATUS.FAILED] = 5
}

--- Statuses whose quests are finished and render de-emphasized
local RESOLVED_STATUSES = {
    [QMQuest.STATUS.COMPLETED] = true,
    [QMQuest.STATUS.FAILED] = true
}

--- Display order for the category sections
local CATEGORY_ORDER = {
    QMQuest.CATEGORY.MAIN,
    QMQuest.CATEGORY.SIDE,
    QMQuest.CATEGORY.PERSONAL,
    QMQuest.CATEGORY.FACTION,
    QMQuest.CATEGORY.TUTORIAL
}

--- Builds the tracker's scoped style rules, following the panel design language:
--- transparent rows that surface on hover, hairline seams, small bold section
--- headers, and chrome that stays muted until the pointer reaches it.
--- @return table styles Array of rule tables for ThemeEngine.MergeTokens
local function BuildQuestTrackerStyles()
    return {
        {
            selectors = {"questUtilityRow"},
            flow = "horizontal",
            width = "100%",
            height = 24
        },
        {
            selectors = {"questPanelCount"},
            fontSize = 11,
            color = "@fgMuted",
            width = "auto",
            height = "auto",
            halign = "left",
            valign = "center",
            lmargin = 6
        },
        {
            selectors = {"questRule"},
            bgimage = true,
            bgcolor = "@border",
            opacity = 0.35,
            width = "100%",
            height = 1
        },
        {
            selectors = {"questSeam"},
            bgimage = true,
            bgcolor = "@border",
            opacity = 0.2,
            width = "100%",
            height = 1
        },
        {
            selectors = {"questSectionHeader"},
            flow = "horizontal",
            bgimage = true,
            bgcolor = "clear",
            width = "100%",
            height = 28,
            tmargin = 8
        },
        {
            selectors = {"questSectionHeader", "hover"},
            bgcolor = "@bgAlt",
            transitionTime = 0.1
        },
        {
            selectors = {"questSectionLabel"},
            fontSize = 13,
            bold = true,
            color = "@fg",
            width = "auto",
            height = "auto",
            halign = "left",
            valign = "center"
        },
        {
            selectors = {"questSectionLabel", "parent:hover"},
            color = "@fgStrong",
            transitionTime = 0.1
        },
        {
            selectors = {"questSectionCount"},
            fontSize = 11,
            color = "@fgMuted",
            width = "auto",
            height = "auto",
            halign = "right",
            valign = "center",
            rmargin = 6
        },
        {
            selectors = {"questRow"},
            flow = "horizontal",
            bgimage = true,
            bgcolor = "clear",
            width = "100%",
            height = 40
        },
        {
            selectors = {"questRow", "hover"},
            bgcolor = "@bgAlt",
            transitionTime = 0.1
        },
        {
            selectors = {"questStripe"},
            bgimage = true,
            bgcolor = "clear",
            width = 3,
            height = "100%"
        },
        {
            selectors = {"questStripe", "statusActive"},
            bgcolor = "@success"
        },
        {
            selectors = {"questStripe", "statusCompleted"},
            bgcolor = "@info"
        },
        {
            selectors = {"questStripe", "statusFailed"},
            bgcolor = "@danger"
        },
        {
            selectors = {"questStripe", "statusOnHold"},
            bgcolor = "@warning"
        },
        {
            selectors = {"questTitle"},
            fontSize = 12,
            color = "@fg",
            width = "100%",
            height = 18,
            tmargin = 4,
            textAlignment = "left"
        },
        {
            selectors = {"questTitle", "resolved"},
            color = "@fgMuted"
        },
        {
            selectors = {"questMeta"},
            fontSize = 10,
            color = "@fgMuted",
            width = "100%",
            height = 13,
            textAlignment = "left"
        },
        {
            selectors = {"questRowActions"},
            flow = "horizontal",
            hidden = 1
        },
        {
            selectors = {"questRowActions", "parent:hover"},
            hidden = 0
        },
        {
            selectors = {"questEmpty"},
            fontSize = 12,
            color = "@fgMuted",
            width = "100%",
            height = 60,
            textAlignment = "center"
        },
        -- The Phosphor plus matches the caret mask used by the section headers.
        -- Scoped here so the app-wide addButton icon is untouched.
        {
            selectors = {"panel", "buttonIcon", "parent:addButton"},
            bgimage = "phosphor/plus-bold.png",
            priority = 10
        },
        -- A delete icon at full strength on every row reads as a button column.
        -- Recede at rest, go danger once the pointer reaches the button itself.
        {
            selectors = {"buttonIcon", "parent:deleteButton"},
            bgcolor = "@fgMuted",
            opacity = 0.5,
            priority = 10
        },
        {
            selectors = {"buttonIcon", "parent:deleteButton", "parent:hover"},
            bgcolor = "@danger",
            opacity = 1,
            priority = 15,
            transitionTime = 0.1
        }
    }
end

--- Builds the status/priority line beneath a quest title. Status and High
--- priority carry theme colors through TextMeshPro markup, which the rule
--- cascade cannot reach, so tokens are resolved against the active scheme here.
--- @param status string One of QMQuest.STATUS values
--- @param priority string One of QMQuest.PRIORITY values
--- @return string text The resolved markup for the meta label
local function BuildMetaText(status, priority)
    local text = status
    local statusToken = STATUS_TEXT_TOKEN[status]
    if statusToken then
        text = string.format("<color=%s>%s</color>", statusToken, status)
    end

    -- Medium is the default and adds no signal, so only the outliers show.
    if priority == QMQuest.PRIORITY.HIGH then
        text = text .. " - <color=@warning>High</color>"
    elseif priority == QMQuest.PRIORITY.LOW then
        text = text .. " - Low"
    end

    return ThemeEngine.ResolveTokens(text)
end

--- Creates a horizontal hairline used to separate rows and sections
--- @param className string Either "questRule" or "questSeam"
--- @return table panel The hairline panel
local function CreateHairline(className)
    return gui.Panel{
        classes = {className},
        interactable = false
    }
end

--- Creates a new Quest Tracker Panel instance
--- @param questManager QMQuestManager The quest manager instance for data operations
--- @return QMQuestTrackerPanel|nil instance The new panel instance
function QMQuestTrackerPanel.CreateNew(questManager)
    if not questManager then return nil end
    return QMQuestTrackerPanel.new{ questManager = questManager }
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

    -- Rule colors are a one-shot snapshot and the meta lines bake resolved hex
    -- into their markup, so a scheme switch has to re-resolve and rebuild both.
    ThemeEngine.OnThemeChanged(mod, function()
        local panel = questTrackerPanel:try_get("panelElement")
        if panel ~= nil and panel.valid then
            panel.styles = ThemeEngine.MergeTokens(BuildQuestTrackerStyles())
            questTrackerPanel:_refreshPanelContent(panel)
        end
    end)
end

--- Builds the main panel structure for the quest tracker
--- @return table panel The main GUI panel containing all quest tracker elements
function QMQuestTrackerPanel:_buildMainPanel()
    local questTrackerPanel = self
    return gui.Panel {
        id = "questTrackerController",
        classes = {"questTrackerController"},
        styles = ThemeEngine.MergeTokens(BuildQuestTrackerStyles()),
        width = "100%",
        height = "auto",
        flow = "vertical",
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
                local questManagerWindow = QMQuestManagerWindow.CreateNew(quest)
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

--- Builds the header panel containing the quest count and the add control
--- @return table panel The header panel
function QMQuestTrackerPanel:_buildHeaderPanel()
    local questCount = 0
    if self.questManager then
        _, questCount = self.questManager:GetAllQuests()
    end

    return gui.Panel {
        width = "100%",
        height = "auto",
        flow = "vertical",
        children = {
            gui.Panel {
                classes = {"questUtilityRow"},
                children = {
                    gui.Label {
                        classes = {"questPanelCount"},
                        text = string.format("Quests (%d)", questCount)
                    },
                    gui.Button {
                        classes = {"addButton", "sizeS"},
                        halign = "right",
                        valign = "center",
                        rmargin = 6,
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
            },
            CreateHairline("questRule")
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
                classes = {"questEmpty"},
                text = "No quests yet.",
                valign = "center"
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

            -- Add untitled quests section first (if any)
            if #untitledQuests > 0 then
                questChildren[#questChildren + 1] = self:_buildUntitledQuestsSection(untitledQuests)
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

            -- Create collapsible sections for each category that has quests
            for _, categoryId in ipairs(CATEGORY_ORDER) do
                local categoryQuests = questsByCategory[categoryId]
                if categoryQuests and #categoryQuests > 0 then
                    questChildren[#questChildren + 1] = self:_buildCategorySection(categoryId, categoryQuests)
                end
            end
        end
    else
        questChildren[#questChildren + 1] =
            gui.Label {
            classes = {"danger", "bold", "sizeS"},
            text = "Quest Manager not available",
            width = "100%",
            height = 40,
            textAlignment = "center"
        }
    end

    return gui.Panel {
        width = "100%",
        height = "auto",
        flow = "vertical",
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
--- @param untitledDisplayText string|nil Optional display text for untitled quests
--- @return table panel The quest item panel
function QMQuestTrackerPanel:_buildQuestItem(quest, untitledDisplayText)
    local isUntitled = self:_isQuestUntitled(quest)
    local title = quest:GetTitle()
    if isUntitled then
        title = untitledDisplayText or "Untitled Quest"
    end
    local status = quest:GetStatus() or "unknown"
    local priority = quest:GetPriority() or "unknown"

    local actionButtons = {}

    -- Add delete button only for DM or quest creator
    if dmhub.isDM or dmhub.userid == quest:GetCreatedBy() then
        actionButtons[#actionButtons + 1] = gui.Button {
            classes = {"deleteButton", "sizeXs"},
            requireConfirm = true,
            halign = "right",
            valign = "center",
            rmargin = 6,
            click = function()
                self.questManager:DeleteQuest(quest:GetID())
            end
        }
    end

    local stripeClasses = {"questStripe"}
    local stripeStatusClass = STATUS_STRIPE_CLASS[status]
    if stripeStatusClass then
        stripeClasses[#stripeClasses + 1] = stripeStatusClass
    end

    local titleClasses = {"questTitle"}
    if isUntitled or RESOLVED_STATUSES[status] then
        titleClasses[#titleClasses + 1] = "resolved"
    end

    return gui.Panel {
        classes = {"questRow"},
        click = function(element)
            element:FireEventOnParents("openQuest", quest:GetID())
        end,
        children = {
            gui.Panel {
                classes = stripeClasses,
                interactable = false
            },
            gui.Panel {
                width = "84%",
                height = "100%",
                flow = "vertical",
                lmargin = 8,
                children = {
                    gui.Label {
                        classes = titleClasses,
                        text = title
                    },
                    gui.Label {
                        classes = {"questMeta"},
                        text = BuildMetaText(status, priority)
                    }
                }
            },
            gui.Panel {
                classes = {"questRowActions"},
                width = "13%",
                height = "100%",
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

    for i, quest in ipairs(untitledQuests) do
        if i > 1 then
            questChildren[#questChildren + 1] = CreateHairline("questSeam")
        end
        questChildren[#questChildren + 1] = self:_buildQuestItem(quest, "(New Quest)")
    end

    questChildren[#questChildren + 1] = CreateHairline("questSeam")

    return gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        children = questChildren
    }
end

--- Maps quest category IDs to user-friendly display names
--- @param categoryId string The category ID from QMQuest.CATEGORY
--- @return string displayName The user-friendly category name
function QMQuestTrackerPanel:_getCategoryDisplayName(categoryId)
    if not categoryId or categoryId == "" then
        return "Other"
    end

    return categoryId
end

--- Builds a collapsible header for a quest category
--- The whole row toggles, not just the caret.
--- @param categoryId string The category ID from QMQuest.CATEGORY
--- @param questCount number The number of quests in this category
--- @param contentPanel table The content panel that this header will toggle
--- @return table panel The category header panel with caret, label and count
function QMQuestTrackerPanel:_buildCategoryHeader(categoryId, questCount, contentPanel)
    local categoryName = self:_getCategoryDisplayName(categoryId)
    local prefKey = string.format("questcategory:%s:%s", categoryId, dmhub.gameid or "default")
    local isExpanded = dmhub.GetPref(prefKey) or false

    local triangle
    local function toggle()
        local nowExpanded = not triangle:HasClass("expanded")
        triangle:SetClass("expanded", nowExpanded)
        if contentPanel then
            contentPanel:SetClass("collapseAnim", not nowExpanded)
        end
        dmhub.SetPref(prefKey, nowExpanded)
    end

    triangle = gui.ExpandoArrow{
        classes = {"sizeXs" and cond(isExpanded, "expanded", nil) },
        click = function()
            toggle()
        end
    }

    return gui.Panel{
        classes = {"questSectionHeader"},
        click = function()
            toggle()
        end,
        children = {
            triangle,
            gui.Label{
                classes = {"questSectionLabel"},
                text = categoryName
            },
            gui.Label{
                classes = {"questSectionCount"},
                text = string.format("(%d)", questCount)
            }
        }
    }
end

--- Builds the collapsible content area for a quest category
--- Quests sort by status so live work stays at the top of the section.
--- @param categoryQuests table Array of QMQuest instances for this category
--- @param categoryId string The category ID to check collapse state
--- @return table panel The content panel containing quest items
function QMQuestTrackerPanel:_buildCategoryContent(categoryQuests, categoryId)
    local questChildren = {}

    table.sort(categoryQuests, function(a, b)
        local rankA = STATUS_SORT_RANK[a:GetStatus()] or 99
        local rankB = STATUS_SORT_RANK[b:GetStatus()] or 99
        if rankA ~= rankB then
            return rankA < rankB
        end
        return string.lower(a:GetTitle() or "") < string.lower(b:GetTitle() or "")
    end)

    for i, quest in ipairs(categoryQuests) do
        if i > 1 then
            questChildren[#questChildren + 1] = CreateHairline("questSeam")
        end
        questChildren[#questChildren + 1] = self:_buildQuestItem(quest)
    end

    questChildren[#questChildren + 1] = CreateHairline("questSeam")

    -- Check collapse state from preferences
    local prefKey = string.format("questcategory:%s:%s", categoryId, dmhub.gameid or "default")
    local isExpanded = dmhub.GetPref(prefKey) or false

    local classes = {}
    if not isExpanded then
        table.insert(classes, "collapseAnim")
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
        children = {
            headerPanel,
            CreateHairline("questRule"),
            contentPanel
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
