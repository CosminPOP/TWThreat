local _G, _ = _G or getfenv()

local __lower = string.lower
local __repeat = string.rep
local __strlen = string.len
local __find = string.find
local __substr = string.sub
local __parseint = tonumber
local __parsestring = tostring
local __getn = table.getn
local __tinsert = table.insert
local __tsort = table.sort
local __pairs = pairs
local __floor = math.floor
local __abs = abs

local TWT = CreateFrame("Frame")

TWT.addonVer = '1.1.0'
TWT.showedUpdateNotification = false
TWT.addonName = '|cffabd473TW|cff11cc11 |cffcdfe00Threatmeter'

TWT.prefix = 'TWT'
TWT.channel = 'RAID'

TWT.name = UnitName('player')
local _, cl = UnitClass('player')
TWT.class = __lower(cl)

TWT.lastAggroWarningSoundTime = 0
TWT.lastAggroWarningGlowTime = 0

TWT.AGRO = '-Pull Aggro at-'
TWT.threatsFrames = {}

TWT.threats = {}

TWT.targetName = ''
TWT.relayTo = {}
TWT.shouldRelay = false
TWT.healerMasterTarget = ''

TWT.updateSpeed = 1

TWT.targetFrameVisible = false

TWT.nameLimit = 30
TWT.windowStartWidth = 300
TWT.windowWidth = 300
TWT.minBars = 5
TWT.maxBars = 11

TWT.roles = {}
TWT.spec = {}

TWT.tankModeTargets = {}
TWT.tankModeThreats = {}

TWT.custom = {
    ['The Prophet Skeram'] = 0
}

TWT.withAddon = 0
TWT.addonStatus = {}

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

TWT.classCoords = {
    ["priest"] = { 0.52, 0.73, 0.27, 0.48 },
    ["mage"] = { 0.23, 0.48, 0.02, 0.23 },
    ["warlock"] = { 0.77, 0.98, 0.27, 0.48 },
    ["rogue"] = { 0.48, 0.73, 0.02, 0.23 },
    ["druid"] = { 0.77, 0.98, 0.02, 0.23 },
    ["hunter"] = { 0.02, 0.23, 0.27, 0.48 },
    ["shaman"] = { 0.27, 0.48, 0.27, 0.48 },
    ["warrior"] = { 0.02, 0.23, 0.02, 0.23 },
    ["paladin"] = { 0.02, 0.23, 0.52, 0.73 },
}

TWT.fonts = {
    'BalooBhaina', 'BigNoodleTitling',
    'Expressway', 'Homespun', 'Hooge', 'LondrinaSolid',
    'Myriad-Pro', 'PT-Sans-Narrow-Bold', 'PT-Sans-Narrow-Regular',
    'Roboto', 'Share', 'ShareBold',
    'Sniglet', 'SquadaOne',
}

TWT.updateSpeeds = {
    ['warrior'] = { 0.7, 0.5, 0.5 },
    ['paladin'] = { 1, 0.5, 0.7 },
    ['hunter'] = { 0.7, 0.7, 0.7 },
    ['rogue'] = { 0.5, 0.5, 0.5 },
    ['priest'] = { 1, 1, 0.6 },
    ['shaman'] = { 0.7, 0.5, 1 },
    ['mage'] = { 1, 0.5, 0.7 },
    ['warlock'] = { 0.8, 1, 0.6 },
    ['druid'] = { 0.8, 0.5, 1 },
}

function twtprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('[TWT]|cff0070de:' .. GetTime() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage(TWT.classColors[TWT.class].c .. "[TWT] |cffffffff" .. a)
end

function twtdebug(a)
    local time = GetTime() + 0.0001
    if not TWT_CONFIG.debug then
        return false
    end
    if a == nil then
        twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff attempt to print a nil value.')
        return
    end
    if type(a) == 'boolean' then
        if a then
            twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff[true]')
        else
            twtprint('|cff0070de[TWTDEBUG:' .. time .. ']|cffffffff[false]')
        end
        return true
    end
    twtprint('|cff0070de[D:' .. time .. ']|cffffffff[' .. a .. ']')
end

SLASH_TWT1 = "/twt"
SlashCmdList["TWT"] = function(cmd)
    if cmd then
        if __substr(cmd, 1, 4) == 'show' then
            _G['TWTMain']:Show()
            TWT_CONFIG.visible = true
            return true
        end
        --if __substr(cmd, 1, 8) == 'tankmode' then
        --    if TWT_CONFIG.tankMode then
        --        twtprint('Tank Mode is already enabled.')
        --        return false
        --    else
        --        TWT_CONFIG.tankMode = true
        --        twtprint('Tank Mode enabled.')
        --    end
        --    return true
        --end
        if __substr(cmd, 1, 6) == 'skeram' then
            if TWT_CONFIG.skeram then
                TWT_CONFIG.skeram = false
                twtprint('Skeram module disabled.')
                return true
            end
            TWT_CONFIG.skeram = true
            twtprint('Skeram module enabled.')
            return true
        end
        if __substr(cmd, 1, 5) == 'debug' then
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

        if __substr(cmd, 1, 3) == 'who' then
            TWT.queryWho()
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

TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")
TWT:RegisterEvent("PLAYER_ENTERING_WORLD")
TWT:RegisterEvent("PARTY_MEMBERS_CHANGED")

TWT.ui = CreateFrame("Frame")
TWT.ui:Hide()

local timeStart = GetTime()
local totalPackets = 0
local totalData = 0

TWT:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            return TWT.init()
        end
        if event == "PARTY_MEMBERS_CHANGED" then
            return TWT.getClasses()
        end
        if event == "PLAYER_ENTERING_WORLD" then
            TWT.sendMyVersion()
            TWT.combatEnd()
            if UnitAffectingCombat('player') and not TWT.ui:IsVisible() then
                TWT.combatStart()
            end
            return true
        end
        if event == 'CHAT_MSG_ADDON' and __find(arg1, 'TWTv3:', 1, true) then
            return TWT.handleServerMSG2(arg1)
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == TWT.prefix then

            if __substr(arg2, 1, 11) == 'TWTRelayV1:' and arg4 == TWT.healerMasterTarget then

                local msgEx = __explode(arg2, ':')

                if msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] and msgEx[6] and msgEx[7] then

                    TWT.targetName = msgEx[2]

                    TWT.handleServerMSG2('TWTv3' ..
                            ':' .. msgEx[3] ..
                            ':' .. msgEx[4] ..
                            ':' .. msgEx[5] ..
                            ':' .. msgEx[6] ..
                            ':' .. msgEx[7])

                end
                return true
            end

            -- healer master target request
            if __substr(arg2, 1, 8) == 'TWT_HMT:' and arg4 ~= TWT.name then
                local hmtEx = __explode(arg2, ':')
                if not hmtEx[2] then
                    return true
                end
                if hmtEx[2] == TWT.name then
                    for _, name in TWT.relayTo do
                        if name == arg4 then
                            twtdebug('relay ' .. name .. ' already exists.')
                            return false
                        end
                    end
                    TWT.relayTo[table.getn(TWT.relayTo) + 1] = arg4
                    twtdebug('added relay: ' .. arg4)
                    TWT.send('TWT_HMT_OK:' .. arg4)

                    TWT.shouldRelay = TWT.checkRelay()

                end
                return true
            end

            -- healer master target request
            if __substr(arg2, 1, 12) == 'TWT_HMT_REM:' and arg4 ~= TWT.name then
                local hmtEx = __explode(arg2, ':')
                if not hmtEx[2] then
                    return true
                end
                if hmtEx[2] == TWT.name then
                    for index, name in TWT.relayTo do
                        if name == arg4 then
                            TWT.relayTo[index] = nil
                            twtdebug('removed relay: ' .. arg4)
                            return false
                        end
                    end
                end
                return true
            end

            -- healer master target respond
            if __substr(arg2, 1, 11) == 'TWT_HMT_OK:' and arg4 ~= TWT.name then
                local hmtEx = __explode(arg2, ':')
                if not hmtEx[2] then
                    return true
                end
                if hmtEx[2] == TWT.name then
                    TWT.healerMasterTarget = arg4

                    local color = TWT.classColors[TWT.getClass(TWT.healerMasterTarget)]

                    _G['TWTMainSettingsHealerMasterTargetButton']:SetText(TWT.healerMasterTarget)
                    _G['TWTMainSettingsHealerMasterTargetButtonNT']:SetVertexColor(color.r, color.g, color.b, 1)

                    twtprint('Healer Master Target set to ' .. color.c .. TWT.healerMasterTarget)
                end
                return true
            end

            if __substr(arg2, 1, 11) == 'TWTVersion:' and arg4 ~= TWT.name then
                if not TWT.showedUpdateNotification then
                    local verEx = __explode(arg2, ':')
                    if TWT.version(verEx[2]) > TWT.version(TWT.addonVer) then
                        twtprint('New version available ' ..
                                TWT.classColors[TWT.class].c .. 'v' .. verEx[2] .. ' |cffffffff(current version ' ..
                                TWT.classColors['paladin'].c .. 'v' .. TWT.addonVer .. '|cffffffff)')
                        twtprint('Update at ' .. TWT.classColors[TWT.class].c .. 'https://github.com/CosminPOP/TWThreat')
                        TWT.showedUpdateNotification = true
                    end
                end
                return true
            end

            if __substr(arg2, 1, 7) == 'TWT_WHO' then
                TWT.send('TWT_ME:' .. TWT.addonVer)
                return true
            end

            if __substr(arg2, 1, 15) == 'TWTRoleTexture:' then
                local tex = __explode(arg2, ':')[2] or ''
                TWT.roles[arg4] = tex
                return true
            end

            if __substr(arg2, 1, 15) == 'TWTShowTalents:' and arg4 ~= TWT.name then

                local name = __explode(arg2, ':')[2] or ''

                if name ~= TWT.name then
                    return false
                end

                for tree = 1, GetNumTalentTabs() do
                    local treeName, iconTexture, pointsSpent = GetTalentTabInfo(tree)
                    local numTalents = GetNumTalents(tree)
                    TWT.send('TWTTalentTabInfo;' .. arg4 .. ';' .. tree .. ';' ..
                            treeName .. ';' .. pointsSpent .. ';' .. numTalents)

                    for i = 1, GetNumTalents(tree) do
                        local nameTalent, _, tier, column, currRank, maxRank, _, meetsPrereq = GetTalentInfo(tree, i)
                        local ptier, pcolumn, isLearnable = GetTalentPrereqs(tree, i);
                        if not ptier then
                            ptier = -1
                        end
                        if not pcolumn then
                            pcolumn = -1
                        end
                        if not isLearnable then
                            isLearnable = -1
                        end
                        TWT.send('TWTTalentInfo;' .. arg4 .. ';' .. tree .. ';' .. i .. ';' ..
                                nameTalent .. ';' .. tier .. ';' .. column .. ';' ..
                                currRank .. ';' .. maxRank .. ';' .. meetsPrereq .. ';' ..
                                ptier .. ';' .. pcolumn .. ';' .. isLearnable)
                    end
                end

                TWT.send('TWTTalentEND;' .. arg4)

                return true
            end

            if __substr(arg2, 1, 13) == 'TWTTalentEND;' then
                local talentEx = __explode(arg2, ';')
                local name = talentEx[2]
                if name == TWT.name then
                    _G['TWTTalentFrame']:Show()
                end
                return true
            end

            if __substr(arg2, 1, 17) == 'TWTTalentTabInfo;' then

                local talentEx = __explode(arg2, ';')

                if talentEx[2] ~= TWT.name then
                    return false
                end

                local index = __parseint(talentEx[3])
                local name = talentEx[4]
                local pointsSpent = __parseint(talentEx[5])
                local numTalents = __parseint(talentEx[6])

                -- todo save twt_spec per sender so it caches from other people's inspects

                TWT_SPEC[index].name = name
                TWT_SPEC[index].pointsSpent = pointsSpent
                TWT_SPEC[index].numTalents = numTalents

                return true
            end

            if __substr(arg2, 1, 14) == 'TWTTalentInfo;' and arg4 ~= TWT.name then

                local talentEx = __explode(arg2, ';')

                if talentEx[2] ~= TWT.name then
                    return false
                end

                local tree = __parseint(talentEx[3])
                local i = __parseint(talentEx[4])
                local nameTalent = talentEx[5]
                local tier = __parseint(talentEx[6])
                local column = __parseint(talentEx[7])
                local currRank = __parseint(talentEx[8])
                local maxRank = __parseint(talentEx[9])
                local meetsPrereq = talentEx[10] == '1'

                local ptier = talentEx[11] ~= '-1' and __parseint(talentEx[11]) or nil
                local pcolumn = talentEx[12] ~= '-1' and __parseint(talentEx[12]) or nil
                local isLearnable = talentEx[13] == '1' and 1 or nil

                if not TWT_SPEC[tree][i] then
                    TWT_SPEC[tree][i] = {}
                end

                TWT_SPEC[tree][i].name = nameTalent
                TWT_SPEC[tree][i].tier = tier
                TWT_SPEC[tree][i].column = column
                TWT_SPEC[tree][i].rank = currRank
                TWT_SPEC[tree][i].maxRank = maxRank
                TWT_SPEC[tree][i].meetsPrereq = meetsPrereq

                TWT_SPEC[tree][i].ptier = ptier
                TWT_SPEC[tree][i].pcolumn = pcolumn
                TWT_SPEC[tree][i].isLearnable = isLearnable

                return true
            end

            if __substr(arg2, 1, 7) == 'TWT_ME:' then

                if TWT.addonStatus[arg4] then

                    local msg = __explode(arg2, ':')[2]
                    local verColor = ""
                    if TWT.version(msg) == TWT.version(TWT.addonVer) then
                        verColor = TWT.classColors['hunter'].c
                    end
                    if TWT.version(msg) < TWT.version(TWT.addonVer) then
                        verColor = '|cffff1111'
                    end
                    if TWT.version(msg) + 1 == TWT.version(TWT.addonVer) then
                        verColor = '|cffff8810'
                    end

                    TWT.addonStatus[arg4]['v'] = '    ' .. verColor .. msg
                    TWT.withAddon = TWT.withAddon + 1

                    TWT.updateWithAddon()

                    return true
                end

                return false
            end

            return false

        end
        if event == "PLAYER_REGEN_DISABLED" then
            return TWT.combatStart()
        end
        if event == "PLAYER_REGEN_ENABLED" then
            return TWT.combatEnd()
        end
        if event == "PLAYER_TARGET_CHANGED" then

            return TWT.targetChanged()

        end
    end
end)

function QueryWho_OnClick()
    TWT.queryWho()
end

function TWT.queryWho()
    TWT.withAddon = 0
    TWT.addonStatus = {}
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            TWT.addonStatus[n] = {
                ['class'] = __lower(class),
                ['v'] = '|cff888888   -   '
            }
            if z == 'Offline' then
                TWT.addonStatus[n]['v'] = '|cffff0000offline'
            end
        end
    end
    twtprint('Sending who query...')
    _G['TWTWithAddonList']:Show()
    TWT.send('TWT_WHO')
