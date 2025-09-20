--- Quest Dialog for Creating and Editing
--- Provides a modal dialog for creating new quests and editing existing ones
--- @class QTQuestDialog
--- @field questManager QTQuestManager The quest manager for data operations
QTQuestDialog = RegisterGameType("QTQuestDialog")
QTQuestDialog.__index = QTQuestDialog

--- Creates a new quest dialog instance
--- @param questManager QTQuestManager The quest manager for data operations
--- @param questId string Optional quest ID for edit mode
--- @return QTQuestDialog instance The new dialog instance
function QTQuestDialog:new(questManager, questId)
    local instance = setmetatable({}, self)
    instance.questManager = questManager
    instance.questId = questId
    instance.isEditMode = questId ~= nil

    -- Validate we have required dependencies
    if not instance.questManager then
        return nil
    end

    return instance
end

--- Shows the new quest creation dialog
--- @param onQuestCreated function Optional callback when quest is created
function QTQuestDialog:Show(onQuestCreated)
    local mod = self.questManager.mod

    -- Load existing quest data if editing
    local existingQuest = nil
    if self.isEditMode then
        existingQuest = self.questManager:GetQuest(self.questId)
    end

    -- Create form field elements first
    local titleField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = existingQuest and existingQuest:GetTitle() or "New Quest",
        placeholderText = "Enter quest title...",
        lineType = "Single"
    }

    local descriptionField = gui.Input{
        width = "100%",
        height = 70,
        classes = {"field-input", "multiline"},
        text = existingQuest and existingQuest:GetDescription() or "",
        placeholderText = "Enter quest description...",
        lineType = "MultiLine",
        textAlignment = "topleft"
    }

    local questGiverField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = existingQuest and existingQuest:GetQuestGiver() or "",
        placeholderText = "Who gave this quest?",
        lineType = "Single"
    }

    local locationField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = existingQuest and existingQuest:GetLocation() or "",
        placeholderText = "Where does this quest take place?",
        lineType = "Single"
    }

    local rewardsField = gui.Input{
        width = "100%",
        height = 30,
        classes = {"field-input"},
        text = existingQuest and existingQuest:GetRewards() or "",
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
        idChosen = existingQuest and existingQuest:GetCategory() or QTQuest.CATEGORY.MAIN
    }

    local priorityDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        height = 30,
        classes = {"field-dropdown"},
        options = priorityOptions,
        idChosen = existingQuest and existingQuest:GetPriority() or QTQuest.PRIORITY.MEDIUM
    }

    local statusDropdown = gui.Dropdown{
        width = "80%",
        halign = "left",
        height = 30,
        classes = {"field-dropdown"},
        options = statusOptions,
        idChosen = existingQuest and existingQuest:GetStatus() or QTQuest.STATUS.NOT_STARTED
    }

    local rewardsClaimedCheckbox = gui.Check{
        text = "Rewards Claimed",
        width = 160,
        height = 30,
        halign = "center",
        valign = "center",
        classes = {"field-checkbox"},
        value = existingQuest and existingQuest:GetRewardsClaimed() or false
    }

    local visibleToPlayersCheckbox = gui.Check{
        text = "Visible to Players",
        width = 160,
        height = 30,
        halign = "center",
        valign = "center",
        classes = {"field-checkbox"},
        value = existingQuest and existingQuest:GetVisibleToPlayers() or true
    }

    -- Helper function to format timestamp
    local function formatTimestamp(isoTimestamp)
        if not isoTimestamp or isoTimestamp == "" then
            return "Not yet created"
        end
        -- Convert ISO timestamp to local time format
        -- For now, just show the ISO timestamp - we can enhance this later
        return isoTimestamp
    end

    -- Timestamp fields (readonly)
    local createdTimestampLabel = gui.Label{
        width = "100%",
        height = 30,
        classes = {"field-readonly"},
        text = existingQuest and formatTimestamp(existingQuest:GetCreatedTimestamp()) or "Not yet created",
        textAlignment = "left"
    }

    local modifiedTimestampLabel = gui.Label{
        width = "100%",
        height = 30,
        classes = {"field-readonly"},
        text = existingQuest and formatTimestamp(existingQuest:GetModifiedTimestamp()) or "Not yet created",
        textAlignment = "left"
    }

    -- Create quest and close dialog
    local createQuest = function()
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

        local quest
        if self.isEditMode then
            -- Update existing quest
            quest = existingQuest
            if quest then
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
            end
        else
            -- Create new quest
            quest = self.questManager:CreateQuest(title, dmhub.playerId)
            if quest then
                quest:UpdateProperties({
                    description = description,
                    category = category,
                    priority = priority,
                    status = status,
                    questGiver = questGiver,
                    location = location,
                    rewards = rewards,
                    rewardsClaimed = rewardsClaimed,
                    visibleToPlayers = visibleToPlayers
                }, "New quest created")
            end
        end

        -- Call callback if provided
        if quest and onQuestCreated then
            onQuestCreated(quest)
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
        height = 800,
        halign = "center",
        valign = "center",
        classes = {"dialog-panel"},
        flow = "vertical",
        styles = self:_getDialogStyles(),
        bgcolor = "#111111ff", -- Ensure opaque background
        opacity = 1.0,
        children = {
            -- Header
            gui.Panel{
                width = "100%",
                height = 50,
                flow = "horizontal",
                classes = {"dialog-header"},
                children = {
                    gui.Label{
                        text = self.isEditMode and "Edit Quest" or "Create New Quest",
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
                height = 700,
                flow = "vertical",
                classes = {"dialog-content"},
                children = {
                    -- Title and Visible to Players row
                    gui.Panel{
                        width = "90%",
                        height = 60,
                        flow = "horizontal",
                        valign = "center",
                        children = {
                            gui.Panel{
                                width = "70%",
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
                            gui.Panel{
                                width = "30%",
                                height = 60,
                                halign = "center",
                                valign = "center",
                                children = {
                                    visibleToPlayersCheckbox
                                }
                            }
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

                    -- Category, Priority, and Status row
                    gui.Panel{
                        width = "90%",
                        height = 60,
                        flow = "horizontal",
                        children = {
                            gui.Panel{
                                width = "33%",
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
                                width = "33%",
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
                            gui.Panel{
                                width = "34%",
                                height = 60,
                                flow = "vertical",
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

                    -- Quest Giver and Location row
                    gui.Panel{
                        width = "90%",
                        height = 60,
                        flow = "horizontal",
                        children = {
                            gui.Panel{
                                width = "48%",
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
                            gui.Panel{
                                width = "4%",
                                height = 60
                            },
                            gui.Panel{
                                width = "48%",
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
                            }
                        }
                    },

                    -- Rewards and Rewards Claimed row
                    gui.Panel{
                        width = "90%",
                        height = 60,
                        flow = "horizontal",
                        valign = "center",
                        children = {
                            gui.Panel{
                                width = "70%",
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
                            },
                            gui.Panel{
                                width = "30%",
                                height = 60,
                                halign = "center",
                                valign = "center",
                                children = {
                                    rewardsClaimedCheckbox
                                }
                            }
                        }
                    },

                    -- Timestamps row
                    gui.Panel{
                        width = "90%",
                        height = 60,
                        flow = "horizontal",
                        children = {
                            gui.Panel{
                                width = "50%",
                                height = 60,
                                flow = "horizontal",
                                valign = "center",
                                children = {
                                    gui.Label{
                                        text = "Created:",
                                        classes = {"field-label"},
                                        width = "30%",
                                        height = 30,
                                        valign = "center"
                                    },
                                    createdTimestampLabel
                                }
                            },
                            gui.Panel{
                                width = "50%",
                                height = 60,
                                flow = "horizontal",
                                valign = "center",
                                children = {
                                    gui.Label{
                                        text = "Modified:",
                                        classes = {"field-label"},
                                        width = "30%",
                                        height = 30,
                                        valign = "center"
                                    },
                                    modifiedTimestampLabel
                                }
                            }
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
                        text = self.isEditMode and "Save Quest" or "Create Quest",
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
function QTQuestDialog:_getDialogStyles()
    return {
        gui.Style{
            selectors = {"dialog-panel"},
            bgcolor = "#111111ff", -- Completely opaque background
            borderWidth = 2,
            borderColor = Styles.textColor,
            opacity = 1.0
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
            -- fontStyle = "italic"
        }
    }
end
