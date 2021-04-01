local _G, _ = _G or getfenv()

local TWT = CreateFrame("Frame")
TWT.addonVer = '0.9'
TWT.showedUpdateNotification = false
TWT.addonName = '|cffabd473TW|cff11cc11 |cffcdfe00Threatmeter'

--|cff1dff00
--|cff58ff00
--|cff89ff00
--|cffcdfe00
--|cfffffe00
--|cfff2bc00
--|cffe57500
--|cffda3800
--|cffcf0000


TWT.prefix = 'TWT'
TWT.channel = 'RAID'
TWT.handShakeSent = false

TWT.name = UnitName('player')
local _, cl = UnitClass('player')
TWT.class = string.lower(cl)

TWT.meleeRange = 5
TWT.raidTargetIconIndex = {}
TWT.secondOnThreat = {}
TWT.lastMessageTime = {}
TWT.lastAggroWarningSoundTime = 0
TWT.lastAggroWarningGlowTime = 0

TWT.AGRO = '-Pull Aggro at-'
TWT.threatsFrames = {}
TWT.tank = {}

TWT.threats = {}
TWT.target = ''
TWT.lastTarget = ''
TWT.guids = {}

TWT.targetFrameVisible = false

TWT.nameLimit = 30
TWT.windowStartWidth = 300
TWT.windowWidth = 300

TWT.custom = {
    ['The Prophet Skeram'] = 0
}

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
        DEFAULT_CHAT_FRAME:AddMessage('[TWT]|cff0070de:' .. GetTime() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(TWT.classColors[TWT.class].c .. "[TWT] |cffffffff" .. a)
end

function twtdebug(a)
    if not TWT_CONFIG.debug then
        return false
    end
    if type(a) == 'boolean' then
        if a then
            twtprint('|cff0070de[TWTDEBUG:' .. GetTime() .. ']|cffffffff[true]')
        else
            twtprint('|cff0070de[TWTDEBUG:' .. GetTime() .. ']|cffffffff[false]')
        end
        return true
    end
    twtprint('|cff0070de[TWTDEBUG:' .. GetTime() .. ']|cffffffff[' .. a .. ']')
end

SLASH_TWT1 = "/twt"
SlashCmdList["TWT"] = function(cmd)
    if cmd then
        if string.sub(cmd, 1, 4) == 'show' then
            _G['TWTMain']:Show()
            TWT_CONFIG.visible = true
            return true
        end
        if string.sub(cmd, 1, 5) == 'debug' then
            if TWT_CONFIG.debug then
                TWT_CONFIG.debug = false
                _G['pps']:Hide()
                twtprint('Debugging disabled')
                return true
            end
            TWT_CONFIG.debug = true
            _G['pps']:Show()
            twtdebug('Debugging enabled')
            return true
        end
        twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff available commands:')
        twtprint('/twt show - shows the main window (also /twtshow)')
    end
end

SLASH_TWTSHOW1 = "/twtshow"
SlashCmdList["TWTSHOW"] = function(cmd)
    if cmd then
        _G['TWTMain']:Show()
        TWT_CONFIG.visible = true
    end
end

SLASH_TWTDEBUG1 = "/twtdebug"
SlashCmdList["TWTDEBUG"] = function(cmd)
    if cmd then
        if TWT_CONFIG.debug then
            TWT_CONFIG.debug = false
            twtprint('Debugging disabled')
            return true
        end
        TWT_CONFIG.debug = true
        twtdebug('Debugging enabled')
        return true
    end
end

TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")
TWT:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
TWT:RegisterEvent("PLAYER_ENTERING_WORLD")

TWT:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
TWT:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS")

TWT.ui = CreateFrame("Frame")
TWT.ui:Hide()

local timeStart = GetTime()
local totalPackets = 0
local totalData = 0

TWT:SetScript("OnEvent", function()
    if event then
        -- heal above name stuff
        if event == 'CHAT_MSG_SPELL_SELF_BUFF' or event == 'CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS' then
            local _, _, heal = string.find(arg1, "for (%d+)");
            local _, _, target = string.find(arg1, "heals (%a+) for");
            if target and heal then
                --np_test(heal, target)
            end
        end
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            TWT.init()
        end
        if event == "PLAYER_ENTERING_WORLD" then
            TWT.sendMyVersion()
            TWT.combatEnd()
        end
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWTGUID:', 1, true) then
            local guidEx = string.split(arg1, ':')
            if guidEx[2] then

                TWT.targetChanged(tonumber(guidEx[2]))
                TWT.guids[tonumber(guidEx[2])] = UnitName('target')
                twtdebug('got guid: ' .. guidEx[2])
                return true
            end
        end
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWT:', 1, true) then
            TWT.handleServerMSG(arg1)
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == TWT.prefix then
            TWT.handleClientMSG(arg2, arg4)

            if string.sub(arg2, 1, 11) == 'TWTVersion:' and arg4 ~= TWT.name then
                if not TWT.showedUpdateNotification then
                    local verEx = string.split(arg2, ':')
                    if TWT.version(verEx[2]) > TWT.version(TWT.addonVer) then
                        twtprint('New version available ' ..
                                TWT.classColors[TWT.class].c .. 'v' .. verEx[2] .. ' |cffffffff(current version ' ..
                                TWT.classColors['paladin'].c .. 'v' .. TWT.addonVer .. '|cffffffff)')
                        twtprint('Update at ' .. TWT.classColors[TWT.class].c .. 'https://github.com/CosminPOP/TWThreat')
                        TWT.showedUpdateNotification = true
                    end
                end
            end

        end
        if event == "PLAYER_REGEN_DISABLED" then
            TWT.combatStart()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            TWT.combatEnd()
        end
        if event == "PLAYER_TARGET_CHANGED" then

            _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)

            if GetNumRaidMembers() > 0 then
                TWT.channel = 'RAID'
            else
                TWT.channel = 'PARTY'
            end

            if not UnitExists('target') then
                --twtdebug('lost target, prev target = ' .. TWT.target)
                --TWT.target = ''
                --TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if UnitIsDead('target') then
                TWT.target = ''
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if UnitIsPlayer('target') then
                --show topmost
                twtdebug('target is player, showing threat for ' .. TWT.target)
                --TWT.target = '' -- UnitIsPlayer('target') and 'max' or ''

                -- twtdebug('player or none')
                --_G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)
                --TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if UnitClassification('target') ~= 'worldboss' and
                    UnitClassification('target') ~= 'elite' then
                TWT.target = ''
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            --if not UnitAffectingCombat('player') then
            --    TWT.target = ''
            --    _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)
            --    TWT.updateTargetFrameThreatIndicators(-1)
            --    return false
            --end

            if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
                TWT.target = ''
                _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            -- find target guid based on mark
            if GetRaidTargetIndex("target") ~= 0 then
                for guid, index in next, TWT.raidTargetIconIndex do
                    if index == GetRaidTargetIndex("target") then
                        TWT.target = guid
                        twtdebug('found target guid = ' .. guid .. ' based on mark')
                        return true
                    end
                end
            end

            --TWT.target = ''

            TWT.updateTargetFrameThreatIndicators(-1)
            TWT.targetChangedHelper:Show()
        end
        --if event == 'CHAT_MSG_COMBAT_HOSTILE_DEATH' and TWT_CONFIG.tankMode then
        --    local wipe = false
        --    for guid, gData in next, TWT.threats do
        --        if TWT.guids[guid] then
        --            if arg1 == TWT.guids[guid] .. ' dies.' then
        --                wipe = true
        --            end
        --        end
        --    end
        --    TWT.wipeThreats = wipe
        --end
    end
