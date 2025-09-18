--- New Quest Creation Dialog
--- Provides a modal dialog for creating new quests with all essential properties
--- @class QTNewQuestDialog
--- @field questManager QTQuestManager The quest manager for data operations
QTNewQuestDialog = RegisterGameType("QTNewQuestDialog")
QTNewQuestDialog.__index = QTNewQuestDialog

--- Creates a new quest dialog instance
--- @param questManager QTQuestManager The quest manager for data operations
--- @return QTNewQuestDialog instance The new dialog instance
function QTNewQuestDialog:new(questManager)
    local instance = setmetatable({}, self)
    instance.questManager = questManager

    -- Validate we have required dependencies
    if not instance.questManager then
        return nil
    end

    return instance
end

--- Shows the new quest creation dialog
--- @param onQuestCreated function Optional callback when quest is created
function QTNewQuestDialog:Show(onQuestCreated)
    local mod = self.questManager.mod

    -- Create form field elements first
    local titleField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = "New Quest",
        placeholderText = "Enter quest title...",
        lineType = "Single"
    }

    local descriptionField = gui.Input{
        width = "100%",
        height = 70,
        classes = {"field-input", "multiline"},
        text = "",
        placeholderText = "Enter quest description...",
        lineType = "MultiLine",
        textAlignment = "topleft"
    }

    local questGiverField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = "",
        placeholderText = "Who gave this quest?",
        lineType = "Single"
    }

    local locationField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = "",
        placeholderText = "Where does this quest take place?",
        lineType = "Single"
    }

    local rewardsField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = "",
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

    -- Create dropdown elements
    local categoryDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        height = 30,
        classes = {"field-dropdown"},
        options = categoryOptions,
        idChosen = QTQuest.CATEGORY.MAIN
    }

    local priorityDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        height = 30,
        classes = {"field-dropdown"},
        options = priorityOptions,
        idChosen = QTQuest.PRIORITY.MEDIUM
    }

    -- Create quest and close dialog
    local createQuest = function()
        local title = titleField and titleField.text or "New Quest"
        local description = descriptionField and descriptionField.text or ""
        local category = categoryDropdown and categoryDropdown.idChosen or QTQuest.CATEGORY.MAIN
        local priority = priorityDropdown and priorityDropdown.idChosen or QTQuest.PRIORITY.MEDIUM
        local questGiver = questGiverField and questGiverField.text or ""
        local location = locationField and locationField.text or ""
        local rewards = rewardsField and rewardsField.text or ""

        -- Create quest using manager
        local quest = self.questManager:CreateQuest(title, dmhub.playerId)

        if quest then
            -- Update all properties in a single transaction
            quest:UpdateProperties({
                description = description,
                category = category,
                priority = priority,
                questGiver = questGiver,
                location = location,
                rewards = rewards
            }, "New quest created")

            -- Call callback if provided
            if onQuestCreated then
                onQuestCreated(quest)
            end
        end

        gui.CloseModal()
    end

    -- Cancel and close dialog
    local cancelDialog = function()
        gui.CloseModal()
    end

    -- Build the dialog
    local dialog = gui.Panel{
        width = 1000,
        height = 600,
        halign = "center",
        valign = "center",
        classes = {"dialog-panel"},
        flow = "vertical",
        styles = self:_getDialogStyles(),
        children = {
            -- Header
            gui.Panel{
                width = "100%",
                height = 50,
                flow = "horizontal",
                classes = {"dialog-header"},
                children = {
                    gui.Label{
                        text = "Create New Quest",
                        classes = {"dialog-title"},
                        width = "100%",
                        halign = "center",
                        valign = "center"
                    }
                }
            },

            -- Content
            gui.Panel{
                width = "100%",
                height = 500,
                flow = "vertical",
                classes = {"dialog-content"},
                children = {
                    -- Title field
                    gui.Panel{
                        width = "80%",
                        height = 60,
                        flow = "vertical",
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

                    -- Description field
                    gui.Panel{
                        width = "80%",
                        height = 100,
                        flow = "vertical",
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

                    -- Category and Priority row
                    gui.Panel{
                        width = "82%",
                        height = 60,
                        flow = "horizontal",
                        children = {
                            gui.Panel{
                                width = "50%",
                                height = 60,
                                flow = "vertical",
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
                                width = "50%",
                                height = 60,
                                flow = "vertical",
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
                            gui.Panel{width = "20%", height = 60} -- Right spacer
                        }
                    },

                    -- Quest Giver field
                    gui.Panel{
                        width = "80%",
                        height = 60,
                        flow = "vertical",
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

                    -- Location field
                    gui.Panel{
                        width = "80%",
                        height = 60,
                        flow = "vertical",
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

                    -- Rewards field
                    gui.Panel{
                        width = "80%",
                        height = 60,
                        flow = "vertical",
                        children = {
                            gui.Label{
                                text = "Rewards:",
                                classes = {"field-label"},
                                width = "100%",
                                height = 20
                            },
                            rewardsField
                        }
                    }
                }
            },

            -- Footer buttons
            gui.Panel{
                width = "100%",
                halign =  "center",
                height = 50,
                flow = "horizontal",
                classes = {"dialog-footer"},
                children = {
                    gui.Button{
                        text = "Cancel",
                        width = 100,
                        height = 35,
                        classes = {"cancel-button"},
                        click = cancelDialog
                    },
                    gui.Panel{width = 10, height = 50}, -- Small spacer between buttons
                    gui.Button{
                        text = "Create Quest",
                        width = 120,
                        height = 35,
                        classes = {"create-button"},
                        click = createQuest
                    }
                }
            }
        }
    }

    -- Show the modal dialog
    gui.ShowModal(dialog)
end

--- Gets the styling configuration for the dialog
--- @return table styles Array of GUI styles for the dialog
function QTNewQuestDialog:_getDialogStyles()
    return {
        gui.Style{
            selectors = {"dialog-panel"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 2,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"dialog-header"},
            bgcolor = Styles.textColor,
            color = Styles.backgroundColor
        },
        gui.Style{
            selectors = {"dialog-title"},
            fontSize = 18,
            bold = true,
            textAlignment = "center"
        },
        gui.Style{
            selectors = {"dialog-content"}
        },
        gui.Style{
            selectors = {"dialog-footer"},
            halign = "right"
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
            selectors = {"cancel-button"},
            fontSize = 13,
            color = Styles.textColor,
            textAlignment = "center"
        },
        gui.Style{
            selectors = {"create-button"},
            fontSize = 13,
            color = Styles.textColor,
            textAlignment = "center",
            bold = true
        }
    }
end
