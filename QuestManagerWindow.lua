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

    return instance
end

--- Creates and shows the Quest Manager window
function QTQuestManagerWindow:Show()
    if self.isOpen then
        return -- Already open
    end

    self.isOpen = true
    local questWindow = self:_createWindow()

    -- Add to main dialog panel
    if gamehud and gamehud.mainDialogPanel then
        gamehud.mainDialogPanel:AddChild(questWindow)
        questWindow:FireEvent("show")
    end
end

--- Creates the main window structure
--- @return table panel The main window panel
function QTQuestManagerWindow:_createWindow()
    local questManagerWindow = self
    local selectedTab = QTQuestManagerWindow.defaultTab

    -- Sort tabs by order
    table.sort(QTQuestManagerWindow.TabOptions, function(a, b)
        return tostring(a.order or a.text) < tostring(b.order or b.text)
    end)

    -- Create tab panels
    local tabPanels = {}
    for _, tabOption in ipairs(QTQuestManagerWindow.TabOptions) do
        local panel = nil
        if tabOption.panel ~= nil then
            panel = tabOption.panel(self.questManager, self.quest)
            if panel == nil then
                print("QuestManagerWindow tab " .. tabOption.id .. " returned nil from panel function")
            end
        else
            print("QuestManagerWindow tab " .. tabOption.id .. " must define a panel function")
        end
        tabPanels[#tabPanels + 1] = panel
    end

    -- Calculate window dimensions and scaling
    local windowHeight = 800
    local windowWidth = 1200
    local scale = 1

    local heightPercent = (dmhub.uiscale * windowHeight) / dmhub.screenDimensions.y
    local minPercent = 800 / 1080
    local xdelta = 0
    if heightPercent < minPercent then
        scale = heightPercent / minPercent
        xdelta = -(1 - scale) * windowWidth / 2
    end

    -- Main content area
    local contentPanel = gui.Panel{
        id = "questContentPanel",
        width = "100%",
        height = "100%",
        scale = scale,
        halign = "center",
        x = xdelta,
        flow = "none",
        children = tabPanels,

        showTab = function(element, tabIndex)
            for i, p in ipairs(tabPanels) do
                if p ~= nil then
                    local hidden = (tabIndex ~= i)
                    p:SetClass("hidden", hidden)
                    p:FireEventTree("questWindowActivate", not hidden)
                end
            end
        end,
    }

    -- Tab selection function
    local tabsPanel
    local SelectTab = function(id)
        local index = nil
        for i, tabOption in ipairs(QTQuestManagerWindow.TabOptions) do
            if tabOption.id == id then
                index = i
            end
        end

        if index ~= nil then
            contentPanel:FireEventTree("showTab", index, id)
        end
        selectedTab = id

        for i, tab in ipairs(tabsPanel.children) do
            if tab:HasClass("questTab") then
                tab:SetClass("selected", tab.data.info.id == id)
            end
        end
    end

    -- Create tabs panel
    tabsPanel = gui.Panel{
        id = "questManagerTabs",
        classes = {"questTabContainer"},
        styles = {
            QTQuestManagerWindow.TabsStyles,
        },

        init = function(element)
            local children = {}
            for _, tabOption in ipairs(QTQuestManagerWindow.TabOptions) do
                children[#children + 1] = gui.Label{
                    classes = {"questTab", selectedTab == tabOption.id and "selected" or nil},
                    text = tabOption.text,
                    press = function(element)
                        SelectTab(tabOption.id)
                    end,
                    data = {
                        info = tabOption,
                    },
                    gui.Panel{classes = {"questTabBorder"}},
                }
            end
            element.children = children
        end,
    }

    tabsPanel:FireEvent("init")

    -- Main window panel
    local windowPanel = gui.Panel{
        id = "questManagerWindow",
        classes = {"questManagerHarness", dmhub.GetSettingValue("quest:windowed") and "windowed" or nil},

        borderWidth = 2,
        borderColor = Styles.textColor,
        bgimage = "panels/square.png",
        bgcolor = "#111111ff", -- Completely opaque background
        opacity = 1.0, -- Ensure full opacity

        styles = {
            Styles.Default,
            Styles.Panel,
            {
                selectors = {"questManagerHarness"},
                width = windowWidth,
                height = windowHeight,
                halign = "center",
                valign = "center",
                flow = "vertical",
            },
            {
                selectors = {"questManagerHarness", "windowed"},
                transitionTime = 0.2,
                scale = 0.6,
            },
        },

        flow = "vertical",
        width = windowWidth,
        height = windowHeight,
        halign = "center",
        valign = "center",

        data = {},

        closeQuestManager = function(element)
            questManagerWindow.isOpen = false
            element:DestroySelf()
        end,

        escape = function(element)
            for _, p in ipairs(tabPanels) do
                if p then
                    p:FireEventTree("questWindowActivate", false)
                end
            end
            element:FireEvent("closeQuestManager")
        end,

        show = function(element)
            SelectTab(QTQuestManagerWindow.defaultTab)
            element:SetClass("collapsed", false)
        end,

        children = {
            -- Main content area
            gui.Panel{
                width = "100%",
                height = "100%",
                halign = "center",
                valign = "center",
                flow = "vertical",
                children = {
                    tabsPanel,
                    contentPanel,
                }
            },

            -- Window controls (resize and close buttons)
            gui.Panel{
                flow = "horizontal",
                floating = true,
                width = "auto",
                height = 40,
                halign = "right",
                valign = "top",
                children = {
                    -- Resize button (windowed mode toggle)
                    gui.Panel{
                        classes = {"iconButton"},
                        bgimage = "panels/square.png",
                        bgcolor = "black",
                        valign = "center",
                        borderColor = Styles.textColor,
                        borderWidth = 4,
                        width = 24,
                        height = 24,
                        click = function(element)
                            dmhub.SetSettingValue("quest:windowed", not dmhub.GetSettingValue("quest:windowed"))
                            element:Get("questManagerWindow"):SetClass("windowed", dmhub.GetSettingValue("quest:windowed"))
                        end,
                    },

                    -- Close button
                    gui.CloseButton{
                        width = 32,
                        height = 32,
                        valign = "center",
                        click = function(element)
                            element:Get("questManagerWindow"):FireEvent("escape")
                        end,
                    },
                }
            }
        }
    }

    return windowPanel
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
    local questName = quest:GetTitle() or "New Quest"

    return gui.Panel{
        id = "objectivesPanel",
        width = "100%",
        height = "100%",
        flow = "vertical",
        styles = {
            gui.Style{
                selectors = {"#objectivesPanel"},
                bgcolor = "#ff1111ff",
                borderWidth = 2,
                borderColor = Styles.textColor,
                opacity = 1.0,
            }
        },
        children = {
            gui.Label{
                text = "Objectives for: " .. questName,
                width = "100%",
                height = "auto",
                halign = "left",
                valign = "top",
                textAlignment = "left",
                fontSize = 24,
                color = Styles.textColor,
                bold = true,
                vmargin = 10
            },
            gui.Label{
                text = "Objective management features will be implemented here. This tab will contain quest objectives, their completion status, and related functionality.",
                width = "100%",
                height = "auto",
                halign = "left",
                valign = "top",
                textAlignment = "left",
                color = Styles.textColor,
                fontSize = 16,
                textWrap = true,
                vmargin = 10
            }
        }
    }
end

--- Creates the Notes tab panel
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object to display/edit
--- @return table panel The notes panel
function QTQuestManagerWindow.CreateNotesPanel(questManager, quest)
    local questName = quest:GetTitle() or "New Quest"

    return gui.Panel{
        id = "notesPanel",
        width = "100%",
        height = "100%",
        flow = "vertical",
        hpad = 20,
        vpad = 20,
        styles = {
            gui.Style{
                selectors = {"#notesPanel"},
                bgcolor = "#111111ff",
                borderWidth = 2,
                borderColor = Styles.textColor,
                opacity = 1.0,
            }
        },
        children = {
            gui.Label{
                text = "Notes for: " .. questName,
                width = "100%",
                height = "auto",
                halign = "left",
                valign = "top",
                textAlignment = "left",
                fontSize = 24,
                color = Styles.textColor,
                bold = true,
                vmargin = 10
            },
            gui.Label{
                text = "Quest notes management features will be implemented here. This tab will contain player notes, director notes, and related quest documentation.",
                width = "100%",
                height = "auto",
                halign = "left",
                valign = "top",
                textAlignment = "left",
                color = Styles.textColor,
                fontSize = 16,
                textWrap = true,
                vmargin = 10
            }
        }
    }
end

--- Builds the quest form for the Quest tab
--- @param questManager QTQuestManager The quest manager instance
--- @param quest QTQuest The quest object to display/edit
--- @return table panel The quest form panel
function QTQuestManagerWindow._buildQuestForm(questManager, quest)

    -- Create form field elements
    local titleField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = quest:GetTitle() or "New Quest",
        placeholderText = "Enter quest title...",
        lineType = "Single"
    }

    local descriptionField = gui.Input{
        width = "100%",
        height = 70,
        classes = {"field-input", "multiline"},
        text = quest:GetDescription() or "",
        placeholderText = "Enter quest description...",
        lineType = "MultiLine",
        textAlignment = "topleft"
    }

    local questGiverField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = quest:GetQuestGiver() or "",
        placeholderText = "Who gave this quest?",
        lineType = "Single"
    }

    local locationField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = quest:GetLocation() or "",
        placeholderText = "Where does this quest take place?",
        lineType = "Single"
    }

    local rewardsField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = quest:GetRewards() or "",
        placeholderText = "What rewards does this quest offer?",
        lineType = "Single"
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
        height = 30,
        classes = {"field-dropdown"},
        options = categoryOptions,
        idChosen = quest:GetCategory() or QTQuest.CATEGORY.MAIN
    }

    local priorityDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        height = 30,
        classes = {"field-dropdown"},
        options = priorityOptions,
        idChosen = quest:GetPriority() or QTQuest.PRIORITY.MEDIUM
    }

    local statusDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        height = 30,
        classes = {"field-dropdown"},
        options = statusOptions,
        idChosen = quest:GetStatus() or QTQuest.STATUS.NOT_STARTED
    }

    local rewardsClaimedCheckbox = gui.Check{
        text = "Rewards Claimed",
        width = 160,
        height = 30,
        halign = "left",
        valign = "center",
        classes = {"field-checkbox"},
        value = quest:GetRewardsClaimed() or false
    }

    local visibleToPlayersCheckbox = gui.Check{
        text = "Visible to Players",
        width = 160,
        height = 30,
        halign = "left",
        valign = "center",
        classes = {"field-checkbox"},
        value = quest:GetVisibleToPlayers() or true
    }

    -- Helper function to format timestamp
    local function formatTimestamp(isoTimestamp)
        if not isoTimestamp or isoTimestamp == "" then
            return "Not yet created"
        end
        return isoTimestamp
    end

    -- Timestamp fields (readonly)
    -- local createdTimestampLabel = gui.Label{
    --     width = "100%",
    --     height = 30,
    --     classes = {"field-readonly"},
    --     text = formatTimestamp(quest:GetCreatedTimestamp()) or "Not yet created",
    --     textAlignment = "left"
    -- }

    -- local modifiedTimestampLabel = gui.Label{
    --     width = "100%",
    --     height = 30,
    --     classes = {"field-readonly"},
    --     text = formatTimestamp(quest:GetModifiedTimestamp()) or "Not yet created",
    --     textAlignment = "left"
    -- }

    -- Save quest function
    local saveQuest = function()
        local title = titleField and titleField.text or "New Quest"
        local description = descriptionField and descriptionField.text or ""
        local category = categoryDropdown and categoryDropdown.idChosen or QTQuest.CATEGORY.MAIN
        local priority = priorityDropdown and priorityDropdown.idChosen or QTQuest.PRIORITY.MEDIUM
        local status = statusDropdown and statusDropdown.idChosen or QTQuest.STATUS.NOT_STARTED
        local questGiver = questGiverField and questGiverField.text or ""
        local location = locationField and locationField.text or ""
        local rewards = rewardsField and rewardsField.text or ""
        local rewardsClaimed = rewardsClaimedCheckbox and rewardsClaimedCheckbox.value or false
        local visibleToPlayers = visibleToPlayersCheckbox and visibleToPlayersCheckbox.value or true

        -- Update quest properties
        quest.title = title
        quest.description = description
        quest.category = category
        quest.priority = priority
        quest.status = status
        quest.questGiver = questGiver
        quest.location = location
        quest.rewards = rewards
        quest.rewardsClaimed = rewardsClaimed
        quest.visibleToPlayers = visibleToPlayers

        -- Save the quest (handles both draft and existing quests)
        if quest.id then
            -- Existing quest - update it
            quest:UpdateProperties({
                title = title,
                description = description,
                category = category,
                priority = priority,
                status = status,
                questGiver = questGiver,
                location = location,
                rewards = rewards,
                rewardsClaimed = rewardsClaimed,
                visibleToPlayers = visibleToPlayers
            }, "Quest updated")
        else
            -- Draft quest - save it for the first time
            questManager:SaveDraftQuest(quest)
        end
    end

    -- Build the form layout with simplest possible structure
    return gui.Panel{
        width = "100%",
        height = "100%",
        flow = "vertical",
        valign = "center",
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
                        classes = {"field-label"},
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
                height = 100,
                flow = "vertical",
                vmargin = 5,
                children = {
                    gui.Label{
                        text = "Description:",
                        classes = {"field-label"},
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
                                classes = {"field-label"},
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
                                classes = {"field-label"},
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
                                classes = {"field-label"},
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
                        classes = {"field-label"},
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
                        classes = {"field-label"},
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
                        classes = {"field-label"},
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

            -- Footer
            gui.Panel{
                width = "95%",
                height = 50,
                flow = "horizontal",
                classes = {"dialog-header"},
                children = {
                    gui.Button{
                        text = quest.id and "Save Quest" or "Create Quest",
                        width = "30%",
                        height = 35,
                        halign = "center",
                        classes = {"create-button"},
                        click = saveQuest
                    }
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
--- @return table styles Array of GUI styles for the dialog
function QTQuestManagerWindow._getDialogStyles()
    return {
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
        gui.Style{
            selectors = {"field-label"},
            fontSize = 14,
            bold = true,
            color = Styles.textColor,
            textAlignment = "left"
        },
        gui.Style{
            selectors = {"field-input"},
            fontSize = 13,
            color = Styles.textColor,
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"field-dropdown"},
            fontSize = 13,
            color = Styles.textColor,
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"create-button"},
            fontSize = 13,
            color = Styles.textColor,
            textAlignment = "center",
            bold = true
        },
        gui.Style{
            selectors = {"field-checkbox"},
            color = Styles.textColor
        },
        gui.Style{
            selectors = {"field-readonly"},
            fontSize = 12,
            color = Styles.textColor,
            bgcolor = "transparent",
        }
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