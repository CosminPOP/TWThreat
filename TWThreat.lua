local _G, _ = _G or getfenv()

local TWT = CreateFrame("Frame")
TWT.addonVer = '0.0.0.2'
TWT.addonName = '|cff69ccf0Momo|cffffffffmeter'
TWT.dev = false

TWT.prefix = 'TWT'
TWT.channel = 'RAID'
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

TWT.fonts = {
    'BalooBhaina', 'BigNoodleTitling',
    'Expressway', 'Homespun', 'Hooge', 'LondrinaSolid',
    'Myriad-Pro', 'PT-Sans-Narrow-Bold', 'PT-Sans-Narrow-Regular',
    'Roboto', 'Share', 'ShareBold',
    'Sniglet', 'SquadaOne',
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

SLASH_TWT1 = "/twt"
SlashCmdList["TWT"] = function(cmd)
    if cmd then
        if string.sub(cmd, 1, 4) == 'show' then
            _G['TWTMain']:Show()
        end

    end

end

TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")

TWT.threats = {}
TWT.target = ''
TWT.lastTarget = ''

TWT.ui = CreateFrame("Frame")
TWT.ui:Hide()
TWT.targetType = 'normal'

local timeStart = GetTime()
local totalPackets = 0

TWT.guids = {}

TWT:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            TWT.init()
        end
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWTGUID:', 1, true) then
            local guidEx = string.split(arg1, ':')
            if guidEx[2] then
                TWT.targetChanged(guidEx[2])
                TWT.targetChangedHelper:Hide()
                TWT.guids[guidEx[2]] = UnitName('target')
                twtdebug('helper stopped - have guid')
                return true
            end
            TWT.targetChangedHelper:Hide()
            twtdebug('helper stopped - not have guid')
        end
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWT:', 1, true) then
            TWT.handleServerMSG(arg1)
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == TWT.prefix then
            TWT.handleClientMSG(arg2, arg4)
        end
        if event == "PLAYER_REGEN_DISABLED" then
            TWT.combatStart()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            TWT.combatEnd()
        end
        if event == "PLAYER_TARGET_CHANGED" then
            if not UnitName('target') then
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if UnitIsPlayer('target') then
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
                _G['TWTMainThreatTarget']:SetText('Threat: ' .. UnitName('target'))
                return false
            end

            if GetNumRaidMembers() > 0 then
                TWT.channel = 'RAID'
            else
                TWT.channel = 'PARTY'
            end

            -- load from guids cache first
            -- even if its the wrong guid, it will update ui fast, not wait for server guid
            local cacheGUID = 0
            for guid, creature in TWT.guids do
                if creature == UnitName('target') then
                    cacheGUID = guid
                end
            end

            if cacheGUID ~= 0 then
                twtdebug('cached guid found')
                TWT.targetChanged(cacheGUID)
            end

            if not TWT.threats[cacheGUID] then
                TWT.updateTargetFrameThreatIndicators(-1)
            end

            TWT.targetChangedHelper:Show()
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
        TWT_CONFIG.font = 'Roboto'
        TWT_CONFIG.barHeight = 20
        TWT_CONFIG.fullScreenGlow = false
    end

    --TWT_CONFIG.font = 'Roboto'
    --TWT_CONFIG.barHeight = 20
    --TWT_CONFIG.fullScreenGlow = false


    _G['TWTFullScreenGlowTexture']:SetWidth(GetScreenWidth())
    _G['TWTFullScreenGlowTexture']:SetHeight(GetScreenHeight())

    _G['TWTMainSettingsFrameHeightSlider']:SetValue(TWT_CONFIG.barHeight)

    _G['TWTMainSettingsFontButton']:SetText(TWT_CONFIG.font)

    _G['TWTMainSettingsTargetFrameGlow']:SetChecked(TWT_CONFIG.glow)
    _G['TWTMainSettingsPercNumbers']:SetChecked(TWT_CONFIG.perc)
    _G['TWTMainSettingsShowInCombat']:SetChecked(TWT_CONFIG.showInCombat)
    _G['TWTMainSettingsHideOOC']:SetChecked(TWT_CONFIG.hideOOC)
    _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)

    _G['TWTMainSettingsFontButtonNT']:SetVertexColor(0.4, 0.4, 0.4)

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


    -- fonts
    local fontFrames = {}

    for i, font in TWT.fonts do
        fontFrames[i] = CreateFrame('Button', 'Font_' .. font, _G['TWTMainSettingsFontList'], 'TWTFontFrameTemplate')

        fontFrames[i]:SetPoint("TOPLEFT", _G["TWTMainSettingsFontList"], "TOPLEFT", 0, 17 - i * 17)

        _G['Font_' .. font]:SetID(i)
        _G['Font_' .. font .. 'Name']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. font .. ".ttf", 15)
        _G['Font_' .. font .. 'Name']:SetText(font)
        _G['Font_' .. font .. 'HT']:SetVertexColor(1, 1, 1, 0.5)

        fontFrames[i]:Show()
    end

