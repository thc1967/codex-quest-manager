local mod = dmhub.GetModLoading()

--- Shared UI utilities for Quest Manager including dialogs and styles
--- Provides consistent dialog components and styling across all Quest Manager UI
--- @class QMUIUtils
QMUIUtils = RegisterGameType("QMUIUtils")

--- Shows a standardized delete confirmation dialog
--- @param itemType string The type of item being deleted ("quest", "note", "objective")
--- @param itemTitle string The display name/title of the item being deleted
--- @param onConfirm function Callback function to execute if user confirms deletion
--- @param onCancel function Optional callback function to execute if user cancels (default: just close dialog)
function QMUIUtils.ShowDeleteConfirmation(itemType, itemTitle, onConfirm, onCancel)
    local displayText = "Are you sure you want to delete " .. itemType .. " \"" .. (itemTitle or "Untitled") .. "\"?"

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
        styles = QMUIUtils.GetDialogStyles(),

        children = {
            -- Header
            gui.Label{
                text = "Delete Confirmation",
                fontSize = 24,
                width = "100%",
                height = 30,
                classes = {"QMLabel", "QMBase"},
                textAlignment = "center",
                halign = "center"
            },

            -- Confirmation message
            gui.Label{
                text = displayText,
                width = "100%",
                height = 80,
                classes = {"QMLabel", "QMBase"},
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
                        classes = {"QMButton", "QMBase"},
                        click = function(element)
                            gui.CloseModal()
                            if onCancel then
                                onCancel()
                            end
                        end
                    },
                    -- Delete button (second)
                    gui.Button{
                        text = "Delete",
                        width = 120,
                        height = 40,
                        hmargin = 10,
                        classes = {"QMButton", "QMBase"},
                        click = function(element)
                            gui.CloseModal()
                            if onConfirm then
                                onConfirm()
                            end
                        end
                    }
                }
            }
        },

        escape = function(element)
            gui.CloseModal()
            if onCancel then
                onCancel()
            end
        end
    }

    gui.ShowModal(confirmationWindow)
end

--- Gets the standardized styling configuration for Quest Manager dialogs
--- Provides consistent styling across all Quest Manager UI components
--- @return table styles Array of GUI styles using QMBase inheritance pattern
function QMUIUtils.GetDialogStyles()
    return {
        -- QMBase: Foundation style for all Quest Manager controls
        gui.Style{
            selectors = {"QMBase"},
            fontSize = 18,
            fontFace = "Berling",
            color = Styles.textColor,
            height = 40,
        },

        -- QM Control Types: Inherit from QMBase, add specific properties
        gui.Style{
            selectors = {"QMLabel", "QMBase"},
            bold = true,
            textAlignment = "left"
        },
        gui.Style{
            selectors = {"QMInput", "QMBase"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"QMDropdown", "QMBase"},
            bgcolor = Styles.backgroundColor,
            borderWidth = 1,
            borderColor = Styles.textColor
        },
        gui.Style{
            selectors = {"QMCheck", "QMBase"},
            -- Inherits all QMBase properties
        },
        gui.Style{
            selectors = {"QMButton", "QMBase"},
            fontSize = 22,
            textAlignment = "center",
            bold = true,
            height = 35  -- Override QMBase height for buttons
        },

        -- Objective drag handle styles
        gui.Style{
            selectors = {"objective-drag-handle"},
            width = 24,
            height = 24,
            bgcolor = "#444444aa",
            bgimage = "panels/square.png",
            transitionTime = 0.2
        },
        gui.Style{
            selectors = {"objective-drag-handle", "hover"},
            bgcolor = "#666666cc"
        },
        gui.Style{
            selectors = {"objective-drag-handle", "dragging"},
            bgcolor = "#888888ff",
            opacity = 0.8
        },
        gui.Style{
            selectors = {"objective-drag-handle", "drag-target"},
            bgcolor = "#4CAF50aa"
        },
    }
end

--- Gets player display name with color formatting from user ID
--- @param userId string The user ID to look up
--- @return string coloredDisplayName The player's display name with HTML color tags, or "{unknown}" if not found
function QMUIUtils.GetPlayerDisplayName(userId)
    if not userId or userId == "" then
        return "{unknown}"
    end

    local sessionInfo = dmhub.GetSessionInfo(userId)
    if sessionInfo and sessionInfo.displayName then
        local displayName = sessionInfo.displayName
        if sessionInfo.displayColor and sessionInfo.displayColor.tostring then
            local colorCode = sessionInfo.displayColor.tostring
            return "<color=" .. colorCode .. ">" .. displayName .. "</color>"
        else
            return displayName
        end
    end

    return "{unknown}"