end

function TWT.updateWithAddon()

    local rosterList = ''
    local i = 0
    for n, data in next, TWT.addonStatus do
        i = i + 1
        rosterList = rosterList .. TWT.classColors[data['class']].c .. n .. __repeat(' ', 12 - __strlen(n)) .. ' ' .. data['v'] .. ' |cff888888'
        if i < 4 then
            rosterList = rosterList .. '| '
        end
        if i == 4 then
            rosterList = rosterList .. '\n'
            i = 0
        end
    end
    _G['TWTWithAddonListText']:SetText(rosterList)
    _G['TWTWithAddonListTitle']:SetText('Addon Raid Status ' .. TWT.withAddon .. '/' .. GetNumRaidMembers())
end

TWT.glowFader = CreateFrame('Frame')
TWT.glowFader:Hide()

TWT.glowFader:SetScript("OnShow", function()
    this.startTime = GetTime() - 1
    this.dir = 10
    _G['TWTFullScreenGlow']:SetAlpha(0.01)
    _G['TWTFullScreenGlow']:Show()
end)
TWT.glowFader:SetScript("OnHide", function()
    this.startTime = GetTime()
end)
TWT.glowFader:SetScript("OnUpdate", function()
    local plus = 0.04
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()

        if _G['TWTFullScreenGlow']:GetAlpha() >= 0.6 then
            this.dir = -1
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

    TWT_CONFIG.windowScale = TWT_CONFIG.windowScale or 1
    TWT_CONFIG.glow = TWT_CONFIG.glow or false
    TWT_CONFIG.perc = TWT_CONFIG.perc or false
    TWT_CONFIG.showInCombat = TWT_CONFIG.showInCombat or false
    TWT_CONFIG.hideOOC = TWT_CONFIG.hideOOC or false
    TWT_CONFIG.font = TWT_CONFIG.font or 'Roboto'
    TWT_CONFIG.barHeight = TWT_CONFIG.barHeight or 20
    TWT_CONFIG.visibleBars = TWT_CONFIG.visibleBars or TWT.minBars
    TWT_CONFIG.fullScreenGlow = TWT_CONFIG.fullScreenGlow or false
    TWT_CONFIG.aggroSound = TWT_CONFIG.aggroSound or false
    TWT_CONFIG.tankMode = TWT_CONFIG.tankMode or false
    TWT_CONFIG.tankModeStick = TWT_CONFIG.tankModeStick or 'Free' -- Top, Right, Left, Right, Free
    TWT_CONFIG.lock = TWT_CONFIG.lock or false
    TWT_CONFIG.visible = TWT_CONFIG.visible or false
    TWT_CONFIG.colTPS = TWT_CONFIG.colTPS or false
    TWT_CONFIG.colThreat = TWT_CONFIG.colThreat or false
    TWT_CONFIG.colPerc = TWT_CONFIG.colPerc or false
    TWT_CONFIG.labelRow = TWT_CONFIG.labelRow or false
    TWT_CONFIG.skeram = TWT_CONFIG.skeram or false

    TWT_CONFIG.combatAlpha = TWT_CONFIG.combatAlpha or 1
    TWT_CONFIG.oocAlpha = TWT_CONFIG.oocAlpha or 1

    --disabled for now
    TWT_CONFIG.tankMode = false

    TWT_CONFIG.debug = TWT_CONFIG.debug or false

    if TWT_CONFIG.visible then
        _G['TWTMain']:Show()
    else
        _G['TWTMain']:Hide()
    end

    if TWT_CONFIG.tankMode then
        _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
        _G['TWTMainSettingsFullScreenGlow']:Disable()
        _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.fullScreenGlow)
        _G['TWTMainSettingsAggroSound']:Disable()
    end

    if TWT_CONFIG.lock then
        _G['TWTMainLockButton']:SetText('u')
    else
        _G['TWTMainLockButton']:SetText('L')
    end

    _G['TWTFullScreenGlowTexture']:SetWidth(GetScreenWidth())
    _G['TWTFullScreenGlowTexture']:SetHeight(GetScreenHeight())

    _G['TWTMain']:SetHeight(TWT_CONFIG.barHeight * TWT_CONFIG.visibleBars + (TWT_CONFIG.labelRow and 40 or 20))

    _G['TWTMainSettingsFrameHeightSlider']:SetValue(TWT_CONFIG.barHeight) -- calls FrameHeightSlider_OnValueChanged()
    _G['TWTMainSettingsWindowScaleSlider']:SetValue(TWT_CONFIG.windowScale) -- calls FrameHeightSlider_OnValueChanged()

    _G['TWTMainSettingsCombatAlphaSlider']:SetValue(TWT_CONFIG.combatAlpha) -- calls CombatOpacitySlider_OnValueChanged()
    _G['TWTMainSettingsOOCAlphaSlider']:SetValue(TWT_CONFIG.oocAlpha) -- calls OOCombatSlider_OnValueChanged()

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
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -40)
        _G['TWTMainNameLabel']:Show()
    else
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -20)
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
    _G['TWTMainTankModeWindowCloseButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)

    _G['TWTMainTankModeWindowStickTopButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainTankModeWindowStickRightButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainTankModeWindowStickBottomButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)
    _G['TWTMainTankModeWindowStickLeftButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.5)

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

    --UnitPopupButtons["INSPECT_TALENTS"] = { text = 'Inspect Talents', dist = 0 }
    --
    --TWT.addInspectMenu("PARTY")
    --TWT.addInspectMenu("PLAYER")
    --TWT.addInspectMenu("RAID")
    --
    --TWT.hooksecurefunc("UnitPopup_OnClick", function()
    --    local button = this.value
    --    if button == "INSPECT_TALENTS" then
    --
    --        _G['TWTTalentFrame']:Hide()
    --
    --        TWT_SPEC = {
    --            class = UnitClass('target'),
    --            {
    --                name = 'Arms',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 27,
    --                numTalents = 18
    --            },
    --            {
    --                name = 'Fury',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 24,
    --                numTalents = 17
    --            },
    --            {
    --                name = 'Protection',
    --                iconTexture = 'interface\\icons\\ability_warrior_cleave',
    --                pointsSpent = 0,
    --                numTalents = 17
    --            }
    --        }
    --
    --        TWT.send('TWTShowTalents:' .. UnitName('target'))
    --
    --    end
    --end)
    --
    --UIParentLoadAddOn("Blizzard_TalentUI")

    TWT.updateTitleBarText()
    TWT.updateSettingsTabs(1)

    twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff loaded.')
    return true
end

function TWT.updateSettingsTabs(tab)
    local color = TWT.classColors[TWT.class]
    _G['TWTMainSettingsTabsUnderline']:SetVertexColor(color.r, color.g, color.b)

    for i = 1, 3 do
        _G['TWTMainSettingsTab' .. i]:Hide()
        _G['TWTMainSettingsTab' .. i .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['TWTMainSettingsTab' .. i .. 'ButtonHT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['TWTMainSettingsTab' .. i .. 'ButtonPT']:SetVertexColor(color.r, color.g, color.b, 0.4)
        _G['TWTMainSettingsTab' .. i .. 'ButtonText']:SetTextColor(0.4, 0.4, 0.4)
    end

    _G['TWTMainSettingsTab' .. tab .. 'ButtonNT']:SetVertexColor(color.r, color.g, color.b, 1)
    _G['TWTMainSettingsTab' .. tab .. 'ButtonText']:SetTextColor(1, 1, 1)

    _G['TWTMainSettingsTab' .. tab]:Show()

end

function TWTSettingsTab_OnClick(tab)
    TWT.updateSettingsTabs(tab)
end

function TWTHealerMasterTarget_OnClick()

    TWT.getClasses()

    if not UnitExists('target') or not UnitIsPlayer('target')
            or UnitName('target') == TWT.name then

        if TWT.healerMasterTarget == '' then
            twtprint('Please target a tank.')
        else
            TWT.removeHealerMasterTarget()
        end

        return false
    end

    if UnitName('target') == TWT.healerMasterTarget then
        return TWT.removeHealerMasterTarget()
    end

    TWT.send('TWT_HMT:' .. UnitName('target'))

    local color = TWT.classColors[TWT.getClass(UnitName('target'))]

    twtprint('Trying to set Healer Master Target to ' .. color.c .. UnitName('target'))

end

function TWT.removeHealerMasterTarget()
    TWT.send('TWT_HMT_REM:' .. TWT.healerMasterTarget)

    twtprint('Healer Master Target cleared.')

    TWT.healerMasterTarget = ''
    TWT.targetName = ''

    TWT.threats = TWT.wipe(TWT.threats)

    _G['TWTMainSettingsHealerMasterTargetButton']:SetText('From Target')
    _G['TWTMainSettingsHealerMasterTargetButtonNT']:SetVertexColor(1, 1, 1, 1)

    TWT.updateUI()

    return true
end

function TWT.addInspectMenu(to)
    local found = 0
    for i, j in UnitPopupMenus[to] do
        if j == "TRADE" then
            found = i
        end
    end
    if found ~= 0 then
        UnitPopupMenus[to][__getn(UnitPopupMenus[to]) + 1] = UnitPopupMenus[to][__getn(UnitPopupMenus[to])]
        for i = __getn(UnitPopupMenus[to]) - 1, found, -1 do
            UnitPopupMenus[to][i] = UnitPopupMenus[to][i - 1]
        end
    end
    UnitPopupMenus[to][found] = "INSPECT_TALENTS"
end

TWT.classes = {}

function TWT.getClass(name)
    return TWT.classes[name] or 'priest'
end

function TWT.getClasses()
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local name = GetRaidRosterInfo(i)
                local _, raidCls = UnitClass('raid' .. i)
                TWT.classes[name] = __lower(raidCls)
            end
        end
    end
    if TWT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) and UnitClass('party' .. i) then
                    local name = UnitName('party' .. i)
                    local _, raidCls = UnitClass('party' .. i)
                    TWT.classes[name] = __lower(raidCls)
                end
            end
        end
    end
    twtdebug('classes saved')
    return true
end

function TWT.handleServerMSG2(msg)

    --twtdebug(msg)

    totalPackets = totalPackets + 1
    totalData = totalData + __strlen(msg)

    local msgEx = __explode(msg, ':')

    -- udts handling
    if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] and msgEx[6] then

        --local prefix = msgEx[1] -- TWTv3
        local player = msgEx[2]
        local tank = msgEx[3] == '1'
        local threat = __parseint(msgEx[4])
        local perc = __parseint(msgEx[5])
        local melee = msgEx[6] == '1'

        if UnitName('target') and not UnitIsPlayer('target') and TWT.shouldRelay then
            --relay
            for i, name in TWT.relayTo do
                twtdebug('relaying to ' .. i .. ' ' .. name)
            end
            TWT.send('TWTRelayV1' ..
                    ':' .. UnitName('target') ..
                    ':' .. player ..
                    ':' .. msgEx[3] ..
                    ':' .. threat ..
                    ':' .. perc ..
                    ':' .. msgEx[6]);
        end

        local time = time()

        if not TWT.threats[TWT.name] then
            TWT.threats[TWT.name] = {
                class = TWT.class,
                threat = 0,
                perc = 1,
                tps = 0,
                history = {
                    [time] = threat
                },
                tank = false,
                melee = false
            }
        end

        if not TWT.threats[TWT.AGRO] then
            TWT.threats[TWT.AGRO] = {
                class = 'agro',
                threat = 0,
                perc = 100,
                tps = '',
                history = {},
                tank = false,
                melee = false
            }
        end

        if TWT.threats[player] then
            TWT.threats[player].threat = threat
            TWT.threats[player].tank = tank
            TWT.threats[player].perc = perc
            TWT.threats[player].melee = melee
            TWT.threats[player].history[time] = threat
            TWT.threats[player].tps = 0

        else
            TWT.threats[player] = {
                class = TWT.getClass(player),
                threat = threat,
                perc = tank and 100 or 1,
                tps = 0,
                history = {
                    [time] = threat
                },
                tank = tank,
                melee = melee,
            }
        end

        TWT.calcAGROPerc()

        TWT.updateUI()

    end
end

function TWT.calcAGROPerc()

    local tankThreat = 0
    for name, data in next, TWT.threats do
        if name ~= TWT.AGRO and data.tank then
            tankThreat = data.threat
        end
    end

    TWT.threats[TWT.AGRO].threat = tankThreat * (TWT.threats[TWT.name].melee and 1.1 or 1.3)
    if TWT.threats[TWT.AGRO].threat == 0 then
        TWT.threats[TWT.AGRO].threat = 1
    end
    TWT.threats[TWT.AGRO].perc = TWT.threats[TWT.name].melee and 110 or 130

end

function TWT.combatStart()

    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    twtdebug('wipe threats combatstart')
    TWT.threats = TWT.wipe(TWT.threats)

    TWT.shouldRelay = TWT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if TWT_CONFIG.showInCombat then
        _G['TWTMain']:Show()
    end

    TWT.spec = {}
    for t = 1, GetNumTalentTabs() do
        TWT.spec[t] = {
            talents = 0,
            texture = ''
        }
        for i = 1, GetNumTalents(t) do
            local _, _, _, _, currRank = GetTalentInfo(t, i);
            TWT.spec[t].talents = TWT.spec[t].talents + currRank
        end
    end

    local specIndex = 1
    for i = 1, MAX_SKILLLINE_TABS do
        local name, texture = GetSpellTabInfo(i);
        if name and name ~= 'General' and texture and i > 1 then
            TWT.spec[specIndex].name = name
            texture = __explode(texture, '\\')
            texture = texture[__getn(texture)]
            TWT.spec[specIndex].texture = texture
            specIndex = specIndex + 1
        end
    end

    local sendTex = TWT.spec[1].texture
    TWT.updateSpeed = TWT.updateSpeeds[TWT.class][1]
    if TWT.spec[2].talents > TWT.spec[1].talents and TWT.spec[2].talents > TWT.spec[3].talents then
        sendTex = TWT.spec[2].texture
        TWT.updateSpeed = TWT.updateSpeeds[TWT.class][2]
    end
    if TWT.spec[3].talents > TWT.spec[1].talents and TWT.spec[3].talents > TWT.spec[2].talents then
        sendTex = TWT.spec[3].texture
        TWT.updateSpeed = TWT.updateSpeeds[TWT.class][3]
    end

    if TWT.class == 'warrior' and __lower(sendTex) == 'ability_rogue_eviscerate' then
        sendTex = 'ability_warrior_savageblow' --ms
    end

    TWT.send('TWTRoleTexture:' .. sendTex)

    TWT.getClasses()

    TWT.updateUI()

    TWT.ui:Show()
    TWT.barAnimator:Show()

    TWTTankModeWindowChangeStick_OnClick()

    _G['TWTMain']:SetAlpha(TWT_CONFIG.combatAlpha)

    return true
end

function TWT.combatEnd()

    TWT.updateTargetFrameThreatIndicators(-1, '')
    twtdebug('wipe threats combat end')
    TWT.threats = TWT.wipe(TWT.threats)

    twtdebug('time = ' .. (TWT.round(GetTime() - timeStart)) .. 's packets = ' .. totalPackets .. ' ' ..
            totalPackets / (GetTime() - timeStart) .. ' packets/s')

    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    TWT.updateUI()

    TWT.ui:Hide()

    if TWT_CONFIG.hideOOC then
        _G['TWTMain']:Hide()
    end

    if TWT_CONFIG.tankMode then
        _G['TWTMainTankModeWindow']:Hide()
    end

    _G['TWTWarning']:Hide()

    TWT.updateTitleBarText()

    _G['TWTMain']:SetAlpha(TWT_CONFIG.oocAlpha)

    return true

end

function TWT.checkRelay()

    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    if table.getn(TWT.relayTo) == 0 then
        return false
    end

    -- in raid
    if TWT.channel == 'RAID' and GetNumRaidMembers() > 0 then
        for index, name in TWT.relayTo do
            local found = false
            for i = 0, GetNumRaidMembers() do
                if GetRaidRosterInfo(i) and UnitName('raid' .. i) == name then
                    found = true
                end
            end
            if not found then
                TWT.relayTo[index] = nil
                twtdebug(name .. ' removed from relay')
            end
        end
    end
    if TWT.channel == 'PARTY' and GetNumPartyMembers() > 0 then
        for index, name in TWT.relayTo do
            local found = false
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) == name then
                    found = true
                end
            end
            if not found then
                TWT.relayTo[index] = nil
                twtdebug(name .. ' removed from relay')
            end
        end
    end

    if table.getn(TWT.relayTo) == 0 then
        return false
    end

    return true
end

function TWT.targetChanged()

    if TWT.healerMasterTarget ~= '' then
        return true
    end

    TWT.channel = (GetNumRaidMembers() > 0) and 'RAID' or 'PARTY'

    TWT.targetName = ''
    TWT.updateTargetFrameThreatIndicators(-1)

    -- lost target
    if not UnitExists('target') then
        return false
    end

    -- target is dead, dont show anything
    if UnitIsDead('target') then
        return false
    end

    -- dont show anything
    if UnitIsPlayer('target') then
        return false
    end

    -- non interesting target
    if UnitClassification('target') ~= 'worldboss' and UnitClassification('target') ~= 'elite' then
        return false
    end

    -- no raid or party
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        return false
    end

    -- not in combat
    if not not UnitAffectingCombat('player') and not UnitAffectingCombat('target') then
        return false
    end

    twtdebug('wipe target changed')
    TWT.threats = TWT.wipe(TWT.threats)

    if _G['TargetFrame']:IsVisible() ~= nil then
        TWT.targetFrameVisible = true
    else
        TWT.targetFrameVisible = false
    end

    if UIParent:GetScale() ~= _G['TWThreatDisplayTarget']:GetScale() then
        _G['TWThreatDisplayTarget']:SetScale(UIParent:GetScale())
    end

    if TWT_CONFIG.skeram then
        -- skeram hax
        --The Prophet Skeram
        --_G['TWTWarning']:Hide()
        --if UnitAffectingCombat('player') then
        --    if UnitName('target') == 'The Prophet Skeram' and TWT.custom['The Prophet Skeram'] ~= 0 then

        --            _G['TWTWarningText']:SetText("|cff00ff00- REAL -");
        --            _G['TWTWarning']:Show()
        --        else
        --            _G['TWTWarningText']:SetText("- CLONE -");
        --            _G['TWTWarning']:Show()
        --        end
        --    end
        --end
    end

    TWT.targetName = TWT.unitNameForTitle(UnitName('target'))

    TWT.updateTitleBarText(TWT.targetName)

    return true
end

function TWT.send(msg)
    SendAddonMessage(TWT.prefix, msg, TWT.channel)
end

function TWT.UnitDetailedThreatSituation(limit)
    -- reset threat if limit changed
    --if TWT.threats[guid] then
    --    if TWT.tableSize(TWT.threats[guid]) > 0 then
    --        if limit ~= TWT.tableSize(TWT.threats[guid]) then
    --            for name, data in next, TWT.threats[guid] do
    --                if name ~= TWT.AGRO then
    --                    data.threat = 0
    --                end
    --            end
    --        end
    --    end
    --
    --end
    SendAddonMessage("TWT_UDTSv3", "limit=" .. limit, TWT.channel)

end

function TWT.updateUI()

    if TWT_CONFIG.debug then
        _G['pps']:SetText('Traffic: ' .. TWT.round((totalPackets / (GetTime() - timeStart)) * 10) / 10 .. 'packets/s (' .. TWT.round(totalData / (GetTime() - timeStart)) .. ' cps)')
        _G['pps']:Show()
    else
        _G['pps']:Hide()
    end

    if not TWT.barAnimator:IsVisible() then
        TWT.barAnimator:Show()
    end

    for name in next, TWT.threatsFrames do
        TWT.threatsFrames[name]:Hide()
    end

    if not UnitAffectingCombat('player') and not _G['TWTMainSettings']:IsVisible() then
        TWT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    if TWT.targetName == '' then
        return false
    end

    local tankName = ''

    for name, data in TWT.threats do
        if data.tank then
            tankName = name
            break
        end
    end

    if _G['TWTMainSettings']:IsVisible() and not UnitAffectingCombat('player') then
        tankName = 'Tenk'
    end

    local index = 0

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats, true) do

        if data and TWT.threats[TWT.name] and index < TWT_CONFIG.visibleBars then

            index = index + 1
            if not TWT.threatsFrames[name] then
                TWT.threatsFrames[name] = CreateFrame('Frame', 'TWThreat' .. name, _G["TWTMain"], 'TWThreat')
            end

            _G['TWThreat' .. name]:SetAlpha(TWT_CONFIG.combatAlpha)
            _G['TWThreat' .. name]:SetWidth(TWT.windowWidth - 2)

            _G['TWThreat' .. name .. 'Name']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['TWThreat' .. name .. 'TPS']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['TWThreat' .. name .. 'Threat']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['TWThreat' .. name .. 'Perc']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")

            _G['TWThreat' .. name]:SetHeight(TWT_CONFIG.barHeight - 1)
            _G['TWThreat' .. name .. 'BG']:SetHeight(TWT_CONFIG.barHeight - 2)

            TWT.threatsFrames[name]:ClearAllPoints()
            TWT.threatsFrames[name]:SetPoint("TOPLEFT", _G["TWTMain"], "TOPLEFT", 0,
                    (TWT_CONFIG.labelRow and -40 or -20) +
                            TWT_CONFIG.barHeight - 1 - index * TWT_CONFIG.barHeight)


            -- icons
            _G['TWThreat' .. name .. 'AGRO']:Hide()
            _G['TWThreat' .. name .. 'Role']:Show()
            if name ~= TWT.AGRO then

                _G['TWThreat' .. name .. 'Role']:SetWidth(TWT_CONFIG.barHeight - 2)
                _G['TWThreat' .. name .. 'Role']:SetHeight(TWT_CONFIG.barHeight - 2)
                _G['TWThreat' .. name .. 'Name']:SetPoint('LEFT', _G['TWThreat' .. name .. 'Role'], 'RIGHT', 1 + (TWT_CONFIG.barHeight / 15), -1)
                if TWT.roles[name] then
                    _G['TWThreat' .. name .. 'Role']:SetTexture('Interface\\Icons\\' .. TWT.roles[name])
                    _G['TWThreat' .. name .. 'Role']:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    _G['TWThreat' .. name .. 'Role']:Show()
                else
                    _G['TWThreat' .. name .. 'Role']:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes')
                    _G['TWThreat' .. name .. 'Role']:SetTexCoord(unpack(TWT.classCoords[data.class]))
                end

            else
                _G['TWThreat' .. name .. 'AGRO']:Show()
                _G['TWThreat' .. name .. 'Role']:Hide()
            end


            -- tps
            --data.history[time()] = data.threat
            if UnitAffectingCombat('player') then
                data.tps = TWT.calcTPS(name, data)
            end
            _G['TWThreat' .. name .. 'TPS']:SetText(data.tps)

            -- labels
            TWT.setBarLabels(_G['TWThreat' .. name .. 'Perc'], _G['TWThreat' .. name .. 'Threat'], _G['TWThreat' .. name .. 'TPS'])

            -- perc
            _G['TWThreat' .. name .. 'Perc']:SetText(TWT.round(data.perc) .. '%')

            if TWT.name ~= tankName and name == TWT.AGRO then
                _G['TWThreat' .. name .. 'Perc']:SetText(100 - TWT.threats[TWT.name].perc .. '%')
            end

            -- name
            _G['TWThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)

            -- bar width and color
            local color = TWT.classColors[data.class]

            if name == TWT.name then

                if UnitName('target') ~= 'The Prophet Skeram' then
                    if name == string.char(77) .. __lower(string.char(79, 77, 79)) and data.perc >= 95 then
                        _G['TWTWarningText']:SetText("- STOP DPS " .. string.char(77) .. __lower(string.char(79, 77, 79)) .. " -");
                        _G['TWTWarning']:Show()
                    else
                        _G['TWTWarning']:Hide()
                    end
                end

                if TWT_CONFIG.aggroSound and data.perc >= 85 and time() - TWT.lastAggroWarningSoundTime > 5
                        and not TWT_CONFIG.fullScreenGlow then
                    PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                    TWT.lastAggroWarningSoundTime = time()
                end

                if TWT_CONFIG.fullScreenGlow and data.perc >= 85 and time() - TWT.lastAggroWarningGlowTime > 5 then
                    TWT.glowFader:Show()
                    TWT.lastAggroWarningGlowTime = time()
                    if TWT_CONFIG.aggroSound then
                        PlaySoundFile('Interface\\addons\\TWThreat\\sounds\\warn.ogg')
                    end
                end

                TWT.updateTitleBarText(TWT.targetName .. ' (' .. TWT.round(data.perc) .. '%)')

                _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))

                TWT.barAnimator:animateTo(name, data.perc)

            elseif name == TWT.AGRO then

                TWT.barAnimator:animateTo(name, nil)

                _G['TWThreat' .. name .. 'BG']:SetWidth(TWT.windowWidth - 2)
                _G['TWThreat' .. name .. 'Threat']:SetText('+' .. TWT.formatNumber(data.threat - TWT.threats[TWT.name].threat))

                local colorLimit = 50

                if TWT.threats[TWT.name].perc >= 0 and TWT.threats[TWT.name].perc < colorLimit then
                    _G['TWThreat' .. name .. 'BG']:SetVertexColor(TWT.threats[TWT.name].perc / colorLimit, 1, 0, 0.9)
                elseif TWT.threats[TWT.name].perc >= colorLimit then
                    _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 1 - (TWT.threats[TWT.name].perc - colorLimit) / colorLimit, 0, 0.9)
                end

                if tankName == TWT.name then
                    _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0, 0, 1)
                    _G['TWThreat' .. name .. 'Perc']:SetText('')
                end

            else

                TWT.barAnimator:animateTo(name, data.perc)

                _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 0.9)
            end

            if data.tank then

                TWT.barAnimator:animateTo(name, 100, true)

            end

            if name == TWT.name then
                _G['TWThreat' .. name .. 'BG']:SetVertexColor(1, 0.2, 0.2, 1)
                TWT.updateTargetFrameThreatIndicators(data.perc)
            end

            TWT.threatsFrames[name]:Show()

        end

    end

    if TWT_CONFIG.tankMode then

        --if TWT.threats[TWT.target] then
        --    if TWT.threats[TWT.target][TWT.name] then
        --        if TWT.threats[TWT.target][TWT.name].perc == 100 then
        --            local found = false
        --            for _, guid in next, TWT.tankModeTargets do
        --                if guid == TWT.target then
        --                    found = true
        --                    break
        --                end
        --            end
        --            if not found and TWT.tableSize(TWT.tankModeTargets) < 5 then
        --                TWT.tankModeTargets[TWT.tableSize(TWT.tankModeTargets) + 1] = TWT.target
        --                twtdebug('added ' .. TWT.target .. ' to tank mode targets')
        --            end
        --        end
        --    end
        --end
        --
        --_G['TMEF1']:Hide()
        --_G['TMEF2']:Hide()
        --_G['TMEF3']:Hide()
        --_G['TMEF4']:Hide()
        --_G['TMEF5']:Hide()
        --
        --_G['TWTMainTankModeWindow']:SetHeight(0)
        --
        --if table.getn(TWT.tankModeTargets) > 1 then
        --
        --    for i, guid in TWT.tankModeTargets do
        --
        --        local player = TWT.tankModeThreats[guid]
        --
        --        if not player then
        --            break
        --        end
        --
        --        _G['TWTMainTankModeWindow']:SetHeight(i * 25 + 23)
        --
        --        _G['TMEF' .. i .. 'Target']:SetText((guid == TWT.target and TWT.classColors['priest'].c or '|cffaaaaaa') .. TWT.guids[guid])
        --        _G['TMEF' .. i .. 'Player']:SetText(TWT.classColors[player.class].c .. player.name)
        --        _G['TMEF' .. i .. 'Perc']:SetText(player.perc .. '%')
        --        _G['TMEF' .. i .. 'TargetButton']:SetID(guid)
        --        _G['TMEF' .. i]:SetPoint("TOPLEFT", _G["TWTMainTankModeWindow"], "TOPLEFT", 0, -21 + 24 - i * 25)
        --
        --        _G['TMEF' .. i .. 'RaidTargetIcon']:Hide()
        --
        --        if player.perc >= 0 and player.perc < 50 then
        --            _G['TMEF' .. i .. 'BG']:SetVertexColor(player.perc / 50, 1, 0, guid == TWT.target and 0.9 or 0.3)
        --        else
        --            _G['TMEF' .. i .. 'BG']:SetVertexColor(1, 1 - (player.perc - 50) / 50, 0, guid == TWT.target and 0.9 or 0.3)
        --        end
        --
        --        _G['TMEF' .. i]:Show()
        --
        --        _G['TWTMainTankModeWindow']:Show()
        --
        --    end
        --
        --else
        --    _G['TWTMainTankModeWindow']:Hide()
        --end
    else
        _G['TWTMainTankModeWindow']:Hide()
    end