end

function TWT.handleServerMSG(msg)

    totalPackets = totalPackets + 1

    local msgEx = string.split(msg, ':')

    if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] then

        local creature = msgEx[2]
        local guid = msgEx[3]
        local threat = tonumber(msgEx[4])

        TWT.send(TWT.class .. ':' .. guid .. ':' .. threat)

        if TWT.target == '' then
            TWT.target = guid
        end

        TWT.guids[guid] = creature

    end
end

function TWT.handleClientMSG(msg, sender)
    --twtprint(sender .. ': ' .. msg)
    --"priest:target:guid:threat:lastthreat:hp"
    local ex = string.split(msg, ':')
    if ex[1] and ex[2] and ex[3] then

        local player = sender
        local class = ex[1]
        local guid = ex[2]
        local threat = tonumber(ex[3])

        if not TWT.threats[guid] then
            TWT.threats[guid] = {}
        end
        if not TWT.threats[guid][player] then
            TWT.threats[guid][player] = {}
        end
        local tps = 0

        if not TWT.threats[guid][TWT.AGRO] then
            TWT.threats[guid][TWT.AGRO] = {
                class = 'agro',
                threat = 0,
                perc = 100,
                tps = 0,
                history = {},
                lastThreat = 0,
                dir = '-'
            }
        end

        if TWT.threats[guid][player].threat then

            TWT.threats[guid][player].lastThreat = TWT.threats[guid][player].threat

            TWT.threats[guid][player].threat = threat
            TWT.threats[guid][player].history[math.floor(GetTime())] = threat
            TWT.threats[guid][player].dir = '-'

        else
            TWT.threats[guid][player] = {
                class = class,
                threat = threat,
                perc = 0,
                tps = tps,
                lastThreat = 0,
                history = {
                    [math.floor(GetTime())] = threat
                },
                dir = '-'
            }
        end

    end
    TWT.updateUI()
end

function TWT.combatStart()

    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.guids = TWT.wipe(TWT.guids)

    TWT.updateUI()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if TWT_CONFIG.showInCombat then
        _G['TWTMain']:Show()
    end
end