end)

TWT.glowFader = CreateFrame('Frame')
TWT.glowFader:Hide()

TWT.glowFader:SetScript("OnShow", function()
    this.startTime = GetTime()
    this.dir = 10
    _G['TWTFullScreenGlow']:SetAlpha(0.01)
    _G['TWTFullScreenGlow']:Show()
end)
TWT.glowFader:SetScript("OnHide", function()
    this.startTime = GetTime()
end)
TWT.glowFader:SetScript("OnUpdate", function()
    local plus = 0.01
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()

        if _G['TWTFullScreenGlow']:GetAlpha() >= 1 then
            this.dir = -1
            --_G['TWTFullScreenGlow']:SetAlpha(1)
        end

        _G['TWTFullScreenGlow']:SetAlpha(_G['TWTFullScreenGlow']:GetAlpha() + 0.03 * this.dir)

        if _G['TWTFullScreenGlow']:GetAlpha() <= 0 then
            TWT.glowFader:Hide()
        end


    end
end)

function TWT.init()

    if not TWT_CONFIG then
        TWT_CONFIG = {
            visible = true,
            colTPS = true,
            colThreat = true,
            colPerc = true,
            labelRow = true,
        }
    end

    TWT_CONFIG.glow = TWT_CONFIG.glow or false
    TWT_CONFIG.perc = TWT_CONFIG.perc or false
    TWT_CONFIG.showInCombat = TWT_CONFIG.showInCombat or false
    TWT_CONFIG.hideOOC = TWT_CONFIG.hideOOC or false
    TWT_CONFIG.font = TWT_CONFIG.font or 'Roboto'
    TWT_CONFIG.barHeight = TWT_CONFIG.barHeight or 20
    TWT_CONFIG.fullScreenGlow = TWT_CONFIG.fullScreenGlow or false
    TWT_CONFIG.aggroSound = TWT_CONFIG.aggroSound or false
    TWT_CONFIG.tankMode = TWT_CONFIG.tankMode or false
    TWT_CONFIG.lock = TWT_CONFIG.lock or false
    TWT_CONFIG.visible = TWT_CONFIG.visible or false
    TWT_CONFIG.colTPS = TWT_CONFIG.colTPS or false
    TWT_CONFIG.colThreat = TWT_CONFIG.colThreat or false
    TWT_CONFIG.colPerc = TWT_CONFIG.colPerc or false
    TWT_CONFIG.labelRow = TWT_CONFIG.labelRow or false

    --TWT_CONFIG.combatAlpha = TWT_CONFIG.combatAlpha or 1
    --TWT_CONFIG.oocAlpha = TWT_CONFIG.oocAlpha or 1

    TWT_CONFIG.debug = TWT_CONFIG.debug or false

    if TWT_CONFIG.visible then
        _G['TWTMain']:Show()
    else
        _G['TWTMain']:Hide()
    end

    if TWT_CONFIG.tankMode then
        _G['TWTMainSettingsFullScreenGlow']:Disable()
    end

    if TWT_CONFIG.lock then
        _G['TWTMainLockButton']:SetText('u')
    else
        _G['TWTMainLockButton']:SetText('L')
    end

    _G['TWTFullScreenGlowTexture']:SetWidth(GetScreenWidth())
    _G['TWTFullScreenGlowTexture']:SetHeight(GetScreenHeight())

    _G['TWTMainSettingsFrameHeightSlider']:SetValue(TWT_CONFIG.barHeight)

    _G['TWTMainSettingsFontButton']:SetText(TWT_CONFIG.font)

    _G['TWTMainSettingsTargetFrameGlow']:SetChecked(TWT_CONFIG.glow)
    _G['TWTMainSettingsPercNumbers']:SetChecked(TWT_CONFIG.perc)
    _G['TWTMainSettingsShowInCombat']:SetChecked(TWT_CONFIG.showInCombat)
    _G['TWTMainSettingsHideOOC']:SetChecked(TWT_CONFIG.hideOOC)
    _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
    _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.aggroSound)
    _G['TWTMainSettingsTankMode']:SetChecked(TWT_CONFIG.tankMode)

    _G['TWTMainSettingsColumnsTPS']:SetChecked(TWT_CONFIG.colTPS)
    _G['TWTMainSettingsColumnsThreat']:SetChecked(TWT_CONFIG.colThreat)
    _G['TWTMainSettingsColumnsPercent']:SetChecked(TWT_CONFIG.colPerc)

    _G['TWTMainSettingsLabelRow']:SetChecked(TWT_CONFIG.labelRow)

    TWT.setColumnLabels()

    if TWT_CONFIG.labelRow then
        _G['TWThreatListScrollFrame']:SetPoint('TOPLEFT', 1, -40)
        _G['TWTMainNameLabel']:Show()
    else
        _G['TWThreatListScrollFrame']:SetPoint('TOPLEFT', 1, -20)
        _G['TWTMainNameLabel']:Hide()
        _G['TWTMainTPSLabel']:Hide()
        _G['TWTMainThreatLabel']:Hide()
        _G['TWTMainPercLabel']:Hide()
    end

    _G['TWTMainSettingsFontButtonNT']:SetVertexColor(0.4, 0.4, 0.4)

    local color = TWT.classColors[TWT.class]
    _G['TWTMainSettingsButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainCloseButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainSettingsCloseButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainLockButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)

    _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)

    twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff loaded.')

    TWTMainMainWindow_Resized()
    TWT.ui:Show()

    _G['TWTMainTitleBG']:SetVertexColor(color.r, color.g, color.b)
    _G['TWTMainSettingsTitleBG']:SetVertexColor(color.r, color.g, color.b)
    _G['TWTMainTankModeWindowTitleBG']:SetVertexColor(color.r, color.g, color.b)

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

    _G['TWThreatListScrollFrameScrollBarScrollUpButton']:SetNormalTexture('')
    _G['TWThreatListScrollFrameScrollBarScrollUpButton']:SetDisabledTexture('')
    _G['TWThreatListScrollFrameScrollBarScrollUpButton']:SetHighlightTexture('')
    _G['TWThreatListScrollFrameScrollBarScrollUpButton']:SetPushedTexture('')

    _G['TWThreatListScrollFrameScrollBarScrollDownButton']:SetNormalTexture('')
    _G['TWThreatListScrollFrameScrollBarScrollDownButton']:SetDisabledTexture('')
    _G['TWThreatListScrollFrameScrollBarScrollDownButton']:SetHighlightTexture('')
    _G['TWThreatListScrollFrameScrollBarScrollDownButton']:SetPushedTexture('')

    _G['TWThreatListScrollFrameScrollBarThumbTexture']:SetTexture('')

    TWT.handShakeDelay:Show()