end

TWT.barAnimator = CreateFrame('Frame')
TWT.barAnimator:Hide()
TWT.barAnimator.frames = {}

function TWT.barAnimator:animateTo(name, perc, instant)

    if perc == nil then
        TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = perc
        return false
    end

    perc = TWT.round(perc)
    perc = perc > 100 and 100 or perc

    local width = TWT.round((TWT.windowWidth - 2) * perc / 100)
    if instant then
        _G['TWThreat' .. name .. 'BG']:SetWidth(width)
        return true
    end
    TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = width
end

TWT.barAnimator:SetScript("OnShow", function()
    this.startTime = GetTime()
    TWT.barAnimator.frames = {}
end)
TWT.barAnimator:SetScript("OnUpdate", function()
    local currentW, step, diff
    for frame, w in TWT.barAnimator.frames do
        currentW = TWT.round(_G[frame]:GetWidth())

        diff = currentW - w

        step = __abs(diff) / (__floor(GetFramerate()) / 30)

        if diff ~= 0 then
            -- grow
            if diff < 0 then
                if __abs(diff) < step then
                    step = __abs(diff)
                end
                _G[frame]:SetWidth(currentW + step)
            else
                if diff < step then
                    step = diff
                end
                _G[frame]:SetWidth(currentW - step)
            end
        end
    end
end)

