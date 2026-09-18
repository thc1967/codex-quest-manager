local mod = dmhub.GetModLoading()

--- Shared vocabulary for the Quest Manager window: sizes, icons and orderings.
--- @class QMConstants
QMConstants = RegisterGameType("QMConstants")

-- Window
QMConstants.panelName = "Quest Manager"
QMConstants.windowWidth = 1240
QMConstants.windowHeight = 700
QMConstants.listWidth = 360
QMConstants.listRightMargin = 12

-- List
QMConstants.rowHeight = 32
QMConstants.rowIconSize = 16
QMConstants.folderHeaderHeight = 26

-- Editor
--- A form row's width, and the margin the theme's formStackedRow puts on its left
QMConstants.formRowWidth = "97%"
QMConstants.formRowMargin = 12
QMConstants.multilineHeight = 60
QMConstants.descriptionHeight = 100
QMConstants.characterLimit = 4096
QMConstants.objectiveIconSize = 14
QMConstants.objectiveStatusWidth = 120
QMConstants.objectiveDragHandleSize = 20
QMConstants.noteHeaderHeight = 20

--- Sections inset from the pane's right edge so the scroll bar rides beside them
QMConstants.sectionWidth = "100%-16"

-- Icons
QMConstants.iconEyeShown = "phosphor/eye.png"
QMConstants.iconEyeHidden = "phosphor/eye-slash.png"
QMConstants.iconGear = "phosphor/gear-six-fill.png"
QMConstants.iconLocked = "phosphor/lock-simple-light.png"
QMConstants.iconUnlocked = "phosphor/lock-simple-open.png"

--- Widths inside a form column, for controls that should not fill it
QMConstants.choiceWidth = "50%"
QMConstants.shortInputWidth = "78%"

--- The Rewards row shares its line with the Claimed box
QMConstants.rewardsWidth = "85%"
QMConstants.claimedWidth = "15%"

QMConstants.statusIcon = {
    [QMQuest.STATUS.NOT_STARTED] = "phosphor/circle-light.png",
    [QMQuest.STATUS.ACTIVE] = "phosphor/play-circle-light.png",
    [QMQuest.STATUS.ON_HOLD] = "phosphor/pause-circle-light.png",
    [QMQuest.STATUS.COMPLETED] = "phosphor/check-circle-light.png",
    [QMQuest.STATUS.FAILED] = "phosphor/x-circle-light.png",
}

--- The tint each status glyph wears, matching the old tracker's stripe colours
QMConstants.statusTone = {
    [QMQuest.STATUS.NOT_STARTED] = "bgFgMuted",
    [QMQuest.STATUS.ACTIVE] = "bgSuccess",
    [QMQuest.STATUS.ON_HOLD] = "bgWarning",
    [QMQuest.STATUS.COMPLETED] = "bgInfo",
    [QMQuest.STATUS.FAILED] = "bgDanger",
}

QMConstants.priorityIcon = {
    [QMQuest.PRIORITY.HIGH] = "phosphor/caret-double-up-light.png",
    [QMQuest.PRIORITY.MEDIUM] = "phosphor/approximate-equals-light.png",
    [QMQuest.PRIORITY.LOW] = "phosphor/caret-double-down-light.png",
}

--- Medium is the default and carries no signal, so only High is lit
QMConstants.priorityTone = {
    [QMQuest.PRIORITY.HIGH] = "bgFg",
    [QMQuest.PRIORITY.MEDIUM] = "bgFgMuted",
    [QMQuest.PRIORITY.LOW] = "bgFgMuted",
}

--- Statuses whose quests are finished and render de-emphasized
QMConstants.resolvedStatuses = {
    [QMQuest.STATUS.COMPLETED] = true,
    [QMQuest.STATUS.FAILED] = true,
}

--- Display order for quests within a folder; lower sorts first
QMConstants.statusSortRank = {
    [QMQuest.STATUS.ACTIVE] = 1,
    [QMQuest.STATUS.NOT_STARTED] = 2,
    [QMQuest.STATUS.ON_HOLD] = 3,
    [QMQuest.STATUS.COMPLETED] = 4,
    [QMQuest.STATUS.FAILED] = 5,
}

--- Dropdown and glyph order for statuses
QMConstants.statusOrder = {
    QMQuest.STATUS.NOT_STARTED,
    QMQuest.STATUS.ACTIVE,
    QMQuest.STATUS.ON_HOLD,
    QMQuest.STATUS.COMPLETED,
    QMQuest.STATUS.FAILED,
}

--- Dropdown order for priorities
QMConstants.priorityOrder = {
    QMQuest.PRIORITY.HIGH,
    QMQuest.PRIORITY.MEDIUM,
    QMQuest.PRIORITY.LOW,
}

--- The static folders of the library, top to bottom
QMConstants.categoryOrder = {
    QMQuest.CATEGORY.MAIN,
    QMQuest.CATEGORY.SIDE,
    QMQuest.CATEGORY.PERSONAL,
    QMQuest.CATEGORY.FACTION,
    QMQuest.CATEGORY.TUTORIAL,
}

--- Completes the theme's size ladder for the two controls it skips, so a form
--- given one size class lands at one point size.
--- @return table styles Rules for the DialogShell's styles argument
function QMConstants.ShellStyles()
    return {
        {
            selectors = {"dropdown", "sizeS"},
            fontSize = 14,
            priority = 5,
        },
        {
            selectors = {"dropdown", "sizeXs"},
            fontSize = 12,
            priority = 5,
        },
        {
            selectors = {"checkboxLabel", "parent:sizeS"},
            fontSize = 14,
            priority = 5,
        },
    }
end