function TWT.combatEnd()
    --left combat

    TWT.updateTargetFrameThreatIndicators(-1, '')
    TWT.threats = TWT.wipe(TWT.threats)
    TWT.guids = TWT.wipe(TWT.guids)

    twtprint('time = ' .. (math.floor(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    TWT.updateUI()

    if TWT_CONFIG.hideOOC then
        _G['TWTMain']:Hide()
    end

end

TWT.targetChangedHelper = CreateFrame('Frame')
TWT.targetChangedHelper:Hide()

TWT.targetChangedHelper:SetScript("OnShow", function()
    this.startTime = GetTime()
    this.canSend = true
end)
TWT.targetChangedHelper:SetScript("OnHide", function()
    this.startTime = GetTime()
    this.canSend = true
end)
TWT.targetChangedHelper:SetScript("OnUpdate", function()
    local plus = 0.2 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if this.canSend then
            twtdebug('helper sent')
            SendAddonMessage("TWTGUID", "GETGUID", TWT.channel)
            this.canSend = false
        else
            twtdebug(' waiting for cansend ')
        end
    end
end)

function TWT.targetChanged(guid)

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

    -- player check
    if UnitIsPlayer('target') then
        TWT.updateTargetFrameThreatIndicators(-1)
        --TWT.lastTarget = UnitName('target')
    else

        TWT.target = guid
        TWT.lastTarget = UnitName('targettarget') --tank

        local targetText = UnitName('target')

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
    SendAddonMessage(TWT.prefix, msg, TWT.channel)
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

local nf = CreateFrame('Frame')
nf:Hide()

local framePoint = ''

nf:SetScript("OnShow", function()
    this.startTime = GetTime()
    this.mh = 70
    this.ch = 0
    _G['CombatHeal']:SetPoint("TOPLEFT", framePoint, "TOPLEFT", 0, 30)
    _G['CombatHeal']:SetAlpha(1)
    _G['CombatHeal']:Show()
end)
nf:SetScript("OnUpdate", function()
    local plus = 0.01 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if this.ch < this.mh then
            this.ch = this.ch + 1
            _G['CombatHeal']:SetPoint("TOPLEFT", framePoint, "TOPLEFT", 0, 30 + this.ch)
            _G['CombatHeal']:SetAlpha(1 - this.ch / this.mh)
            return true
        end
        _G['CombatHeal']:SetAlpha(0)
        nf:Hide()
        _G['CombatHeal']:Hide()
    end
end)

function np_test()

    local Nameplates = {}

    for _, plate in pairs({ WorldFrame:GetChildren() }) do
        local name = plate:GetName()
        if plate then

            if plate:GetObjectType() == 'Button' then

                twtdebug(plate:GetObjectType())

                framePoint = plate

                _G['CombatHeal']:SetWidth(plate:GetWidth())
                _G['CombatHeal']:SetPoint("TOPLEFT", plate, "TOPLEFT", 0, 30)

                nf:Show()

            end
        end
        if name then
            twtdebug(name)
        end
    end

end

function TWT.updateUI()

    --twtprint('time = ' .. (math.floor(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
    --totalPackets / (GetTime() - timeStart) .. ' packets/s')
    --twtdebug('update ui call target = ' .. TWT.target)

    if TWT.target == '' then
        twtdebug('uiupdate returned, target = blank')
        return false
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

    local tankThreat = 0
    local myThreat = 0

    local tankName = ''

    if UnitIsPlayer('target') or not UnitName('target') then
        tankName = TWT.lastTarget
    else
        tankName = UnitName('targettarget')
        TWT.lastTarget = tankName
    end

    if TWT.threats[TWT.target] then
        if TWT.threats[TWT.target][tankName] then
            if TWT.threats[TWT.target][tankName].threat then
                tankThreat = TWT.threats[TWT.target][tankName].threat
            end
        end
    end

    if TWT.threats[TWT.target] then
        if TWT.threats[TWT.target][TWT.name] then
            if TWT.threats[TWT.target][TWT.name].threat then
                myThreat = TWT.threats[TWT.target][TWT.name].threat
            end
        end
    end

    if CheckInteractDistance('target', 1) then
        -- melee
        TWT.threats[TWT.target][TWT.AGRO].threat = tankThreat * 1.1
        TWT.threats[TWT.target][TWT.AGRO].perc = 110
    else
        -- ranged
        TWT.threats[TWT.target][TWT.AGRO].threat = tankThreat * 1.3
        TWT.threats[TWT.target][TWT.AGRO].perc = 130
    end

    local maxThreat = TWT.threats[TWT.target][TWT.AGRO].threat

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats[TWT.target], true) do

        index = index + 1
        if not TWT.threatsFrames[name] then
            TWT.threatsFrames[name] = CreateFrame('Frame', 'TWThreat' .. name, _G["TWThreatListScrollFrameChildren"], 'TWThreat')
        end

        _G['TWThreat' .. name .. 'Name']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
        _G['TWThreat' .. name .. 'TPS']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
        _G['TWThreat' .. name .. 'Threat']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
        _G['TWThreat' .. name .. 'Perc']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")

        _G['TWThreat' .. name]:SetHeight(TWT_CONFIG.barHeight - 1)
        _G['TWThreat' .. name .. 'BG']:SetHeight(TWT_CONFIG.barHeight - 2)

        TWT.threatsFrames[name]:SetPoint("TOPLEFT", _G["TWThreatListScrollFrameChildren"], "TOPLEFT", 0, TWT_CONFIG.barHeight - 1 - index * TWT_CONFIG.barHeight)


        -- icons
        if name == tankName then
            _G['TWThreat' .. name .. 'Tank']:Show()
            _G['TWThreat' .. name .. 'AGRO']:Hide()
        elseif name == TWT.AGRO then
            _G['TWThreat' .. name .. 'AGRO']:Show()
            _G['TWThreat' .. name .. 'Tank']:Hide()
        else
            _G['TWThreat' .. name .. 'AGRO']:Hide()
            _G['TWThreat' .. name .. 'Tank']:Hide()
        end

        -- tps
        data.tps = TWT.calcTPS(name, data)
        _G['TWThreat' .. name .. 'TPS']:SetText(data.tps)


        -- perc
        if CheckInteractDistance('target', 1) then
            if name == TWT.AGRO then
                data.perc = math.floor(110 - myThreat * 110 / maxThreat)
            else
                data.perc = math.floor(data.threat * 110 / maxThreat)
            end
        else
            if name == TWT.AGRO then
                data.perc = math.floor(130 - myThreat * 130 / maxThreat)
            else
                data.perc = math.floor(data.threat * 130 / maxThreat)
            end
        end

        if name == tankName then
            data.perc = 100
        end

        if string.find(data.perc, '#INF', 1, true) then
            data.perc = 0
        end

        _G['TWThreat' .. name .. 'Perc']:SetText(data.perc .. '%')



        -- name
        _G['TWThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)


        -- bar
        local color = TWT.classColors[data.class]
        if name == TWT.name then

            _G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 1)

            TWT.updateTargetFrameThreatIndicators(data.perc, TWT.guids[TWT.target])

            _G['TWTMainThreatTarget']:SetText('Threat: ' .. (TWT.guids[TWT.target] or '') .. ' (' .. data.perc .. '%)')

            _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))

        elseif name == TWT.AGRO then
            _G['TWThreat' .. name .. 'Threat']:SetText('+' .. TWT.formatNumber(maxThreat - myThreat))
            _G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
        else
            _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))
            _G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
        end

        if data.perc >= 100 then
            -- red for anyone over 100%
            _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0, 0, 0.9)
        end

        -- dir
        if name ~= TWT.AGRO then
            if data.dir then

                if data.dir == 'down' then
                    _G['TWThreat' .. name .. 'ArrowUp']:Hide()
                    _G['TWThreat' .. name .. 'ArrowDown']:Show()
                elseif data.dir == 'up' then
                    _G['TWThreat' .. name .. 'ArrowDown']:Hide()
                    _G['TWThreat' .. name .. 'ArrowUp']:Show()
                else
                    _G['TWThreat' .. name .. 'ArrowDown']:Hide()
                    _G['TWThreat' .. name .. 'ArrowUp']:Hide()
                end

            end
        end

        -- bar width
        if CheckInteractDistance(TWT.targetFromName(name), 1) then
            _G['TWThreat' .. name .. 'BG']:SetWidth(298 * data.perc / 110 + 1)
        else
            _G['TWThreat' .. name .. 'BG']:SetWidth(298 * data.perc / 130 + 1)
        end

        if name == TWT.AGRO then
            _G['TWThreat' .. name .. 'BG']:SetWidth(298)

            local percToAgro = 0

            if CheckInteractDistance('target', 1) then
                percToAgro = 110 - data.perc
            else
                percToAgro = 130 - data.perc
            end

            if percToAgro >= 0 and percToAgro < 50 then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(percToAgro / 50, 1, 0, 1)
            elseif percToAgro >= 50 then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 1 - (percToAgro - 50) / 50, 0, 1)

            end
            if tankName == TWT.name then
                _G['TWThreat' .. name .. 'Perc']:SetText()
            end
        elseif name == tankName then
            _G['TWThreat' .. name .. 'BG']:SetWidth(298)
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
        if UnitAffectingCombat('player') then
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

        if data.history[math.floor(GetTime())] and data.history[math.floor(GetTime()) - 1] then
            if data.history[math.floor(GetTime())] > data.history[math.floor(GetTime()) - 1] then
                data.dir = 'up'
            elseif data.history[math.floor(GetTime())] < data.history[math.floor(GetTime()) - 1] then
                data.dir = 'down'
            else
                data.dir = '-'
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
    local plus = 0.02 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        this.threat = this.threat + this.f * 1
        if this.threat >= 50 then
            this.f = -1
        end
        if this.threat <= 0 then
            this.f = 1
        end
        --TWT.updateTargetFrameThreatIndicators(this.threat)

        --/run start_test()


    end