TWT.ui:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.ui:SetScript("OnHide", function()
    for name in next, TWT.threatsFrames do
        TWT.threatsFrames[name]:Hide()
    end
end)
TWT.ui:SetScript("OnUpdate", function()
    local plus = TWT.updateSpeed
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
            return false
        end
        if UnitAffectingCombat('player') and UnitAffectingCombat('target') then

            if TWT.targetName == '' then
                twtdebug('ui onupdate target = blank ')
                return false
            end

            if TWT_CONFIG.glow or TWT_CONFIG.fullScreenGlow or TWT_CONFIG.tankmode or
                    TWT_CONFIG.perc or TWT_CONFIG.visible then

                if TWT.healerMasterTarget == '' then
                    TWT.UnitDetailedThreatSituation(TWT_CONFIG.visibleBars - 1)
                end
            else
                twtdebug('not asking threat situation')
            end

        end
    end
end)

function TWT.calcTPS(name, data)

    if name ~= TWT.AGRO then

        local older = time()
        for i in TWT.pairsByKeys(data.history) do
            if i < older then
                older = i
            end
        end

        if TWT.tableSize(data.history) > 10 then
            data.history[older] = nil
        end

        local tps = 0
        local mean = 0

        local time = time()
        for i = 0, TWT.tableSize(data.history) - 1 do
            if data.history[time - i] and data.history[time - i - 1] then
                tps = tps + data.history[time - i] - data.history[time - i - 1]
                mean = mean + 1
            end
        end

        if mean > 0 and tps > 0 then
            return TWT.round(tps / mean)
        end

        return 0
    end

    return ''