end

TWT.handShakeDelay = CreateFrame('Frame')
TWT.handShakeDelay:Hide()
TWT.handShakeDelay:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.handShakeDelay:SetScript("OnUpdate", function()
    local plus = 1 --sec
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        TWT.sendHandShake()
        TWT.handShakeDelay:Hide()
    end
end)

function TWT.sendHandShake()
    SendAddonMessage("TWT_HANDSHAKE", "twt", TWT.channel)
    twtdebug('handshake sent')
end

function TWT.handleServerMSG(msg)
    twtdebug('smesg: ' .. msg)
    totalPackets = totalPackets + 1
    totalData = totalData + string.len(msg)

    local msgEx = string.split(msg, ':')

    if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] then

        local creature = msgEx[2]
        local guid = tonumber(msgEx[3])
        local threat = tonumber(msgEx[4])
        local melee = tonumber(msgEx[5]) <= TWT.meleeRange and 1 or 0

        threat = threat >= 1 and threat or 1

        TWT.send(TWT.class .. ':' .. guid .. ':' .. threat .. ':' .. melee .. ':' .. TWT.isTank(guid), guid)

        --if TWT.target == '' then
        --    TWT.target = guid
        --end

        TWT.guids[guid] = creature

    end
end

function TWT.handleClientMSG(msg, sender)
    -- format "class:guid:threat:melee:tank"
    --twtdebug(msg)
    twtdebug('Cmesg: ' .. msg)
    local ex = string.split(msg, ':')
    if ex[1] and ex[2] and ex[3] and ex[4] and ex[5] then

        local player = sender
        local class = ex[1]
        local guid = tonumber(ex[2])
        local threat = tonumber(ex[3])
        local melee = tonumber(ex[4]) == 1
        local tank = tonumber(ex[5]) == 1

        if not TWT.threats[guid] then
            TWT.threats[guid] = {}
        end

        if not TWT.threats[guid][TWT.name] then
            TWT.threats[guid][TWT.name] = {
                class = TWT.class,
                threat = 0,
                perc = 0,
                tps = 0,
                history = {},
                melee = melee,
                stamp = GetTime(),
                tank = tank
            }
        end

        if not TWT.threats[guid][TWT.AGRO] then
            TWT.threats[guid][TWT.AGRO] = {
                class = 'agro',
                threat = 0,
                perc = 100,
                tps = '',
                history = {},
                melee = true,
                stamp = GetTime(),
                tank = false
            }
        end

        if TWT.threats[guid][player] then
            TWT.threats[guid][player].threat = threat
            TWT.threats[guid][player].melee = melee
            TWT.threats[guid][player].stamp = GetTime()
            TWT.threats[guid][player].tank = tank

        else
            TWT.threats[guid][player] = {
                class = class,
                threat = threat,
                perc = 0,
                tps = 0,
                history = {},
                melee = melee,
                stamp = GetTime(),
                tank = tank
            }
        end

        TWT.calcPerc(guid)

    end
    TWT.updateUI()
