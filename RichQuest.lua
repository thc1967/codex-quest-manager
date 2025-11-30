--- @class RichQuest
RichQuest = RegisterGameType("RichQuest", "Rich Tag")
RichQuest.tag = "quest"
RichQuest.pattern = "(?i)^quest:(?<questId>.+)$"
RichQuest.questId = ""
RichQuest.hasEdit = false

function RichQuest.Create()
    return RichQuest.new()
end

local DisplayStyles = {
    {
        selectors = {"quest-panel"},
        bgimage = true,
        bgcolor = "black",
        borderColor = "#ffffff88",
        borderWidth = "1",
        pad = 2,
        halign = "left",
    },
    {
        selectors = {"quest-header-panel"},
        width = "100%",
        height = "auto",
        flow = "horizontal",
        bgimage = true,
        bgcolor = "black",
        borderColor = "white",
        border = {x1 = 0, y1 = 1, x2 = 0, y2 = 0},
    },
    {
        selectors = {"quest-body-panel"},
        width = "100%",
        height = "auto",
        pad = 4,
        halign = "left",
        valign = "top",
        flow = "vertical",
    },
    {
        selectors = {"quest-label"},
        textAlignment = "topLeft",
        fontSize = 14,
        minFontSize = 8,
        hmargin = 2,
        height = "auto",
        width = "auto",
        halign = "left",
        valign = "top",
    },
	{
		selectors = {"quest-open-icon"},
		halign = "right",
		valign = "center",
        hmargin = 8,
		width = 16,
		height = 16,
		bgimage = "panels/hud/gear.png",
		bgcolor = "white",
	},
    {
        selectors = {"quest-open-icon", "hover"},
        brightness = 1.5,
    },
	{
		selectors = {"quest-visible-icon"},
		halign = "right",
		valign = "center",
        hmargin = 8,
		width = 16,
		height = 16,
		bgimage = "ui-icons/eye.png",
		bgcolor = "white",
	},
	{
		selectors = {"quest-visible-icon", "hover"},
		brightness = 1.5,
	},
	{
		selectors = {"quest-visible-icon", "inactive"},
		bgimage = "ui-icons/eye-closed.png",
	},
}

function RichQuest:CreateDisplay()
    local resultPanel

    local m_questManager = QMQuestManager:new()
    local m_questId
    local m_quest

    local function validateQuest(questId)
        if m_quest and m_quest:GetID() == questId then return m_quest end
        m_quest = nil
        if m_questManager == nil then m_questManager = QMQuestManager:new() end
        if m_questManager then
            if QMUIUtils.IsGuid(questId) then
                m_quest = m_questManager:GetQuest(questId)
            else
                m_quest = m_questManager:GetQuestByTitle(questId)
            end
        end
        return m_quest
    end

    local function formatObjective(objective)
        local title = objective:GetTitle() or "Unknown Objective"
        local status = objective:GetStatus() or "?"
        return string.format("%s (%s)", title, status)
    end

    local titleLabel = gui.Label{
        classes = {"quest-label"},
        width = "90%",
        refreshTag = function(element)
            local title = "Unknown Quest"
            local priority = "?"
            local category = "?"
            if m_quest then
                title = m_quest:GetTitle() or "Unknown Quest"
                priority = m_quest:GetPriority() or "?"
                category = m_quest:GetCategory() or "?"
            end
            element.text = string.format("<b>%s</b>: A <b>%s</b> priority <b>%s</b> Quest", title, priority, category)
        end
    }

    local openButton = gui.Panel{
        classes = {"quest-open-icon"},
        swallowPress = true,
        press = function(element)
            if m_quest then
                local questMgrWindow = QMQuestManagerWindow:new(m_quest)
                if questMgrWindow then
                    questMgrWindow:Show()
                end
            end
        end,
    }

    local showHide = dmhub.isDM and gui.Panel{
        classes = {"quest-visible-icon"},
        swallowPress = true,
        refreshTag = function(element)
            local visible = m_quest and m_quest:GetVisibleToPlayers() or false
            element:SetClass("inactive", not visible)
        end,
        press = function(element)
            if m_questManager and m_quest then
                m_questManager:ExecuteUpdateFn(function()
                    m_quest:SetVisibleToPlayers(not m_quest:GetVisibleToPlayers())
                end)
                resultPanel:FireEventTree("refreshTag")
            end
        end
    } or nil

    local headerPanel = gui.Panel{
        classes = {"quest-header-panel"},
        titleLabel,
        showHide,
        openButton,
    }

    local questGiver = gui.Label{
        classes = {"quest-label"},
        width = "98%",
        text = "calculating...",
        refreshTag = function(element)
            local giver = "?"
            local location = "?"
            if m_quest then
                giver = m_quest:GetQuestGiver()
                location = m_quest:GetLocation()
            end
            element.text = string.format("<b>Granted By:</b> %s at %s", giver, location)
        end,
    }

    local description = gui.Label{
        classes = {"quest-label"},
        width = "98%",
        text = "calculating...",
        refreshTag = function(element)
            local description = m_quest and m_quest:GetDescription()
            element.text = description
            element:SetClass("collapsed", description == nil or #description == 0)
        end,
    }

    local objectives = gui.Label{
        classes = {"quest-label"},
        width = "98%",
        text = "calculating...",
        refreshTag = function(element)
            local text = ""
            local objectives = m_quest and m_quest:GetObjectivesSorted()
            if objectives and #objectives > 0 then
                text = string.format("<b>Objective%s:</b>%s", #objectives > 1 and "s" or "", #objectives > 1 and "\n" or "")
                local i = 0
                for _, objective in ipairs(objectives) do
                    i = i + 1
                    text = string.format("%s%d. %s%s", text, i, formatObjective(objective), #objectives > i and "\n" or "")
                end
            end
            element.text = text
            element:SetClass("collapsed", #text == 0)
        end
    }

    local rewards = gui.Label {
        classes = {"quest-label"},
        width = "98%",
        text = "calculating...",
        refreshTag = function(element)
            local text = ""
            local rewards = m_quest and m_quest:GetRewards()
            if rewards then
                text = string.format("<b>Rewards:</b> %s", rewards)
            end
            element.text = text
            element:SetClass("collapsed", #text == 0)
        end
    }

    local bodyPanel = gui.Panel{
        classes = {"quest-body-panel"},
        height = "auto",
        questGiver,
        description,
        objectives,
        rewards,
    }

    resultPanel = gui.Panel{
        styles = DisplayStyles,
        classes = {"quest-panel"},
        width = "80%",
        height = "auto",
        flow = "vertical",
        halign = "left",

        monitorGame = m_questManager:GetDocumentPath(),
        refreshGame = function(element)
            element:FireEventTree("refreshTag")
        end,

        create = function(element)
            element:FireEventTree("refreshTag")
        end,
        refreshTag = function(element, tag, match, token)
            self = tag or self
            if match and match.questId then m_questId = match.questId end
            validateQuest(m_questId)
            local visible = m_quest and m_questManager._questVisibleToUser(m_quest) or false
            element:SetClass("collapsed", not visible)
        end,

        headerPanel,
        bodyPanel,
    }

    return resultPanel
end

MarkdownDocument.RegisterRichTag(RichQuest)
