local mod = dmhub.GetModLoading()

--- The Quest Manager window. The frame comes from DialogShell; what lives here
--- is the pairing of the library on the left with the editor on the right, and
--- the Tools menu entry that opens it.
--- @class QMDialog
QMDialog = RegisterGameType("QMDialog")

--- How many Quest Manager windows this client has open. LaunchPanelByName
--- toggles, so asking an open window to open would shut it.
local m_openWindows = 0

--- The library list of the open window, so a journal link can drive its selection
local m_listPanel = nil

--- @return boolean
function QMDialog.IsOpen()
    return m_openWindows > 0
end

--- Raise the window, selecting one quest if given
--- @param questId string|nil
function QMDialog.Open(questId)
    if not QMDialog.IsOpen() then
        LaunchablePanel.LaunchPanelByName(QMConstants.panelName)
    end

    if questId == nil then
        return
    end

    --A window asked for on this frame has not built its list yet, so the
    --selection waits a tick rather than firing into nothing.
    dmhub.Schedule(0.01, function()
        if mod.unloaded then
            return
        end
        if m_listPanel ~= nil and m_listPanel.valid then
            m_listPanel:FireEvent("select", questId)
        end
    end)
end

--- The line under the title: which quest is selected and where it stands
--- @param qm QMQuestManager
--- @param questId string|nil
--- @return string
local function Subtitle(qm, questId)
    if questId == nil then
        return ""
    end
    local quest = qm:GetQuest(questId)
    if quest == nil then
        return ""
    end

    local title = trim(quest:GetTitle() or "")
    if title == "" then
        title = "(New Quest)"
    end

    return table.concat({
        title,
        quest:GetCategory() or "",
        quest:GetStatus() or "",
        (quest:GetPriority() or "") .. " priority",
    }, "  |  ")
end

--- Builds the window: library on the left, editor on the right, Close in the footer
--- @return table panel The dialog's root panel
function QMDialog.Create()
    local qm = QMQuestManager.CreateNew()
    local m_selected = nil
    local dlg

    local editorPanel = QMEditorPanel.Create(qm)

    local listPanel = QMLibraryPanel.Create(qm, function(questId)
        m_selected = questId
        if editorPanel.valid then
            editorPanel:FireEvent("setQuest", questId)
        end
        if dlg ~= nil then
            dlg:SetSubtitle(Subtitle(qm, questId))
        end
    end)

    m_listPanel = listPanel

    dlg = DialogShell.CreateNew{
        classes = {"launchablePanel"},
        title = QMConstants.panelName,
        subtitle = "",
        width = QMConstants.windowWidth,
        height = QMConstants.windowHeight,
        footerCells = {100},
        close = "host",
        styles = QMConstants.ShellStyles(),

        monitor = qm:GetDocumentPath(),
        refresh = function(shell)
            shell:Root():FireEventTree("questsChanged")
            shell:SetSubtitle(Subtitle(qm, m_selected))
        end,

        onCreate = function(shell)
            m_openWindows = m_openWindows + 1
            shell:Root():FireEventTree("questsChanged")
        end,

        onDestroy = function()
            m_openWindows = math.max(0, m_openWindows - 1)
        end,
    }

    dlg:SetWorkingContent(gui.Panel{
        width = "100%",
        height = "100%",
        flow = "horizontal",
        valign = "top",

        --No vscroll here: the library's bordered list is the scroller
        gui.Panel{
            width = QMConstants.listWidth,
            height = "100%",
            flow = "vertical",
            valign = "top",
            rmargin = QMConstants.listRightMargin,

            listPanel,
        },

        editorPanel,
    })

    dlg:AddFooterButton{
        slot = "left",
        text = "Close",
        click = function(shell)
            shell:Close()
        end,
    }

    return dlg:Root()
end

LaunchablePanel.Register{
    name = QMConstants.panelName,
    menu = "tools",
    icon = QMConstants.icon,
    halign = "center",
    valign = "center",
    content = QMDialog.Create,
}

--- The dockable tracker: the window's own library, standing alone. Clicking a
--- row raises the window on that quest, and its add button does the same for
--- a new one. The dock root already carries the theme cascade.
--- @return table panel
function QMDialog.CreateTracker()
    local qm = QMQuestManager.CreateNew()
    return QMLibraryPanel.Create(qm, function(questId)
        if questId ~= nil then
            QMDialog.Open(questId)
        end
    end)
end

DockablePanel.Register{
    name = QMConstants.trackerName,
    icon = QMConstants.icon,
    minHeight = QMConstants.trackerMinHeight,
    maxHeight = QMConstants.trackerMaxHeight,
    content = QMDialog.CreateTracker,
}