end

function TWT.updateTargetFrameThreatIndicators(perc)

    if TWT_CONFIG.fullScreenGlow then
        _G['TWTFullScreenGlow']:Show()
    else
        _G['TWTFullScreenGlow']:Hide()
    end

    if perc == -1 then
        TWT.updateTitleBarText()
        _G['TWThreatDisplayTarget']:Hide()

        for name in next, TWT.threatsFrames do
            TWT.threatsFrames[name]:Hide()
        end

        return false
    end

    if not TWT_CONFIG.glow and not TWT_CONFIG.perc then
        _G['TWThreatDisplayTarget']:Hide()
        return false
    end

    _G['TWThreatDisplayTarget']:Show()

    perc = TWT.round(perc)

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
    _G['TWTMain']:SetAlpha(0.4)
end

function TWTMainMainWindow_Resized()
    _G['TWTMain']:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)

    TWT_CONFIG.visibleBars = TWT.round((_G['TWTMain']:GetHeight() - (TWT_CONFIG.labelRow and 40 or 20)) / TWT_CONFIG.barHeight)
    TWT_CONFIG.visibleBars = TWT_CONFIG.visibleBars < 4 and 4 or TWT_CONFIG.visibleBars

    FrameHeightSlider_OnValueChanged()
end

function FrameHeightSlider_OnValueChanged()
    TWT_CONFIG.barHeight = _G['TWTMainSettingsFrameHeightSlider']:GetValue()

    _G['TWTMain']:SetHeight(TWT_CONFIG.barHeight * TWT_CONFIG.visibleBars + (TWT_CONFIG.labelRow and 40 or 20))

    TWT.setMinMaxResize()
    TWT.updateUI()
