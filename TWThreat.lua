local _G, _ = _G or getfenv()

local TWT = CreateFrame("Frame")
TWT.addonVer = '0.0.0.2'
TWT.addonName = '|cff69ccf0Momo|cffffffffmeter'
TWT.dev = false

TWT.channel = 'TWT'
TWT.name = UnitName('player')
local _, cl = UnitClass('player')
TWT.class = string.lower(cl)

TWT.classColors = {
    ["warrior"] = { r = 0.78, g = 0.61, b = 0.43, c = "|cffc79c6e" },
    ["mage"] = { r = 0.41, g = 0.8, b = 0.94, c = "|cff69ccf0" },
    ["rogue"] = { r = 1, g = 0.96, b = 0.41, c = "|cfffff569" },
    ["druid"] = { r = 1, g = 0.49, b = 0.04, c = "|cffff7d0a" },
    ["hunter"] = { r = 0.67, g = 0.83, b = 0.45, c = "|cffabd473" },
    ["shaman"] = { r = 0.14, g = 0.35, b = 1.0, c = "|cff0070de" },
    ["priest"] = { r = 1, g = 1, b = 1, c = "|cffffffff" },
    ["warlock"] = { r = 0.58, g = 0.51, b = 0.79, c = "|cff9482c9" },
    ["paladin"] = { r = 0.96, g = 0.55, b = 0.73, c = "|cfff58cba" },
    ["agro"] = { r = 0.96, g = 0.1, b = 0.1, c = "|cffff1111" }
}

function twtprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('[TWT]|cff0070de:' .. math.floor(GetTime()) .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(TWT.classColors[TWT.class].c .. "[TWT] |cffffffff" .. a)
end

function twtdebug(a)
    if type(a) == 'boolean' then
        if a then
            twtprint('|cff0070de[TWTDEBUG:' .. time() .. ']|cffffffff[true]')
        else
            twtprint('|cff0070de[TWTDEBUG:' .. time() .. ']|cffffffff[false]')
        end
        return true
    end
    twtprint('|cff0070de[TWTDEBUG:' .. time() .. ']|cffffffff[' .. a .. ']')
end

TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")

TWT.threats = {}
TWT.target = ''

TWT.ui = CreateFrame("Frame")
TWT.ui:Hide()
TWT.targetType = 'normal'
TWT.inCombat = false

local timeStart = GetTime()
local totalPackets = 0

TWT.guids = {}

TWT:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            TWT.init()
        end
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWT:', 1, true) then
            TWT.handleServerMSG(arg1)
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == TWT.channel then
            TWT.handleClientMSG(arg2, arg4)
        end
        if event == "PLAYER_REGEN_DISABLED" then
            TWT.combatStart()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            TWT.combatEnd()
        end
        if event == "PLAYER_TARGET_CHANGED" then
            TWT.targetChanged()
        end

    end
end)

function TWT.init()

    if not TWT_CONFIG then
        TWT_CONFIG = {}
        TWT_CONFIG.glow = false
        TWT_CONFIG.perc = false
        TWT_CONFIG.showInCombat = false
        TWT_CONFIG.hideOOC = false
    end

    _G['TWTMainSettingsTargetFrameGlow']:SetChecked(TWT_CONFIG.glow)
    _G['TWTMainSettingsPercNumbers']:SetChecked(TWT_CONFIG.perc)
    _G['TWTMainSettingsShowInCombat']:SetChecked(TWT_CONFIG.showInCombat)
    _G['TWTMainSettingsHideOOC']:SetChecked(TWT_CONFIG.hideOOC)

    local color = TWT.classColors[TWT.class]
    _G['TWTMainSettingsButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainCloseButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)

    _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)
    _G['TWTMainThreatTarget']:SetText('Threat: <no target>')

    twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff loaded.')
    _G['TWThreatListScrollFrameScrollBar']:Hide()
    _G['TWThreatListScrollFrameScrollBar']:SetAlpha(0)
    TWTMainMainWindow_Resized()
    TWT.ui:Show()

    _G['TWTMainTitleBG']:SetVertexColor(color.r, color.g, color.b)

    _G['TWThreatDisplayTarget']:SetScale(UIParent:GetScale())