end

function TWT.calcPerc(guid)

    local tankThreat = 1

    -- max
    for name, data in next, TWT.threats[guid] do
        if name ~= TWT.AGRO and data.tank then
            tankThreat = data.threat
        end
    end

    --perc
    for name, data in next, TWT.threats[guid] do
        if name ~= TWT.AGRO then
            data.perc = TWT.round(data.tank and 100 or data.threat * 100 / (tankThreat * (data.melee and 1.1 or 1.3)))
        end
    end

end

function TWT.isTank(guid)

    if not TWT.tank[guid] then
        TWT.tank[guid] = 0
    end

    if UnitExists('target') and not UnitIsPlayer('target')
            and UnitExists('targettarget') and UnitName('targettarget') ~= TWT.name then
        TWT.tank[guid] = 0
    end

    if UnitExists('target') and not UnitIsPlayer('target')
            and UnitExists('targettarget') and UnitName('targettarget') == TWT.name then
        TWT.tank[guid] = 1
    end

    return TWT.tank[guid]

end

function TWT.combatStart()

    TWT.sendHandShake()

    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.raidTargetIconIndex = TWT.wipe(TWT.raidTargetIconIndex)
    TWT.guids = TWT.wipe(TWT.guids)

    TWT.secondOnThreat = TWT.wipe(TWT.secondOnThreat)
    TWT.lastMessageTime = TWT.wipe(TWT.lastMessageTime)

    TWT.tank = TWT.wipe(TWT.tank)

    TWT.updateUI()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if TWT_CONFIG.showInCombat then
        _G['TWTMain']:Show()
    end

    if TWT_CONFIG.fullScreenGlow then
        --TWT.fullScreenGlowAnimator:Show()
    end

    TWT.barAnimator:Show()
end

