local mod = dmhub.GetModLoading()

--- @class RichQuest
RichQuest = RegisterGameType("RichQuest", "Rich Tag")
RichQuest.tag = "quest"
RichQuest.pattern = "(?i)^quest:(?<questId>.+)$"
RichQuest.questId = ""
RichQuest.hasEdit = false

function RichQuest.Create()
    return RichQuest.new()
end

function RichQuest:CreateDisplay()
    local resultPanel

    local m_questManager = QMQuestManager.CreateNew()
    local m_questId
    local m_quest

    local function validateQuest(questId)
        if m_quest and m_quest:GetID() == questId then return m_quest end
        m_quest = nil
        if m_questManager == nil then m_questManager = QMQuestManager.CreateNew() end
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

    local qmIcon = gui.Panel{
        bgimage = mod.images.questManager,
        bgcolor = "white",
        halign = "left",
        valign = "center",
        hmargin = 4,
        width = 16,
        height = 16,
    }

    local titleLabel = gui.Label{
        classes = {"sizeS"},
        width = "84%",
        height = "auto",
        halign = "left",
        valign = "top",
        textAlignment = "topLeft",
        minFontSize = 8,
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

    local openButton = gui.Button{
        classes = {"settingsButton"},
        halign = "right",
        valign = "center",
        hmargin = 12,
        width = 16,
        height = 16,
        swallowPress = true,
        press = function(element)
            if m_quest then
                local questMgrWindow = QMQuestManagerWindow.CreateNew(m_quest)
                if questMgrWindow then
                    questMgrWindow:Show()
                end
            end
        end,
    }

    local showHide = dmhub.isDM and gui.Button{
        icon = "ui-icons/eye.png",
        halign = "right",
        valign = "center",
        hmargin = 8,
        width = 16,
        height = 16,
        swallowPress = true,
        refreshTag = function(element)
            local visible = m_quest and m_quest:GetVisibleToPlayers() or false
            element.icon = visible and "ui-icons/eye.png" or "ui-icons/eye-closed.png"
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
        width = "100%",
        height = "auto",
        flow = "horizontal",
        qmIcon,
        titleLabel,
        showHide,
        openButton,
    }

    local function makeBodyLabel(refreshTag)
        return gui.Label{
            classes = {"sizeS"},
            width = "98%",
            height = "auto",
            halign = "left",
            valign = "top",
            textAlignment = "topLeft",
            minFontSize = 8,
            text = "calculating...",
            refreshTag = refreshTag,
        }
    end

    local questGiver = makeBodyLabel(function(element)
        local giver = "?"
        local location = "?"
        if m_quest then
            giver = m_quest:GetQuestGiver()
            location = m_quest:GetLocation()
        end
        element.text = string.format("<b>Granted By:</b> %s at %s", giver, location)
    end)

    local description = makeBodyLabel(function(element)
        local text = m_quest and m_quest:GetDescription()
        element.text = text
        element:SetClass("collapsed", text == nil or #text == 0)
    end)

    local objectives = makeBodyLabel(function(element)
        local text = ""
        local list = m_quest and m_quest:GetObjectivesSorted()
        if list and #list > 0 then
            text = string.format("<b>Objective%s:</b>%s", #list > 1 and "s" or "", #list > 1 and "\n" or "")
            for i, objective in ipairs(list) do
                text = string.format("%s%d. %s%s", text, i, formatObjective(objective), #list > i and "\n" or "")
            end
        end
        element.text = text
        element:SetClass("collapsed", #text == 0)
    end)

    local rewards = makeBodyLabel(function(element)
        local text = ""
        local rewardText = m_quest and m_quest:GetRewards()
        if rewardText then
            text = string.format("<b>Rewards:</b> %s", rewardText)
        end
        element.text = text
        element:SetClass("collapsed", #text == 0)
    end)

    local bodyPanel = gui.Panel{
        width = "100%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        valign = "top",
        pad = 4,
        questGiver,
        description,
        objectives,
        rewards,
    }

    resultPanel = gui.Panel{
        classes = {"bordered"},
        styles = ThemeEngine.GetStyles(),
        width = "80%",
        height = "auto",
        flow = "vertical",
        halign = "left",
        pad = 2,

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

    ThemeEngine.OnThemeChanged(mod, function()
        if resultPanel ~= nil and resultPanel.valid then
            resultPanel.styles = ThemeEngine.GetStyles()
        end
    end)

    return resultPanel
end

MarkdownDocument.RegisterRichTag(RichQuest)
