local mod = dmhub.GetModLoading()

--- Shared UI utilities for Quest Manager including dialogs and styles
--- Provides consistent dialog components and styling across all Quest Manager UI
--- @class QMUIUtils
QMUIUtils = RegisterGameType("QMUIUtils")

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
                classes = {"bold"},
                width = "100%",
                height = 20
            },
            gui.Dropdown(dropdownDefaults)
        }
    }
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
                classes = {"bold"},
                width = "100%",
                height = 20
            },
            gui.Input(inputDefaults)
        }
    }
end

--- A label-over-control form row
--- @param labelText string The label above the control
--- @param width string The row's width
--- @param control table The control panel
--- @return table panel The row panel
function QMUIUtils.FormRow(labelText, width, control)
    return gui.Panel{
        classes = {"formStackedRow"},
        width = width,
        children = {
            gui.Label{
                classes = {"formStacked", "sizeS"},
                text = labelText,
            },
            control,
        },
    }
end

--- The player-visibility eye. Live when a change handler is given, a plain indicator otherwise.
--- @param args table shown boolean; change nil|fun(shown: boolean); size nil|number; halign nil|string; hmargin nil|number
--- @return table panel The eye panel
function QMUIUtils.EyeToggle(args)
    local shown = args.shown == true
    local size = args.size or 16

    local tooltip
    if args.change ~= nil then
        tooltip = cond(shown, "Players can see this. Click to hide it.", "Hidden from players. Click to show it.")
    else
        tooltip = cond(shown, "Visible to players", "Hidden from players")
    end

    local press = nil
    if args.change ~= nil then
        press = function()
            args.change(not shown)
        end
    end

    return gui.Panel{
        classes = { cond(shown, "bgFg", "bgFgMuted") },
        width = size,
        height = size,
        halign = args.halign or "left",
        valign = "center",
        hmargin = args.hmargin or 4,
        bgimage = cond(shown, QMConstants.iconEyeShown, QMConstants.iconEyeHidden),
        hover = gui.Tooltip(tooltip),
        press = press,
    }
end

--- A section header with a hairline under it, drawn as a real bottom border
--- @param args table text string; trailing nil|table A panel placed after the label
--- @return table panel The header panel
function QMUIUtils.SectionHeader(args)
    local children = {
        gui.Label{
            classes = {"tableLabel", "sizeXs"},
            width = "auto",
            height = "auto",
            halign = "left",
            valign = "center",
            text = args.text or "",
        },
    }

    if args.trailing ~= nil then
        children[#children + 1] = args.trailing
    end

    return gui.Panel{
        classes = {"border"},
        width = QMConstants.sectionWidth,
        height = 26,
        flow = "horizontal",
        halign = "left",
        valign = "top",
        tmargin = 10,
        border = { x1 = 0, y1 = 1, x2 = 0, y2 = 0 },
        children = children,
    }
end

--- Gets player display name with color formatting from user ID
--- @param userId string The user ID to look up
--- @return string coloredDisplayName The player's display name with HTML color tags, or "{unknown}" if not found
function QMUIUtils.GetPlayerDisplayName(userId)

    if userId and #userId > 0 then
        local sessionInfo = dmhub.GetSessionInfo(userId)
        if sessionInfo and sessionInfo.displayName then
            local displayName = sessionInfo.displayName
            if sessionInfo.displayColor and sessionInfo.displayColor.tostring then
                local colorCode = sessionInfo.displayColor.tostring
                return string.format("<color=%s>%s</color>", colorCode, displayName)
            else
                return displayName
            end
        end
    end

    return "{unknown}"
end

--- Determine whether a string matches GUID format
--- @param str string A potential GUID
--- @return boolean isGuid Whether the string matches the GUID format
function QMUIUtils.IsGuid(str)
    if #str ~= 36 then return false end
    return str:match("^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
end

--- Transforms a list of strings into a list of id, text pairs for dropdown lists
--- @param sourceList table The table to convert
--- @return table destList The transformed table
function QMUIUtils.ListToDropdownOptions(sourceList)
    local destList = {}
    if sourceList and type(sourceList) == "table" then
        for _, item in pairs(sourceList) do
            destList[#destList+1] = { id = item, text = item}
        end
    end
    return destList
end