function TWT.combatEnd()

    TWT.updateTargetFrameThreatIndicators(-1, '')
    TWT.threats = TWT.wipe(TWT.threats)
    TWT.raidTargetIconIndex = TWT.wipe(TWT.raidTargetIconIndex)
    TWT.guids = TWT.wipe(TWT.guids)

    TWT.guids = TWT.wipe(TWT.guids)

    twtdebug('time = ' .. (math.floor(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    totalData = 0
    TWT.updateUI()

    if TWT_CONFIG.hideOOC then
        _G['TWTMain']:Hide()
    end

    if TWT_CONFIG.fullScreenGlow then
        --TWT.fullScreenGlowAnimator:Hide()
    end

    if TWT_CONFIG.tankMode then
        _G['TWTMainTankModeWindow']:Hide()
    end

    _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)

end

TWT.targetChangedHelper = CreateFrame('Frame')
TWT.targetChangedHelper:Hide()

TWT.targetChangedHelper:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.targetChangedHelper:SetScript("OnHide", function()
    this.startTime = GetTime()
end)
TWT.targetChangedHelper:SetScript("OnUpdate", function()
    local plus = 0.2
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        twtdebug('asking for guid ')
        SendAddonMessage("TWT_GUID", "twt", TWT.channel)
        TWT.targetChangedHelper:Hide()
    end
end)

function TWT.targetChanged(guid, cached)

    if guid == 0 then
        TWT.updateTargetFrameThreatIndicators(-1)
        return
    end

    if _G['TargetFrame']:IsVisible() ~= nil then
        TWT.targetFrameVisible = true
    else
        TWT.targetFrameVisible = false
    end

    if UIParent:GetScale() ~= _G['TWThreatDisplayTarget']:GetScale() then
        _G['TWThreatDisplayTarget']:SetScale(UIParent:GetScale())
    end

    -- no target
    if not UnitExists('target') then
        _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)

        TWT.updateTargetFrameThreatIndicators(-1, 'notarget')
        return false
    end

    -- player check
    if UnitIsPlayer('target') then
        TWT.updateTargetFrameThreatIndicators(-1)
        return
    end

    -- skeram hax
    if not cached then
        if UnitName('target') == 'The Prophet Skeram' and TWT.custom['The Prophet Skeram'] == 0 then
            TWT.custom[UnitName('target')] = guid
            twtdebug('real skeram guid = ' .. guid)
        end

        if UnitName('target') == 'The Prophet Skeram' and TWT.custom['The Prophet Skeram'] ~= 0 then
            if guid == TWT.custom[UnitName('target')] then
                twtdebug('targetting real skeram')
            else
                twtdebug('targetting a clone')
            end
        end
    end

    TWT.target = guid
    if UnitExists('targettarget') then
        TWT.lastTarget = UnitName('targettarget') --tank
    end
    --TWT.lastTarget = guid

    local targetText = TWT.unitNameForTitle(UnitName('target'))

    _G['TWTMainTitle']:SetText(targetText)
    if TWT.threats[TWT.target] then
        if TWT.threats[TWT.target][TWT.name] then
            _G['TWTMainTitle']:SetText(targetText .. ' (' .. TWT.threats[TWT.target][TWT.name].perc .. '%)')
        end
    else
        TWT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    --if not cached then
    --    TWT.raidTargetIconIndex[TWT.target] = GetRaidTargetIndex("target") or 0
    --end

    TWT.updateUI()
end

function TWT.send(msg, guid)
    SendAddonMessage(TWT.prefix, msg, TWT.channel)
    TWT.lastMessageTime[guid] = GetTime()
end

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
    local plus = 0.01
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

function np_test(heal, target)

    local Nameplates = {}

    for _, plate in pairs({ WorldFrame:GetChildren() }) do
        local name = plate:GetName()
        if plate then

            if plate:GetObjectType() == 'Button' then

                for _, region in ipairs({ plate:GetRegions() }) do
                    --twtdebug('found a region')
                    --twtdebug(region:GetObjectType())
                    if region:GetObjectType() == 'FontString' then
                        --twtdebug(region:GetText())
                        --twtdebug(target)

                        if region:GetText() == target then

                            framePoint = plate

                            _G['CombatHeal']:SetText("+" .. heal)

                            _G['CombatHeal']:SetWidth(plate:GetWidth())
                            _G['CombatHeal']:SetPoint("TOPLEFT", plate, "TOPLEFT", 0, 30)

                            nf:Show()

                        else
                            region:SetAlpha(0)
                        end
                    else
                        region:SetAlpha(0)
                    end

                end
            end
        end
    end

end

function TWT.updateUI()

    if TWT_CONFIG.debug then
        _G['pps']:SetText('Traffic: ' .. TWT.round((totalPackets / (GetTime() - timeStart)) * 10) / 10 .. 'packets/s (' .. TWT.round(totalData / (GetTime() - timeStart)) .. ' Bps)')
        _G['pps']:Show()
    else
        _G['pps']:Hide()
    end

    if not TWT.barAnimator:IsVisible() then
        TWT.barAnimator:Show()
    end

    for index in next, TWT.threatsFrames do
        TWT.threatsFrames[index]:Hide()
    end

    if TWT.target == '' then
        --return false
    end

    if TWT.target == '' or UnitIsPlayer('target') then
        local myThreatPercs = {
        }

        for guid, creature in next, TWT.threats do
            myThreatPercs[guid] = creature[TWT.name].perc
        end

        local maxThreatGuid = 0
        local maxThreatPerc = 0
        for guid, perc in myThreatPercs do
            if perc > maxThreatPerc then
                maxThreatPerc = perc
                maxThreatGuid = guid
            end
        end

        TWT.target = maxThreatGuid ~= 0 and maxThreatGuid or ''
    end

    if TWT.target == '' then
        return false
    end

    if UnitExists('target') and not UnitIsDead('target') and UnitName('target')
            and not UnitIsPlayer('target')
            and (UnitClassification('target') == 'WorldBoss' or UnitClassification('target') == 'elite')
            and GetRaidTargetIndex("target")
    then
        if GetRaidTargetIndex("target") then
            TWT.raidTargetIconIndex[TWT.target] = GetRaidTargetIndex("target")
            twtdebug('saved icon ' .. GetRaidTargetIndex("target") .. ' for target ' .. TWT.target)
        end
    end

    local index = 0

    for _, creature in next, TWT.threats do
        for player, data in next, creature do
            if player == TWT.AGRO then
                data.tps = ''
                data.threat = 1
            end
        end
    end

    if not TWT.threats[TWT.target] then
        TWT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    local tankThreat = 0
    local myThreat = 0

    local tankName = ''

    if UnitExists('target') and (UnitIsPlayer('target') or UnitIsDead('target')) then
        tankName = TWT.lastTarget
    else
        if UnitName('targettarget') then
            tankName = UnitName('targettarget')
        else
            -- not tt, target sunned
            tankName = TWT.lastTarget
        end
    end

    TWT.lastTarget = tankName ~= '' and tankName or UnitName('targettargettarget')

    if TWT.threats[TWT.target] then
        if TWT.threats[TWT.target][tankName] then
            if TWT.threats[TWT.target][tankName].threat then
                tankThreat = TWT.threats[TWT.target][tankName].threat
            end
        end
        if TWT.threats[TWT.target][TWT.name] then
            if TWT.threats[TWT.target][TWT.name].threat then
                myThreat = TWT.threats[TWT.target][TWT.name].threat
            end
        end
    end

    if TWT.threats[TWT.target][TWT.name].melee then
        TWT.threats[TWT.target][TWT.AGRO].threat = tankThreat * 1.1
        TWT.threats[TWT.target][TWT.AGRO].perc = 110
    else
        TWT.threats[TWT.target][TWT.AGRO].threat = tankThreat * 1.3
        TWT.threats[TWT.target][TWT.AGRO].perc = 130
    end

    local maxThreat = TWT.threats[TWT.target][TWT.AGRO].threat

    if maxThreat == 0 then
        return false
    end

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats[TWT.target], true) do

        index = index + 1
        if not TWT.threatsFrames[name] then
            TWT.threatsFrames[name] = CreateFrame('Frame', 'TWThreat' .. name, _G["TWThreatListScrollFrameChildren"], 'TWThreat')
        end

        _G['TWThreat' .. name]:SetWidth(TWT.windowWidth - 2)

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
        data.history[math.floor(GetTime())] = data.threat
        data.tps = TWT.calcTPS(name, data)
        _G['TWThreat' .. name .. 'TPS']:SetText(data.tps)

        -- labels
        TWT.setBarLabels(_G['TWThreat' .. name .. 'Perc'], _G['TWThreat' .. name .. 'Threat'], _G['TWThreat' .. name .. 'TPS'])

        -- perc
        _G['TWThreat' .. name .. 'Perc']:SetText(data.perc .. '%')

        if TWT.name ~= tankName and name == TWT.AGRO then
            _G['TWThreat' .. name .. 'Perc']:SetText(100 - TWT.threats[TWT.target][TWT.name].perc .. '%')
        end


        -- name
        _G['TWThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)


        -- bar width and color
        local color = TWT.classColors[data.class]

        if name == TWT.name then

            if TWT_CONFIG.aggroSound and data.perc >= 85 and time() - TWT.lastAggroWarningSoundTime > 5 then
                PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                TWT.lastAggroWarningSoundTime = time()
            end

            if TWT_CONFIG.fullScreenGlow and data.perc >= 85 and time() - TWT.lastAggroWarningGlowTime > 5 then
                TWT.glowFader:Show()
                TWT.lastAggroWarningGlowTime = time()
            end

            _G['TWTMainTitle']:SetText((TWT.guids[TWT.target] and TWT.unitNameForTitle(TWT.guids[TWT.target]) or '') .. ' (' .. data.perc .. '%)')

            --_G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 1)
            _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))

            TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = TWT.round((TWT.windowWidth - 2) * data.perc / 100)

        elseif name == TWT.AGRO then
            TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = nil

            _G['TWThreat' .. name .. 'BG']:SetWidth(TWT.windowWidth - 2)
            _G['TWThreat' .. name .. 'Threat']:SetText('+' .. TWT.formatNumber(maxThreat - myThreat))

            local colorLimit = 50

            if TWT.threats[TWT.target][TWT.name].perc >= 0 and TWT.threats[TWT.target][TWT.name].perc < colorLimit then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(TWT.threats[TWT.target][TWT.name].perc / colorLimit, 1, 0, 0.9)
            elseif TWT.threats[TWT.target][TWT.name].perc >= colorLimit then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 1 - (TWT.threats[TWT.target][TWT.name].perc - colorLimit) / colorLimit, 0, 0.9)
            end

            if tankName == TWT.name then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0, 0, 1)
                _G['TWThreat' .. name .. 'Perc']:SetText('')
            end

        else
            TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = TWT.round((TWT.windowWidth - 2) * data.perc / 100)
            _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))
            _G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
        end

        if name == tankName then
            TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = nil
            _G['TWThreat' .. name .. 'BG']:SetWidth(TWT.windowWidth - 2)
        end

        if name == TWT.name then
            _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0.2, 0.2, 1)
            TWT.updateTargetFrameThreatIndicators(data.perc, TWT.guids[TWT.target])
        end

        TWT.threatsFrames[name]:Show()

    end

    if TWT_CONFIG.tankMode then

        TWT.secondOnThreat = TWT.wipe(TWT.secondOnThreat)

        for guid, creature in next, TWT.threats do
            for name, data in next, creature do
                if name == TWT.name then
                    if data.perc == 100
                            and TWT.tableSize(TWT.secondOnThreat) < 5
                            and GetTime() - data.stamp < 10 then
                        TWT.secondOnThreat[guid] = {
                            name = '',
                            class = '',
                            perc = 0
                        }
                    end
                end
            end
        end

        if TWT.tableSize(TWT.secondOnThreat) > 1 then

            -- find first player bellow me
            for guid, player in next, TWT.secondOnThreat do
                player.name = ''
                player.class = 'priest'
                player.perc = 0
                for name, data in TWT.threats[guid] do
                    if name ~= TWT.name and name ~= TWT.AGRO then
                        if data.perc > player.perc then
                            player.name = name
                            player.class = data.class
                            player.perc = data.perc
                        end
                    end
                end
            end

            _G['TMEF1']:Hide()
            _G['TMEF2']:Hide()
            _G['TMEF3']:Hide()
            _G['TMEF4']:Hide()
            _G['TMEF5']:Hide()
            _G['TWTMainTankModeWindow']:Hide()
            _G['TWTMainTankModeWindow']:SetHeight(0)

            local i = 1
            for guid, player in next, TWT.secondOnThreat do

                if player.name ~= '' then

                    if player.perc ~= 0 then
                        _G['TWTMainTankModeWindow']:SetHeight(i * 25 + 23)
                    end

                    _G['TMEF' .. i .. 'Target']:SetText(TWT.guids[guid])
                    _G['TMEF' .. i .. 'Player']:SetText(TWT.classColors[player.class].c .. player.name)
                    _G['TMEF' .. i .. 'Perc']:SetText(player.perc .. '%')
                    _G['TMEF' .. i .. 'TargetButton']:SetID(guid)
                    _G['TMEF' .. i]:SetPoint("TOPLEFT", _G["TWTMainTankModeWindow"], "TOPLEFT", 0, -21 + 24 - i * 25)

                    _G['TMEF' .. i .. 'RaidTargetIcon']:Hide()

                    if TWT.raidTargetIconIndex[guid] then
                        SetRaidTargetIconTexture(_G['TMEF' .. i .. 'RaidTargetIcon'], TWT.raidTargetIconIndex[guid])
                        _G['TMEF' .. i .. 'RaidTargetIcon']:Show()
                    end

                    if player.perc >= 0 and player.perc < 50 then
                        _G['TMEF' .. i .. 'BG']:SetVertexColor(player.perc / 50, 1, 0, 0.3)
                    else
                        _G['TMEF' .. i .. 'BG']:SetVertexColor(1, 1 - (player.perc - 50) / 50, 0, 0.6)
                    end

                    _G['TMEF' .. i]:Show()

                    i = i + 1

                end
            end

            _G['TWTMainTankModeWindow']:Show()
        else
            _G['TWTMainTankModeWindow']:Hide()
        end
    else
        _G['TWTMainTankModeWindow']:Hide()
    end

    _G['TWThreatListScrollFrame']:UpdateScrollChildRect()

    -- send threat data to others if not sent in last 2 secs
    for guid, data in next, TWT.threats do
        if TWT.lastMessageTime[guid] then
            if GetTime() - TWT.lastMessageTime[guid] > 2 then
                TWT.lastMessageTime[guid] = GetTime()
                if data[TWT.name].threat > 0 then

                    --twtdebtwtdebug('send: ' .. TWT.class .. ':' .. guid .. ':' .. data[TWT.name].threat .. ':' ..
                    --        (data[TWT.name].melee and 1 or 0) .. ':' .. TWT.isTank(guid))
                    TWT.send(TWT.class .. ':' .. guid .. ':' .. data[TWT.name].threat .. ':' ..
                            (data[TWT.name].melee and 1 or 0) .. ':' .. TWT.isTank(guid), guid)
                end
            end
        end
    end