end

function WindowScaleSlider_OnValueChanged()
    TWT_CONFIG.windowScale = _G['TWTMainSettingsWindowScaleSlider']:GetValue()

    local x, y = _G['TWTMain']:GetLeft(), _G['TWTMain']:GetTop()
    local s = _G['TWTMain']:GetEffectiveScale()
    local posX, posY

    if x and y and s then
        x, y = x * s, y * s
        posX = x
        posY = y
    end

    _G['TWTMain']:SetScale(TWT_CONFIG.windowScale)

    s = _G['TWTMain']:GetEffectiveScale()
    posX, posY = posX / s, posY / s
    _G['TWTMain']:ClearAllPoints()
    _G['TWTMain']:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", posX, posY)
end

function CombatOpacitySlider_OnValueChanged()
    TWT_CONFIG.combatAlpha = _G['TWTMainSettingsCombatAlphaSlider']:GetValue()
    _G['TWTMain']:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)
end

function OOCombatSlider_OnValueChanged()
    TWT_CONFIG.oocAlpha = _G['TWTMainSettingsOOCAlphaSlider']:GetValue()
    _G['TWTMain']:SetAlpha(UnitAffectingCombat('player') and TWT_CONFIG.combatAlpha or TWT_CONFIG.oocAlpha)
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
            TWT.testBars(true)
            TWT_CONFIG.fullScreenGlow = false
            TWT_CONFIG.aggroSound = false
            _G['TWTMainSettingsFullScreenGlow']:SetChecked(TWT_CONFIG.fullScreenGlow)
            _G['TWTMainSettingsFullScreenGlow']:Disable()
            _G['TWTMainSettingsAggroSound']:SetChecked(TWT_CONFIG.fullScreenGlow)
            _G['TWTMainSettingsAggroSound']:Disable()

            _G['TWTMainTankModeWindowStickTopButton']:Show()
            _G['TWTMainTankModeWindowStickRightButton']:Show()
            _G['TWTMainTankModeWindowStickBottomButton']:Show()
            _G['TWTMainTankModeWindowStickLeftButton']:Show()

            _G['TWTMainTankModeWindow']:Show()
        else
            _G['TWTMainSettingsFullScreenGlow']:Enable()
            _G['TWTMainSettingsAggroSound']:Enable()
            _G['TWTMainTankModeWindow']:Hide()
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
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -40)
        _G['TWTMainNameLabel']:Show()
    else
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -20)
        _G['TWTMainNameLabel']:Hide()
        _G['TWTMainTPSLabel']:Hide()
        _G['TWTMainThreatLabel']:Hide()
        _G['TWTMainPercLabel']:Hide()
    end

    FrameHeightSlider_OnValueChanged()

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

    if TWT.nameLimit < 14 then
        TWT.nameLimit = 14
    end

    if _G['TWTMain']:GetWidth() < 190 then
        _G['TWTMain']:SetWidth(190)
    end

    TWT.windowWidth = _G['TWTMain']:GetWidth()

    TWT.setMinMaxResize()
end

function TWT.setMinMaxResize()
    _G['TWTMain']:SetMinResize(TWT.windowWidth, TWT_CONFIG.barHeight * TWT.minBars + (TWT_CONFIG.labelRow and 40 or 20))
    _G['TWTMain']:SetMaxResize(TWT.windowWidth, TWT_CONFIG.barHeight * TWT.maxBars + (TWT_CONFIG.labelRow and 40 or 20))
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