end)

function TWT.updateTargetFrameThreatIndicators(perc, creature)

    if TWT_CONFIG.fullScreenGlow then

        _G['TWTFullScreenGlow']:SetAlpha((perc - 50) / 50 + math.random() / 10)

        _G['TWTFullScreenGlow']:SetWidth(GetScreenWidth() + 100 - perc)
        _G['TWTFullScreenGlow']:SetHeight(GetScreenHeight() + 100 - perc)

        _G['TWTFullScreenGlow']:Show()
    else
        _G['TWTFullScreenGlow']:Hide()
    end

    if not creature or creature ~= UnitName('target') or perc == -1 then
        _G['TWThreatDisplayTarget']:Hide()
        return false
    end

    if not TWT_CONFIG.glow and not TWT_CONFIG.perc then
        _G['TWThreatDisplayTarget']:Hide()
        return false
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

        if perc < 0 then
            return false
        elseif perc >= 0 and perc < 50 then
            _G['TWThreatDisplayTargetNumericBG']:SetVertexColor(perc / 50, 1, 0, 1)
        elseif perc >= 50 then
            _G['TWThreatDisplayTargetNumericBG']:SetVertexColor(1, 1 - (perc - 50) / 50, 0)
        end
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

    if UnitAffectingCombat('player') and TWT.targetFrameVisible then
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