end

TWT.barAnimator = CreateFrame('Frame')
TWT.barAnimator:Hide()
TWT.barAnimator.frames = {}

TWT.barAnimator:SetScript("OnShow", function()
    this.startTime = GetTime()
    TWT.barAnimator.frames = {}
end)
TWT.barAnimator:SetScript("OnUpdate", function()
    for frame, w in TWT.barAnimator.frames do
        local currentW = TWT.round(_G[frame]:GetWidth())
        if currentW ~= w then
            if currentW > w then
                local diff = 5
                if currentW - w < 5 then
                    diff = currentW - w
                end
                _G[frame]:SetWidth(currentW - diff)
            else
                local diff = 5
                if w - currentW < 5 then
                    diff = w - currentW
                end
                _G[frame]:SetWidth(currentW + diff)
            end
        end
    end
    --end
end)

TWT.ui:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.ui:SetScript("OnUpdate", function()
    local plus = 0.5
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
        for i, j in TWT.pairsByKeys(data.history) do
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
            return TWT.round(tps_real / TWT.tableSize(data.history))
        else
            return 0
        end

    end

    return ''
end

TWT.fullScreenGlowAnimator = CreateFrame('Frame')
TWT.fullScreenGlowAnimator:Hide()

TWT.fullScreenGlowAnimator:SetScript("OnShow", function()
    this.startTime = GetTime()
    this.sizeDiff = 100
    this.sizeNow = 0
    this.factor = 1
end)
TWT.fullScreenGlowAnimator:SetScript("OnHide", function()
end)
TWT.fullScreenGlowAnimator:SetScript("OnUpdate", function()
    local plus = 0.02
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if this.sizeNow >= this.sizeDiff then
            this.factor = -1
        end
        if this.sizeNow <= 0 then
            this.factor = 1
        end

        this.sizeNow = this.sizeNow + this.factor * 4

        if TWT_CONFIG.fullScreenGlow then
            _G['TWTFullScreenGlowTexture']:SetWidth(GetScreenWidth() + this.sizeNow)
            _G['TWTFullScreenGlowTexture']:SetHeight(GetScreenHeight() + this.sizeNow)
        end
    end
end)

function TWT.updateTargetFrameThreatIndicators(perc, creature)

    if TWT_CONFIG.fullScreenGlow then
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

    if UnitAffectingCombat('player') and TWT.targetFrameVisible then
        _G['TWThreatDisplayTarget']:Show()
    else
        _G['TWThreatDisplayTarget']:Hide()
    end

end

function TWTMainWindow_Resizing()
    _G['TWTMain']:SetAlpha(0.5)
end

function TWTMainMainWindow_Resized()
    _G['TWTMain']:SetAlpha(1)
end

function TWTChangeSetting_OnClick(checked, code)
    if code == 'lock' then
        checked = not TWT_CONFIG[code]
        if checked then
            _G['TWTMainLockButton']:SetText('u')
        else
            _G['TWTMainLockButton']:SetText('L')
        end
    end
    TWT_CONFIG[code] = checked
    if code == 'tankMode' then
        if checked then
            TWT_CONFIG.fullScreenGlow = false
            TWT_CONFIG.aggroSound = false
            _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
            _G['TWTMainSettingsFullScreenGlow']:Disable()
            _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.fullScreenGlow)
            _G['TWTMainSettingsAggroSound']:Disable()
        else
            _G['TWTMainSettingsFullScreenGlow']:Enable()
            _G['TWTMainSettingsAggroSound']:Enable()
        end
    end
    if code == 'aggroSound' and checked then
        PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
    end

    if code == 'fullScreenGlow' and checked then
        TWT.glowFader:Show()
    end

    TWT.setColumnLabels()

    if TWT_CONFIG.labelRow then
        _G['TWThreatListScrollFrame']:SetPoint('TOPLEFT', 1, -40)
        _G['TWTMainNameLabel']:Show()
    else
        _G['TWThreatListScrollFrame']:SetPoint('TOPLEFT', 1, -20)
        _G['TWTMainNameLabel']:Hide()
        _G['TWTMainTPSLabel']:Hide()
        _G['TWTMainThreatLabel']:Hide()
        _G['TWTMainPercLabel']:Hide()
    end

    TWT.updateUI()