function TWT.testBars(show)

    if UnitAffectingCombat('player') then
        return false
    end

    if show then
        TWT.roles['Tenk'] = 'ability_warrior_defensivestance'
        TWT.roles['Chad'] = 'spell_holy_auraoflight'
        TWT.roles[TWT.name] = 'ability_hunter_pet_turtle'
        TWT.roles['Olaf'] = 'ability_racial_bearform'
        TWT.roles['Jimmy'] = 'ability_backstab'
        TWT.roles['Miranda'] = 'spell_shadow_shadowwordpain'
        TWT.roles['Karen'] = 'spell_holy_powerinfusion'
        TWT.roles['Felix'] = 'spell_fire_sealoffire'
        TWT.roles['Tom'] = 'spell_shadow_shadowbolt'
        TWT.roles['Bill'] = 'ability_marksmanship'
        TWT.threats = {
            [TWT.AGRO] = {
                class = 'agro', threat = 1100, perc = 110, tps = '',
                history = {}, melee = true, tank = false
            },
            ['Tenk'] = {
                class = 'warrior', threat = 1000, perc = 100, tps = 100,
                history = {}, melee = true, tank = true },
            ['Chad'] = {
                class = 'paladin', threat = 990, perc = 99, tps = 99,
                history = {}, melee = true, tank = false },
            [TWT.name] = {
                class = TWT.class, threat = 750, perc = 75, tps = 75,
                history = {}, melee = false, tank = false
            },
            ['Olaf'] = {
                class = 'druid', threat = 700, perc = 70, tps = 70,
                history = {}, melee = true, tank = false
            },
            ['Jimmy'] = {
                class = 'rogue', threat = 500, perc = 50, tps = 50,
                history = {}, melee = true, tank = false
            },
            ['Miranda'] = {
                class = 'priest', threat = 450, perc = 45, tps = 45,
                history = {}, melee = false, tank = false
            },
            ['Karen'] = {
                class = 'priest', threat = 400, perc = 40, tps = 40,
                history = {}, melee = true, tank = false
            },
            ['Felix'] = {
                class = 'mage', threat = 350, perc = 35, tps = 35,
                history = {}, melee = false, tank = false
            },
            ['Tom'] = {
                class = 'warlock', threat = 250, perc = 25, tps = 25,
                history = {}, melee = false, tank = false
            },
            ['Bill'] = {
                class = 'hunter', threat = 100, perc = 10, tps = 10,
                history = {}, melee = false, tank = false
            }
        }
        TWT.targetName = "Patchwerk TEST"

        TWT.updateUI()
    else
        TWT.combatEnd()
    end
end
function TWTCloseButton_OnClick()
    _G['TWTMain']:Hide()
    twtprint('Window closed. Type |cff69ccf0/twt show|cffffffff or |cff69ccf0/twtshow|cffffffff to restore it.')
    TWT_CONFIG.visible = false
end

function TWTTankModeWindowCloseButton_OnClick()
    twtprint('Tank Mode disabled. Type |cff69ccf0/twt tankmode|cffffffff to enable it or go into settings.')
    TWTChangeSetting_OnClick(false, 'tankMode')
    _G['TWTMainSettingsTankMode']:SetChecked(false)
end

function TWTTankModeWindowChangeStick_OnClick(to)
    if to then
        TWT_CONFIG.tankModeStick = to
    end
    if TWT_CONFIG.tankModeStick == 'Top' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('BOTTOMLEFT', _G['TWTMain'], 'TOPLEFT', 0, 1)
    elseif TWT_CONFIG.tankModeStick == 'Right' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('TOPLEFT', _G['TWTMain'], 'TOPRIGHT', 1, 0)
    elseif TWT_CONFIG.tankModeStick == 'Bottom' then
        twtdebug('set')
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('TOPLEFT', _G['TWTMain'], 'BOTTOMLEFT', 0, -1)
    elseif TWT_CONFIG.tankModeStick == 'Left' then
        _G['TWTMainTankModeWindow']:ClearAllPoints()
        _G['TWTMainTankModeWindow']:SetPoint('TOPRIGHT', _G['TWTMain'], 'TOPLEFT', -1, 0)
    end
end

function TWTSettingsToggle_OnClick()
    if _G['TWTMainSettings']:IsVisible() == 1 then
        _G['TWTMainSettings']:Hide()
        TWT.testBars(false)

        _G['TWTMainTankModeWindowStickTopButton']:Hide()
        _G['TWTMainTankModeWindowStickRightButton']:Hide()
        _G['TWTMainTankModeWindowStickBottomButton']:Hide()
        _G['TWTMainTankModeWindowStickLeftButton']:Hide()

    else
        _G['TWTMainSettings']:Show()

        if TWT_CONFIG.tankMode then
            TWTTankModeWindowChangeStick_OnClick()
            _G['TWTMainTankModeWindowStickTopButton']:Show()
            _G['TWTMainTankModeWindowStickRightButton']:Show()
            _G['TWTMainTankModeWindowStickBottomButton']:Show()
            _G['TWTMainTankModeWindowStickLeftButton']:Show()
        end

        TWT.testBars(true)
    end
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

function TWTTargetButton_OnClick()
    --
end

function __explode(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = __find(str, delimiter, from, 1, true)
    while delim_from do
        __tinsert(result, __substr(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = __find(str, delimiter, from, true)
    end
    __tinsert(result, __substr(str, from))
    return result
end

function TWT.ohShitHereWeSortAgain(t, reverse)
    local a = {}
    for n, l in __pairs(t) do
        __tinsert(a, { ['threat'] = l.threat, ['perc'] = l.perc, ['tps'] = l.tps, ['name'] = n })
    end
    if reverse then
        __tsort(a, function(b, c)
            return b['perc'] > c['perc']
        end)
    else
        __tsort(a, function(b, c)
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
    if __strlen(name) > TWT.nameLimit then
        return __substr(name, 1, TWT.nameLimit) .. '-'
    end
    return name
end

function TWT.targetRaidIcon(iconIndex)

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

function TWT.updateTitleBarText(text)
    if not text then
        _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)
        return true
    end
    _G['TWTMainTitle']:SetText(text)
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
    for k in __pairs(src) do
        src[k] = nil
    end
    return src
end

TWT.hooks = {}
--https://github.com/shagu/pfUI/blob/master/compat/vanilla.lua#L37
function TWT.hooksecurefunc(name, func, append)
    if not _G[name] then
        return
    end

    TWT.hooks[__parsestring(func)] = {}
    TWT.hooks[__parsestring(func)]["old"] = _G[name]
    TWT.hooks[__parsestring(func)]["new"] = func

    if append then
        TWT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        TWT.hooks[__parsestring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[__parsestring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    end

    _G[name] = TWT.hooks[__parsestring(func)]["function"]
end

function TWT.pairsByKeys(t, f)
    local a = {}
    for n in __pairs(t) do
        __tinsert(a, n)
    end
    __tsort(a, function(a, b)
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
    return __floor(num * mult + 0.5) / mult
end

function TWT.version(ver)
    local verEx = __explode(ver, '.')

    if verEx[3] then
        -- new versioning with 3 numbers
        return __parseint(verEx[1]) * 100 +
                __parseint(verEx[2]) * 10 +
                __parseint(verEx[3]) * 1
    end

    -- old versioning
    return __parseint(verEx[1]) * 10 +
            __parseint(verEx[2]) * 1

end

function TWT.sendMyVersion()
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "PARTY")
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "GUILD")
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "RAID")
    SendAddonMessage(TWT.prefix, "TWTVersion:" .. TWT.addonVer, "BATTLEGROUND")
end