function TWTSettingsCloseButton_OnClick()
    _G['TWTMainSettings']:Hide()
end

function TWTFontButton_OnClick()
    if _G['TWTMainSettingsFontList']:IsVisible() then
        _G['TWTMainSettingsFontList']:Hide()
    else
        _G['TWTMainSettingsFontList']:Show()
    end
end

function TWTFontSelect(id)
    TWT_CONFIG.font = TWT.fonts[id]
    _G['TWTMainSettingsFontButton']:SetText(TWT_CONFIG.font)
    TWT.updateUI()
end

function FrameHeightSlider_OnValueChanged(self, value, userInput)
    TWT_CONFIG.barHeight = _G['TWTMainSettingsFrameHeightSlider']:GetValue()
    TWT.updateUI()
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

function TWT.formatNumber(n)
    if n < 999 then
        return math.floor(n)
    end
    if n < 99999 then
        return math.floor(n / 10) / 100 .. 'K' or 0 --562
    end
    if n < 999999 then
        return math.floor(n / 10) / 100 .. 'K' or 0 --562
    end
    return math.floor(n / 1000) / 1000 .. 'M' or 0 --562
end

function TWT.tableSize(t)
    local size = 0
    for _, _ in next, t do
        size = size + 1
    end
    return size
end

function TWT.targetFromName(name)
    if name == TWT.name then
        return 'target'
    end
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local n = GetRaidRosterInfo(i)
                if n == name then
                    return 'raid' .. i
                end
            end
        end
    end
    if TWT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) then
                    if name == UnitName('party' .. i) then
                        return 'party' .. i
                    end
                end
            end
        end
    end

    return 'target'
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