end

function TWT.setColumnLabels()
    _G['TWTMain']:SetWidth(TWT.windowStartWidth - 70 - 70 - 70)

    TWT.nameLimit = 5

    if TWT_CONFIG.colPerc then
        _G['TWTMainPercLabel']:Show()
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + 70)
        TWT.nameLimit = TWT.nameLimit + 8
    else
        _G['TWTMainPercLabel']:Hide()
    end

    if TWT_CONFIG.colThreat then
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + 70)
        TWT.nameLimit = TWT.nameLimit + 8

        if TWT_CONFIG.colPerc then
            _G['TWTMainThreatLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10 - 70 - 5, -21)
        else
            _G['TWTMainThreatLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10, -21)
        end

        _G['TWTMainThreatLabel']:Show()
    else
        _G['TWTMainThreatLabel']:Hide()
    end

    if TWT_CONFIG.colTPS then
        _G['TWTMain']:SetWidth(_G['TWTMain']:GetWidth() + 70)
        TWT.nameLimit = TWT.nameLimit + 8

        if TWT_CONFIG.colThreat then
            if TWT_CONFIG.colPerc then
                _G['TWTMainTPSLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10 - 70 - 70, -21)
            else
                _G['TWTMainTPSLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10 - 70, -21)
            end
        elseif TWT_CONFIG.colPerc then
            _G['TWTMainTPSLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], -10 - 70, -21)
        else
            _G['TWTMainTPSLabel']:SetPoint('TOPRIGHT', _G['TWTMain'], 'TOPRIGHT', -10, -21)
        end

        _G['TWTMainTPSLabel']:Show()
    else
        _G['TWTMainTPSLabel']:Hide()
    end

    if TWT.nameLimit < 17 then
        TWT.nameLimit = 17
    end

    if _G['TWTMain']:GetWidth() < 190 then
        _G['TWTMain']:SetWidth(190)
    end

    TWT.windowWidth = _G['TWTMain']:GetWidth()

    twtdebug('TWT.windowWidth = ' .. TWT.windowWidth)

    _G['TWTMain']:SetMinResize(TWT.windowWidth, 100)
    _G['TWTMain']:SetMaxResize(TWT.windowWidth, 300)
end

function TWT.setBarLabels(perc, threat, tps)

    if TWT_CONFIG.colPerc then
        perc:Show()
    else
        perc:Hide()
    end

    if TWT_CONFIG.colThreat then

        if TWT_CONFIG.colPerc then
            threat:SetPoint('RIGHT', -10 - 70 + 4, 0)
        else
            threat:SetPoint('RIGHT', -10 + 4, 0)
        end

        threat:Show()
    else
        threat:Hide()
    end

    if TWT_CONFIG.colTPS then

        if TWT_CONFIG.colThreat then
            if TWT_CONFIG.colPerc then
                tps:SetPoint('RIGHT', -10 - 70 - 70 + 4, 0)
            else
                tps:SetPoint('RIGHT', -10 - 70 + 4, 0)
            end
        elseif TWT_CONFIG.colPerc then
            tps:SetPoint('RIGHT', -10 - 70 + 4, 0)
        else
            tps:SetPoint('RIGHT', -10 + 4, 0)
        end

        tps:Show()
    else
        tps:Hide()
    end

end

function TWTCloseButton_OnClick()
    _G['TWTMain']:Hide()
    twtprint('Window closed. Type |cff69ccf0/twt show|cffffffff or |cff69ccf0/twtshow|cffffffff to restore it.')
    TWT_CONFIG.visible = false
end

function TWTSettingsToggle_OnClick()
    if _G['TWTMainSettings']:IsVisible() == 1 then
        _G['TWTMainSettings']:Hide()
    else
        _G['TWTMainSettings']:Show()
    end
end

function TWTFontButton_OnClick()
    if _G['TWTMainSettingsFontList']:IsVisible() then
        _G['TWTMainSettingsFontList']:Hide()
    else
        _G['TWTMainSettingsFontList']:Show()
    end
end

function TWTTargetButton_OnClick(guid)

    twtdebug('target button click with guid ' .. guid)

    if TWT.raidTargetIconIndex[guid] then
        if TWT.targetRaidIcon(TWT.raidTargetIconIndex[guid], guid) then
            return true
        end
    else
        twtdebug('no marks, should assist name')
        if UnitExists(TWT.targetFromName(TWT.secondOnThreat[guid].name) .. 'target') then
            if not UnitIsPlayer(TWT.targetFromName(TWT.secondOnThreat[guid].name) .. 'target') then
                twtdebug('no marks, should assist ' .. TWT.secondOnThreat[guid].name)
                AssistByName(TWT.secondOnThreat[guid].name)
                return true
            end
        end
    end
    twtprint("Cannot find target (second on threat is not targeting a creature).")
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
        table.sort(a, function(b, c)
            return b['perc'] > c['perc']
        end)
    else
        table.sort(a, function(b, c)
            return b['perc'] < c['perc']
        end)
    end

    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i]['name'], t[a[i]['name']]
        end
    end
    return iter
end

function TWT.formatNumber(n)

    if n < 0 then
        n = 0
    end

    if n < 999 then
        return TWT.round(n)
    end
    if n < 99999 then
        return TWT.round(n / 10) / 100 .. 'K' or 0
    end
    if n < 999999 then
        return TWT.round(n / 10) / 100 .. 'K' or 0
    end
    return TWT.round(n / 1000) / 1000 .. 'M' or 0
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

function TWT.unitNameForTitle(name)
    if string.len(name) > TWT.nameLimit then
        return string.sub(name, 1, TWT.nameLimit) .. '-'
    end
    return name
end

function TWT.targetRaidIcon(iconIndex, guid)

    for i = 1, GetNumRaidMembers() do
        if TWT.targetRaidSymbolFromUnit("raid" .. i, iconIndex) then
            return true
        end
    end
    for i = 1, GetNumPartyMembers() do
        if TWT.targetRaidSymbolFromUnit("party" .. i, iconIndex) then
            return true
        end
    end
    if TWT.targetRaidSymbolFromUnit("player", iconIndex) then
        return true
    end
    return false
end

function TWT.targetRaidSymbolFromUnit(unit, index)
    if UnitExists(unit) then
        if GetRaidTargetIndex(unit) == index then
            twtdebug('found ! ' .. unit)
            TargetUnit(unit);
            return true
        end
        if UnitExists(unit .. "target") then
            if GetRaidTargetIndex(unit .. "target") == index then
                twtdebug('found ! ' .. unit .. 'target')
                TargetUnit(unit .. "target");
                return true;
            end
        end
    end
    return false
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

function TWT.pairsByKeys(t, f)
    local a = {}
    for n in pairs(t) do
        table.insert(a, n)
    end
    table.sort(a, function(a, b)
        return a < b
    end)
    local i = 0 -- iterator variable
    local iter = function()
        -- iterator function
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], t[a[i]]
        end
    end
    return iter
end

function TWT.round(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function TWT.version(ver)
    return tonumber(string.sub(ver, 1, 1)) * 10 +
            tonumber(string.sub(ver, 3, 3)) * 1
end

function TWT.sendMyVersion()
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "PARTY")
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "GUILD")
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "RAID")
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "BATTLEGROUND")
end