end

--- Creates a labeled input field with consistent styling
--- @param labelText string The label text to display above the input
--- @param inputOptions table Options for the input field (text, placeholderText, lineType, etc.)
--- @param panelOptions table Optional panel options (width, height, vmargin, etc.)
--- @return table panel The complete labeled input panel
function QMUIUtils.CreateLabeledInput(labelText, inputOptions, panelOptions)
    -- Default panel options
    local panelDefaults = {
        width = "95%",
        height = inputOptions.lineType == "MultiLine" and 120 or 60,
        flow = "vertical",
        vmargin = 5
    }

    -- Merge panel options
    for k, v in pairs(panelOptions or {}) do
        panelDefaults[k] = v
    end

    -- Default input options
    local inputDefaults = {
        width = "100%",
        classes = {"QMInput", "QMBase"},
        lineType = "Single",
        editlag = 0.25
    }

    -- Merge input options
    for k, v in pairs(inputOptions) do
        inputDefaults[k] = v
    end

    -- Adjust input height for multiline
    if inputDefaults.lineType == "MultiLine" then
        inputDefaults.height = inputDefaults.height or 100
        inputDefaults.textAlignment = inputDefaults.textAlignment or "topleft"
    end

    return gui.Panel{
        width = panelDefaults.width,
        height = panelDefaults.height,
        flow = panelDefaults.flow,
        vmargin = panelDefaults.vmargin,
        children = {
            gui.Label{
                text = labelText,
                classes = {"QMLabel", "QMBase"},
                width = "100%",
                height = 20
            },
            gui.Input(inputDefaults)
        }
    }
end

--- Creates a labeled dropdown with consistent styling
--- @param labelText string The label text to display above the dropdown
--- @param dropdownOptions table Options for the dropdown (options, idChosen, change, etc.)
--- @param panelOptions table Optional panel options (width, height, vmargin, etc.)
--- @return table panel The complete labeled dropdown panel
function QMUIUtils.CreateLabeledDropdown(labelText, dropdownOptions, panelOptions)
    -- Default panel options
    local panelDefaults = {
        width = "33%",
        height = 60,
        flow = "vertical",
        hmargin = 5
    }

    -- Merge panel options
    for k, v in pairs(panelOptions or {}) do
        panelDefaults[k] = v
    end

    -- Default dropdown options
    local dropdownDefaults = {
        width = "80%",
        halign = "left",
        classes = {"QMDropdown", "QMBase"}
    }

    -- Merge dropdown options
    for k, v in pairs(dropdownOptions) do
        dropdownDefaults[k] = v
    end

    return gui.Panel{
        width = panelDefaults.width,
        height = panelDefaults.height,
        flow = panelDefaults.flow,
        hmargin = panelDefaults.hmargin,
        children = {
            gui.Label{
                text = labelText,
                classes = {"QMLabel", "QMBase"},
                width = "100%",
                height = 20
            },
            gui.Dropdown(dropdownDefaults)
        }
    }
end

--- Creates a labeled checkbox with consistent styling
--- @param checkboxOptions table Options for the checkbox (text, value, change, etc.)
--- @param panelOptions table Optional panel options (width, height, etc.)
--- @return table panel The complete labeled checkbox panel
function QMUIUtils.CreateLabeledCheckbox(checkboxOptions, panelOptions)
    -- Default panel options
    local panelDefaults = {
        width = "25%",
        height = 60,
        halign = "left",
        valign = "center"
    }

    -- Merge panel options
    for k, v in pairs(panelOptions or {}) do
        panelDefaults[k] = v
    end

    -- Default checkbox options
    local checkboxDefaults = {
        width = 160,
        halign = "left",
        valign = "center",
        classes = {"QMCheck", "QMBase"}
    }

    -- Merge checkbox options
    for k, v in pairs(checkboxOptions) do
        checkboxDefaults[k] = v
    end

    return gui.Panel{
        width = panelDefaults.width,
        height = panelDefaults.height,
        halign = panelDefaults.halign,
        valign = panelDefaults.valign,
        children = {
            gui.Check(checkboxDefaults)
        }
    }
end