end

TWT.codes = {}

function TWT.handleServerMSG(msg)
    --twtdebug(msg)
    -- "TWT:target:guid:threat:lastthreat:"

    totalPackets = totalPackets + 1

    local msgEx = string.split(msg, ':')

    if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] and msgEx[6] then

        local creature = ''
        local guid = 0
        local threat = 0
        local lastThreat = 0
        local hp = math.floor(msgEx[6])

        creature = msgEx[2]
        guid = msgEx[3]
        threat = tonumber(msgEx[4])
        lastThreat = tonumber(msgEx[5])

        TWT.send(TWT.class .. ':' .. creature .. ':' .. guid .. ':' .. threat .. ':' .. lastThreat .. ':' .. hp)

        if TWT.target == '' then
            TWT.target = guid
        end

        TWT.guids[guid] = creature
        TWT.codes[guid] = creature .. hp

    end
end

function TWT.handleClientMSG(msg, sender)
    --twtprint(msg)
    --"priest:target:guid:threat:lastthreat:hp"
    local ex = string.split(msg, ':')
    if ex[1] and ex[2] and ex[3] and ex[4] and ex[5] and ex[6] then

        local creature = ex[2]
        local guid = ex[3]
        local player = sender
        local threat = tonumber(ex[4])
        local lastThreat = tonumber(ex[5])
        local target = guid
        local class = ex[1]
        local hp = ex[6]

        if not TWT.threats[target] then
            TWT.threats[target] = {}
        end
        if not TWT.threats[target][player] then
            TWT.threats[target][player] = {}
        end
        local tps = 0

        if not TWT.threats[target][TWT.AGRO] then
            TWT.threats[target][TWT.AGRO] = {
                class = 'agro',
                threat = 0,
                perc = 100,
                tps = 0,
                history = {},
                lastThreat = 0
            }
        end

        if TWT.threats[target][player]['threat'] then

            TWT.threats[target][player].threat = threat
            TWT.threats[target][player].lastThreat = lastThreat
            TWT.threats[target][player].history[math.floor(GetTime())] = threat

        else
            TWT.threats[target][player] = {
                class = class,
                threat = threat,
                perc = 0,
                tps = tps,
                lastThreat = lastThreat,
                history = {
                    [math.floor(GetTime())] = threat
                }
            }
        end

    end
    TWT.updateUI()
end

function TWT.combatStart()
    TWT.inCombat = true
    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    TWT.updateUI()

    if TWT_CONFIG.showInCombat then
        _G['TWTMain']:Show()
    end
end

