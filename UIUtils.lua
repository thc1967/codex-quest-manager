--- Shared UI utilities for Quest Manager including dialogs and styles
--- Provides consistent dialog components and styling across all Quest Manager UI
--- @class QTUIUtils
QTUIUtils = RegisterGameType("QTUIUtils")

--- Shows a standardized delete confirmation dialog
--- @param itemType string The type of item being deleted ("quest", "note", "objective")
--- @param itemTitle string The display name/title of the item being deleted
--- @param onConfirm function Callback function to execute if user confirms deletion
--- @param onCancel function Optional callback function to execute if user cancels (default: just close dialog)
function QTUIUtils.ShowDeleteConfirmation(itemType, itemTitle, onConfirm, onCancel)
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
        styles = QTUIUtils.GetDialogStyles(),

        children = {
            -- Header
            gui.Label{
                text = "Delete Confirmation",
                fontSize = 24,
                width = "100%",
                height = 30,
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
                        classes = {"QTButton", "QTBase"},
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
--- @return table styles Array of GUI styles using QTBase inheritance pattern
function QTUIUtils.GetDialogStyles()
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