function TWT.combatEnd()
    --left combat
    TWT.inCombat = false
    TWT.updateTargetFrameThreatIndicators(-1, '')
    TWT.wipe(TWT.threats)

    twtprint('time = ' .. (math.floor(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    TWT.updateUI()

    if TWT_CONFIG.hideOOC then
        _G['TWTMain']:Hide()
    end

end

function TWT.targetChanged()

    if TargetFrame:IsVisible() ~= nil then
        TWT.targetFrameVisible = true
    else
        TWT.targetFrameVisible = false
    end

    if UIParent:GetScale() ~= _G['TWThreatDisplayTarget']:GetScale() then
        _G['TWThreatDisplayTarget']:SetScale(UIParent:GetScale())
    end

    -- no target
    if not UnitName('target') then
        _G['TWTMainThreatTarget']:SetText('Threat: <no target>')
        TWT.updateTargetFrameThreatIndicators(-1, 'notarget')
        return false
    end

    if UnitIsPlayer('target') then
        TWT.updateTargetFrameThreatIndicators(-1, UnitName('target'))
    else

        --if TWT.target == '' then
        --    _G['TWTMainThreatTarget']:SetText('Threat: ' .. UnitName('target'))
        --    return true
        --end

        TWT.target = ''

        for guid, data in next, TWT.threats do
            if TWT.codes[guid] == UnitName('target') .. UnitHealth('target') then
                TWT.target = guid
            end
        end

        if TWT.target == '' then
            _G['TWTMainThreatTarget']:SetText('Threat: ' .. UnitName('target'))
            TWT.updateTargetFrameThreatIndicators(-1, UnitName('target'))
            return true
        end

        local targetText = TWT.guids[TWT.target]

        _G['TWTMainThreatTarget']:SetText('Threat: ' .. targetText)
        if TWT.threats[TWT.target] then
            if TWT.threats[TWT.target][TWT.name] then
                _G['TWTMainThreatTarget']:SetText('Threat: ' .. targetText .. ' (' .. TWT.threats[TWT.target][TWT.name].perc .. '%)')
            end
        end

    end
    TWT.updateUI()
end

function TWT.send(msg)
    SendAddonMessage(TWT.channel, msg, "RAID")
end

TWT.AGRO = '-Pull Aggro at-'

if TWT.dev then
    TWT.threats = {
        --['Tham\'Grarr'] = {
        [123456] = {
            [TWT.AGRO] = {
                class = 'agro',
                threat = 1,
                perc = 100,
                tps = 10
            },
            ['Smultron'] = {
                class = 'warrior',
                threat = 10,
                perc = 10,
                tps = 10
            },
            ['Momo'] = {
                class = 'mage',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Carol'] = {
                class = 'warrior',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Laugh'] = {
                class = 'paladin',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Astrld'] = {
                class = 'rogue',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['BoB'] = {
                class = 'rogue',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Chlo'] = {
                class = 'hunter',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Slowbro'] = {
                class = 'rogue',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Ilmane'] = {
                class = 'shaman',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Furryslayer'] = {
                class = 'warlock',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Er'] = {
                class = 'priest',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Dispatch'] = {
                class = 'priest',
                threat = 5,
                perc = 5,
                tps = 5
            },
            ['Cinnamom'] = {
                class = 'priest',
                threat = 5,
                perc = 5,
                tps = 5
            },

        }
    }

end

TWT.threatsFrames = {}

function TWT.updateUI()

    --twtprint('time = ' .. (math.floor(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
    --totalPackets / (GetTime() - timeStart) .. ' packets/s')

    for guid, data in next, TWT.threats do
        if TWT.codes[guid] and UnitName('target') and UnitHealth('target') then
            if TWT.codes[guid] == UnitName('target') .. UnitHealth('target') then
                TWT.target = guid
            end
        end
    end

    _G['TWThreatListScrollFrameScrollBar']:Hide()

    for index in next, TWT.threatsFrames do
        TWT.threatsFrames[index]:Hide()
    end

    local index = 0

    for boss, data in next, TWT.threats do
        for player, threatData in next, data do

            if player == TWT.AGRO then
                threatData.tps = ''
                threatData.threat = 1
            else
                if TWT.dev then
                    local tps = math.random(1, 500)
                    threatData.tps = tps
                    threatData.threat = threatData.threat + tps
                end
            end
        end
    end

    if not TWT.threats[TWT.target] then
        return false
    end

    local maxThreat = 0
    local minThreat = 10000000
    local myThreat = 0
    for name, data in next, TWT.threats[TWT.target] do
        if data.threat > maxThreat and name ~= TWT.AGRO then
            maxThreat = data.threat
        end
        if data.threat < minThreat and data.threat ~= 0 and name ~= TWT.AGRO then
            minThreat = data.threat
        end
        if name == TWT.name then
            myThreat = data.threat
        end
    end

    if CheckInteractDistance('target', 1) then
        -- melee
        for name, data in next, TWT.threats[TWT.target] do
            if name == TWT.AGRO then
                data.threat = maxThreat * 1.1 -- - maxThreat
            end
        end
    else
        -- ranged
        for name, data in next, TWT.threats[TWT.target] do
            if name == TWT.AGRO then
                data.threat = maxThreat * 1.3 -- - maxThreat
            end
        end
    end

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats[TWT.target], true) do

        index = index + 1

        if not TWT.threatsFrames[name] then
            TWT.threatsFrames[name] = CreateFrame('Frame', 'TWThreat' .. name, _G["TWThreatListScrollFrameChildren"], 'TWThreat')
        end

        TWT.threatsFrames[name]:SetPoint("TOPLEFT", _G["TWThreatListScrollFrameChildren"], "TOPLEFT", 0, 19 - index * 20)

        data.tps = TWT.calcTPS(name, data)
        data.perc = math.floor((data.threat * 100) / maxThreat)

        local color = TWT.classColors[data.class]
        if name == TWT.name then
            --_G['TWThreat' .. name .. 'BG']:SetTexture(color.r, color.g, color.b, 0.7)
            --_G['TWThreat' .. name .. 'BG']:SetTexture(TWT.classColors['agro'].r, TWT.classColors['agro'].g, TWT.classColors['agro'].b,
            --        data.threat / maxThreat - 0.2)


            if data.perc >= 0 and data.perc <= 50 then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(0, 1, 0, 1)
            elseif data.perc > 50 and data.perc <= 80 then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0.5, 0.1, 1)
            else
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0.1, 0.1, 1)
            end

            TWT.updateTargetFrameThreatIndicators(data.perc, TWT.guids[TWT.target])

            _G['TWTMainThreatTarget']:SetText('Threat: ' .. TWT.guids[TWT.target] .. ' (' .. data.perc .. '%)')

        else
            _G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
        end

        if name == TWT.name then
            _G['TWThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)
        else
            _G['TWThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)
        end

        --data.tps = TWT.calcTPS(name, data)

        _G['TWThreat' .. name .. 'TPS']:SetText(data.tps)

        local threatText = data.threat
        if data.threat > 1000 then
            threatText = math.floor((data.threat / 1000) * 100) / 100 .. 'K'
        end
        if data.threat > 1000000 then
            threatText = math.floor((data.threat / 1000000) * 100) / 100 .. 'M'
        end

        if name == TWT.AGRO then

            local agroInText = ''
            if CheckInteractDistance('target', 1) then
                -- melee
                local meleeThreat = maxThreat * 1.1 - myThreat
                local meleeThreatText = meleeThreat
                if meleeThreat > 1000 then
                    meleeThreatText = math.floor((meleeThreat / 1000) * 100) / 100 .. 'K'
                end
                if meleeThreat > 1000000 then
                    meleeThreatText = math.floor((meleeThreat / 1000000) * 100) / 100 .. 'M'
                end
                agroInText = '+' .. meleeThreatText

                --_G['TWThreat' .. name .. 'Name']:SetText("-Pull Aggro in "..math.floor(meleeThreat / TWT.threats[TWT.target][TWT.name].tps).."s -")

            else
                -- ranged
                local rangedThreat = maxThreat * 1.3 - myThreat
                local rangedThreatText = rangedThreat
                if rangedThreat > 1000 then
                    rangedThreatText = math.floor((rangedThreat / 1000) * 100) / 100 .. 'K'
                end
                if rangedThreat > 1000000 then
                    rangedThreatText = math.floor((rangedThreat / 1000000) * 100) / 100 .. 'M'
                end
                agroInText = '+' .. rangedThreatText
            end

            _G['TWThreat' .. name .. 'Threat']:SetText(agroInText)


        else
            _G['TWThreat' .. name .. 'Threat']:SetText(threatText)

            if data.threat < data.lastThreat then
                _G['TWThreat' .. name .. 'ArrowUp']:Hide()
                _G['TWThreat' .. name .. 'ArrowDown']:Show()
            elseif data.threat > data.lastThreat then
                _G['TWThreat' .. name .. 'ArrowDown']:Hide()
                _G['TWThreat' .. name .. 'ArrowUp']:Show()
            else
                _G['TWThreat' .. name .. 'ArrowDown']:Hide()
                _G['TWThreat' .. name .. 'ArrowUp']:Hide()
            end
        end

        _G['TWThreat' .. name .. 'Perc']:SetText(data.perc .. '%')

        if CheckInteractDistance('target', 1) then

            _G['TWThreat' .. name .. 'BG']:SetWidth(298 * data.perc / 110)
        else
            _G['TWThreat' .. name .. 'BG']:SetWidth(298 * data.perc / 130)
        end

        TWT.threatsFrames[name]:Show()

    end

    _G['TWThreatListScrollFrameScrollBar']:Hide()

    _G['TWThreatListScrollFrame']:UpdateScrollChildRect()
    _G['TWThreatListScrollFrameScrollBar']:Hide()

end

TWT.ui:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.ui:SetScript("OnUpdate", function()
    local plus = 1 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if TWT.inCombat then
            TWT.updateUI()
        end
    end
end)

function TWT.calcTPS(name, data)
    if name ~= TWT.AGRO then

        local older = math.floor(GetTime())
        for i in data.history do
            if i < older then
                older = i
            end
        end

        if TWT.tableSize(data.history) > 5 then
            data.history[older] = nil
        end

        local tps_real = 0

        for i = 0, TWT.tableSize(data.history) - 1 do
            if data.history[math.floor(GetTime()) - i] and data.history[math.floor(GetTime()) - i - 1] then
                tps_real = tps_real + data.history[math.floor(GetTime()) - i] - data.history[math.floor(GetTime()) - i - 1]
            end
        end

        if tps_real >= 0 then
            return math.floor(tps_real / TWT.tableSize(data.history))
        else
            return 0
        end

    end

    return ''
end

TWT.targetFrameVisible = false

function st(t)
    TWT.updateTargetFrameThreatIndicators(t)
end

function start_test()
    TWT.test:Show()
end

TWT.test = CreateFrame('Frame')
TWT.test:Hide()

TWT.test:SetScript("OnShow", function()
    this.startTime = GetTime()
    this.threat = 1
    this.f = 1
end)
TWT.test:SetScript("OnUpdate", function()
    local plus = 0.03 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        this.threat = this.threat + this.f * 1
        if this.threat >= 130 then
            this.f = -1
        end
        if this.threat <= 0 then
            this.f = 1
        end
        TWT.updateTargetFrameThreatIndicators(this.threat)
    end
end)

function TWT.updateTargetFrameThreatIndicators(perc, creature)

    if not creature or creature ~= UnitName('target') then
        _G['TWThreatDisplayTarget']:Hide()
        return false
    end

    if not TWT_CONFIG.glow and not TWT_CONFIG.perc then
        _G['TWThreatDisplayTarget']:Hide()
        return true
    end

    _G['TWThreatDisplayTarget']:Show()

    if TWT_CONFIG.perc and not UnitIsPlayer('target') then
        _G['TWThreatDisplayTargetNumericPerc']:SetText(perc .. '%')
        _G['TWThreatDisplayTargetNumericPerc']:Show()
        _G['TWThreatDisplayTargetNumericBG']:Show()
        _G['TWThreatDisplayTargetNumericBorder']:Show()
    else
        _G['TWThreatDisplayTargetNumericPerc']:Hide()
        _G['TWThreatDisplayTargetNumericBG']:Hide()
        _G['TWThreatDisplayTargetNumericBorder']:Hide()
    end

    if TWT_CONFIG.glow then
        _G['TWThreatDisplayTargetGlow']:Show()
    else
        _G['TWThreatDisplayTargetGlow']:Hide()
        return true
    end

    local unitClassification = UnitClassification('target')
    if unitClassification == 'worldboss' then
        unitClassification = 'elite'
    end

    if perc < 0 then
        _G['TWThreatDisplayTarget']:Hide()
        return false
    elseif perc >= 0 and perc < 50 then
        _G['TWThreatDisplayTargetGlow']:SetVertexColor(perc / 50, 1, 0, perc / 50)
        _G['TWThreatDisplayTargetNumericBG']:SetVertexColor(perc / 50, 1, 0, 1)
    elseif perc >= 50 then
        _G['TWThreatDisplayTargetGlow']:SetVertexColor(1, 1 - (perc - 50) / 50, 0, 1)
        _G['TWThreatDisplayTargetNumericBG']:SetVertexColor(1, 1 - (perc - 50) / 50, 0)
    end

    _G['TWThreatDisplayTargetGlow']:SetTexture('Interface\\addons\\TWThreat\\images\\' .. unitClassification)

    --dev
    --_G['TWThreatDisplayTarget']:Show()

    if TWT.inCombat and TWT.targetFrameVisible then
        _G['TWThreatDisplayTarget']:Show()
    else
        _G['TWThreatDisplayTarget']:Hide()
    end


end

function TWTMainWindow_Resizing()
    _G['TWTMain']:SetAlpha(0.5)
    _G['TWThreatListScrollFrameScrollBar']:Hide()
    _G['TWThreatListScrollFrameScrollBar']:SetAlpha(0)
end

function TWTMainMainWindow_Resized()
    --_G['TWThreatListScrollFrame']:SetHeight(_G['TWTMain']:GetHeight() - 60)
    --_G['TWThreatListScrollFrameChildren']:SetHeight(_G['TWThreatListScrollFrame']:GetHeight())
    --_G['TWThreatListScrollFrame']:UpdateScrollChildRect()
    _G['TWThreatListScrollFrameScrollBar']:Hide()
    _G['TWThreatListScrollFrameScrollBar']:SetAlpha(0)
    _G['TWTMain']:SetAlpha(1)
end

function TWTChangeSetting_OnClick(name, checked, code)
    TWT_CONFIG[code] = checked
end

function TWTCloseButton_OnClick()
    _G['TWTMain']:Hide()
    twtprint('Window closed. Type |cff69ccf0/twt show|cffffffff to restore it.')
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from, 1, true)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from, true)
    end
    table.insert(result, string.sub(self, from))
    return result
end

function TWT.ohShitHereWeSortAgain(t, reverse)
    local a = {}
    for n, l in pairs(t) do
        table.insert(a, { ['threat'] = l.threat, ['perc'] = l.perc, ['tps'] = l.tps, ['name'] = n })
    end
    if reverse then
        table.sort(a, function(a, b)
            return a['threat'] > b['threat']
        end)
    else
        table.sort(a, function(a, b)
            return a['threat'] < b['threat']
        end)
    end

    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
            --        else return a[i]['code'], t[a[i]['name']]
        else
            return a[i]['name'], t[a[i]['name']]
        end
    end
    return iter
end

function TWT.tableSize(t)
    local size = 0
    for _, _ in next, t do
        size = size + 1
    end
    return size
end

-- https://github.com/shagu/pfUI/blob/master/api/api.lua#L596
function TWT.wipe(src)
    -- notes: table.insert, table.remove will have undefined behavior
    -- when used on tables emptied this way because Lua removes nil
    -- entries from tables after an indeterminate time.
    -- Instead of table.insert(t,v) use t[table.getn(t)+1]=v as table.getn collapses nil entries.
    -- There are no issues with hash tables, t[k]=v where k is not a number behaves as expected.
    local mt = getmetatable(src) or {}
    if mt.__mode == nil or mt.__mode ~= "kv" then
        mt.__mode = "kv"
        src = setmetatable(src, mt)
    end
    for k in pairs(src) do
        src[k] = nil
    end
    return src
end
