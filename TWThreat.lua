local _G, _ = _G or getfenv()

local TWT = CreateFrame("Frame")
TWT.addonVer = '1.0'
TWT.showedUpdateNotification = false
TWT.addonName = '|cffabd473TW|cff11cc11 |cffcdfe00Threatmeter'

TWT.prefix = 'TWT'
TWT.channel = 'RAID'

TWT.name = UnitName('player')
local _, cl = UnitClass('player')
TWT.class = string.lower(cl)

TWT.raidTargetIconIndex = {}
TWT.lastMessageTime = {}
TWT.lastAggroWarningSoundTime = 0
TWT.lastAggroWarningGlowTime = 0

TWT.AGRO = '-Pull Aggro at-'
TWT.threatsFrames = {}
TWT.tank = {}

TWT.threats = {}
TWT.target = ''
TWT.guids = {}
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
    if not TWT_CONFIG.debug then
        return false
    end
    if a == nil then
        twtprint('|cff0070de[TWTDEBUG:' .. GetTime() .. ']|cffffffff attempt to print a nil value.')
        return
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
        if string.sub(cmd, 1, 6) == 'skeram' then
            if TWT_CONFIG.skeram then
                TWT_CONFIG.skeram = false
                twtprint('Skeram module disabled.')
                return true
            end
            TWT_CONFIG.skeram = true
            twtprint('Skeram module enabled.')
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

        if string.sub(cmd, 1, 3) == 'who' then
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

TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("PLAYER_REGEN_DISABLED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")
TWT:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")
TWT:RegisterEvent("PLAYER_ENTERING_WORLD")
TWT:RegisterEvent("PARTY_MEMBERS_CHANGED")

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
            local _, _, heal = string.find(arg1, "for (%d+)")
            local _, _, target = string.find(arg1, "heals (%a+) for")
            if target and heal then
                --np_test(heal, target)
            end
        end
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            TWT.init()
        end
        if event == "PARTY_MEMBERS_CHANGED" then
            TWT.getClasses()
        end
        if event == "PLAYER_ENTERING_WORLD" then
            TWT.sendMyVersion()
            TWT.combatEnd()
            if UnitAffectingCombat('player') and not TWT.ui:IsVisible() then
                TWT.combatStart()
            end
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
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWTv2:', 1, true) then
            TWT.handleServerMSG2(arg1)
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == TWT.prefix then

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
                return true
            end

            if string.sub(arg2, 1, 7) == 'TWT_WHO' then
                TWT.send('TWT_ME:' .. TWT.addonVer)
                return true
            end

            if string.sub(arg2, 1, 15) == 'TWTRoleTexture:' then
                local tex = string.split(arg2, ':')[2] or ''
                TWT.roles[arg4] = tex
                return true
            end

            if string.sub(arg2, 1, 15) == 'TWTShowTalents:' and arg4 ~= TWT.name then

                local name = string.split(arg2, ':')[2] or ''

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

            if string.sub(arg2, 1, 13) == 'TWTTalentEND;' then
                local talentEx = string.split(arg2, ';')
                local name = talentEx[2]
                if name == TWT.name then
                    _G['TWTTalentFrame']:Show()
                end
                return true
            end

            if string.sub(arg2, 1, 17) == 'TWTTalentTabInfo;' then

                local talentEx = string.split(arg2, ';')

                if talentEx[2] ~= TWT.name then
                    return false
                end

                local index = tonumber(talentEx[3])
                local name = talentEx[4]
                local pointsSpent = tonumber(talentEx[5])
                local numTalents = tonumber(talentEx[6])

                TWT_SPEC[index].name = name
                TWT_SPEC[index].pointsSpent = pointsSpent
                TWT_SPEC[index].numTalents = numTalents

                return true
            end

            if string.sub(arg2, 1, 14) == 'TWTTalentInfo;' and arg4 ~= TWT.name then

                local talentEx = string.split(arg2, ';')

                if talentEx[2] ~= TWT.name then
                    return false
                end

                local tree = tonumber(talentEx[3])
                local i = tonumber(talentEx[4])
                local nameTalent = talentEx[5]
                local tier = tonumber(talentEx[6])
                local column = tonumber(talentEx[7])
                local currRank = tonumber(talentEx[8])
                local maxRank = tonumber(talentEx[9])
                local meetsPrereq = talentEx[10] == '1'

                local ptier = talentEx[11] ~= '-1' and tonumber(talentEx[11]) or nil
                local pcolumn = talentEx[12] ~= '-1' and tonumber(talentEx[12]) or nil
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

            if string.sub(arg2, 1, 7) == 'TWT_ME:' then

                if TWT.addonStatus[arg4] then

                    local msg = string.split(arg2, ':')[2]
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
                else
                    return false
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
                --lost target, dont change TWT.target
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if UnitIsDead('target') then
                --target is dead, dont show anything
                TWT.target = ''
                TWT.updateTargetFrameThreatIndicators(-1)
                return false
            end

            if UnitIsPlayer('target') then
                --show topmost, dont change TWT.target
                TWT.updateTargetFrameThreatIndicators(-1)
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
                        return true
                    end
                end
            end

            TWT.updateTargetFrameThreatIndicators(-1)
            TWT.targetChangedHelper:Show()
        end
    end
end)

TWT.withAddon = 0
TWT.addonStatus = {}

function QueryWho_OnClick()
    TWT.queryWho()
end

function TWT.queryWho()
    TWT.withAddon = 0
    TWT.addonStatus = {}
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, _, _, _, _, _, z = GetRaidRosterInfo(i);
            local _, class = UnitClass('raid' .. i)

            TWT.addonStatus[n] = {
                ['class'] = string.lower(class),
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
        rosterList = rosterList .. TWT.classColors[data['class']].c .. n .. string.rep(' ', 12 - string.len(n)) .. ' ' .. data['v'] .. ' |cff888888'
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
    TWT_CONFIG.lock = TWT_CONFIG.lock or false
    TWT_CONFIG.visible = TWT_CONFIG.visible or false
    TWT_CONFIG.colTPS = TWT_CONFIG.colTPS or false
    TWT_CONFIG.colThreat = TWT_CONFIG.colThreat or false
    TWT_CONFIG.colPerc = TWT_CONFIG.colPerc or false
    TWT_CONFIG.labelRow = TWT_CONFIG.labelRow or false
    TWT_CONFIG.skeram = TWT_CONFIG.skeram or false

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

    _G['TWTMain']:SetHeight(TWT_CONFIG.barHeight * TWT_CONFIG.visibleBars + (TWT_CONFIG.labelRow and 40 or 20))

    _G['TWTMainSettingsFrameHeightSlider']:SetValue(TWT_CONFIG.barHeight) -- calls FrameHeightSlider_OnValueChanged()

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

    _G['TWTMainTitle']:SetText(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer)

    twtprint(TWT.addonName .. ' |cffabd473v' .. TWT.addonVer .. '|cffffffff loaded.')
end

function TWT.addInspectMenu(to)
    local found = 0
    for i, j in UnitPopupMenus[to] do
        if j == "TRADE" then
            found = i
        end
    end
    if found ~= 0 then
        UnitPopupMenus[to][table.getn(UnitPopupMenus[to]) + 1] = UnitPopupMenus[to][table.getn(UnitPopupMenus[to])]
        for i = table.getn(UnitPopupMenus[to]) - 1, found, -1 do
            UnitPopupMenus[to][i] = UnitPopupMenus[to][i - 1]
        end
    end
    UnitPopupMenus[to][found] = "INSPECT_TALENTS"
end

TWT.classes = {}

function TWT.getClasses()
    if TWT.channel == 'RAID' then
        for i = 0, GetNumRaidMembers() do
            if GetRaidRosterInfo(i) then
                local name = GetRaidRosterInfo(i)
                local _, raidCls = UnitClass('raid' .. i)
                TWT.classes[name] = string.lower(raidCls)
            end
        end
    end
    if TWT.channel == 'PARTY' then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName('party' .. i) and UnitClass('party' .. i) then
                    local name = UnitName('party' .. i)
                    local _, raidCls = UnitClass('party' .. i)
                    TWT.classes[name] = string.lower(raidCls)
                end
            end
        end
    end
    twtdebug('classes saved')
end

function TWT.handleServerMSG2(msg)

    totalPackets = totalPackets + 1
    totalData = totalData + string.len(msg)

    local msgEx = string.split(msg, ':')

    -- dead handling
    if msgEx[1] and msgEx[2] and msgEx[3] and not msgEx[4] then
        local guid = tonumber(msgEx[2])
        local dead = msgEx[3] == 'dead'

        if dead then
            for index, target in next, TWT.tankModeTargets do
                if guid == target then
                    TWT.tankModeTargets[index] = nil
                    twtdebug('REMOVED ' .. target .. ' from tank mode targets')
                    return true
                end
            end
        end
        return true
    end

    -- ttts data handling
    if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5]
            and msgEx[6] and msgEx[6] and msgEx[7] and msgEx[8] and msgEx[9] then
        if msgEx[9] == 'TTTS' then
            local guid = tonumber(msgEx[3])
            local player = msgEx[4]
            local perc = tonumber(msgEx[7])

            TWT.tankModeThreats[guid] = {
                name = player,
                class = TWT.classes[player],
                perc = perc
            }
        end
    end
    -- tdts handling
    if msgEx[1] and msgEx[2] and msgEx[3] and msgEx[4] and msgEx[5] and
            msgEx[6] and msgEx[6] and msgEx[7] and msgEx[8] then

        local creature = msgEx[2]
        local guid = tonumber(msgEx[3])
        local player = msgEx[4]
        local tank = msgEx[5] == '1'
        local threat = tonumber(msgEx[6])
        local perc = tonumber(msgEx[7])
        local melee = msgEx[8] == '1'

        if not TWT.threats[guid] then
            TWT.threats[guid] = {}
        end

        if not TWT.threats[guid][TWT.name] then
            TWT.threats[guid][TWT.name] = {
                class = TWT.class,
                threat = 0,
                perc = 1,
                tps = 0,
                history = {},
                tank = false,
                melee = false
            }
        end

        if not TWT.threats[guid][TWT.AGRO] then
            TWT.threats[guid][TWT.AGRO] = {
                class = 'agro',
                threat = 0,
                perc = 100,
                tps = '',
                history = {},
                tank = false,
                melee = false
            }
        end

        if TWT.threats[guid][player] then
            TWT.threats[guid][player].threat = threat
            TWT.threats[guid][player].tank = tank
            TWT.threats[guid][player].perc = perc
            TWT.threats[guid][player].melee = melee

        else
            TWT.threats[guid][player] = {
                class = TWT.classes[player] or 'priest',
                threat = threat,
                perc = 1,
                tps = 0,
                history = {},
                tank = tank,
                melee = melee,
            }
        end

        TWT.guids[guid] = creature

        TWT.calcAGROPerc(guid)

        TWT.updateUI()

    end
end

function TWT.calcAGROPerc(guid)
    ---- max
    local tankThreat = 0
    for name, data in next, TWT.threats[guid] do
        if name ~= TWT.AGRO and data.tank then
            tankThreat = data.threat
        end
    end

    TWT.threats[guid][TWT.AGRO].threat = tankThreat * (TWT.threats[guid][TWT.name].melee and 1.1 or 1.3)
    TWT.threats[guid][TWT.AGRO].perc = TWT.threats[guid][TWT.name].melee and 110 or 130

end

function TWT.combatStart()

    TWT.updateTargetFrameThreatIndicators(-1, '')
    timeStart = GetTime()
    totalPackets = 0
    totalData = 0

    TWT.threats = TWT.wipe(TWT.threats)
    TWT.raidTargetIconIndex = TWT.wipe(TWT.raidTargetIconIndex)
    TWT.guids = TWT.wipe(TWT.guids)

    TWT.tankModeTargets = TWT.wipe(TWT.tankModeTargets)
    TWT.lastMessageTime = TWT.wipe(TWT.lastMessageTime)

    TWT.tank = TWT.wipe(TWT.tank)

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
            texture = string.split(texture, '\\')
            texture = texture[table.getn(texture)]
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

    if TWT.class == 'warrior' and string.lower(sendTex) == 'ability_rogue_eviscerate' then
        sendTex = 'ability_warrior_savageblow' --ms
    end

    TWT.send('TWTRoleTexture:' .. sendTex)

    TWT.getClasses()

    TWT.updateUI()

    TWT.ui:Show()
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

    TWT.ui:Hide()

    if TWT_CONFIG.hideOOC then
        _G['TWTMain']:Hide()
    end

    if TWT_CONFIG.tankMode then
        _G['TWTMainTankModeWindow']:Hide()
    end

    _G['TWTWarning']:Hide()

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
        --twtdebug('asking for guid ')
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

    if TWT_CONFIG.skeram then
        -- skeram hax
        if UnitName('target') == 'The Prophet Skeram' and TWT.custom['The Prophet Skeram'] == 0 then
            TWT.custom[UnitName('target')] = guid
        end
        --
        _G['TWTWarning']:Hide()
        if UnitAffectingCombat('player') then
            if UnitName('target') == 'The Prophet Skeram' and TWT.custom['The Prophet Skeram'] ~= 0 then
                if guid == TWT.custom[UnitName('target')] then
                    _G['TWTWarningText']:SetText("|cff00ff00- REAL -");
                    _G['TWTWarning']:Show()
                else
                    _G['TWTWarningText']:SetText("- CLONE -");
                    _G['TWTWarning']:Show()
                end
            end
        end
    end

    TWT.target = guid

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
    if guid then
        TWT.lastMessageTime[guid] = GetTime()
    end
end

function TWT.UnitDetailedThreatSituation(guid, limit)
    -- reset threat if limit changed
    if TWT.threats[guid] then
        if TWT.tableSize(TWT.threats[guid]) > 0 then
            if limit ~= TWT.tableSize(TWT.threats[guid]) then
                for name, data in next, TWT.threats[guid] do
                    if name ~= TWT.AGRO then
                        data.threat = 0
                    end
                end
            end
        end

    end
    SendAddonMessage("TWT_UDTS", "guid=" .. guid .. "&limit=" .. limit, TWT.channel)
    --twtdebug("UDTS guid=" .. guid)
end

function TWT.TankTargetsThreatSituation(guid)
    SendAddonMessage("TWT_TTTS", "guid=" .. guid, TWT.channel)
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

    if not UnitAffectingCombat('player') and not _G['TWTMainSettings']:IsVisible() then
        TWT.updateTargetFrameThreatIndicators(-1, '')
        return false
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
            --twtdebug('saved icon ' .. GetRaidTargetIndex("target") .. ' for target ' .. TWT.target)
        end
    end

    if not TWT.threats[TWT.target] then
        TWT.updateTargetFrameThreatIndicators(-1)
        return false
    end

    local tankName = ''

    for name, data in TWT.threats[TWT.target] do
        if data.tank then
            tankName = name
            break
        end
    end

    if _G['TWTMainSettings']:IsVisible() and not UnitAffectingCombat('player') then
        tankName = 'BarTestMode'
    end

    local index = 0

    for name, data in TWT.ohShitHereWeSortAgain(TWT.threats[TWT.target], true) do

        if data.threat > 0 and index < TWT_CONFIG.visibleBars then

            index = index + 1
            if not TWT.threatsFrames[name] then
                TWT.threatsFrames[name] = CreateFrame('Frame', 'TWThreat' .. name, _G["TWTMain"], 'TWThreat')
            end

            _G['TWThreat' .. name]:SetWidth(TWT.windowWidth - 2)
            TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = 1

            _G['TWThreat' .. name .. 'Name']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['TWThreat' .. name .. 'TPS']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['TWThreat' .. name .. 'Threat']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")
            _G['TWThreat' .. name .. 'Perc']:SetFont("Interface\\addons\\TWThreat\\fonts\\" .. TWT_CONFIG.font .. ".ttf", 15, "OUTLINE")

            _G['TWThreat' .. name]:SetHeight(TWT_CONFIG.barHeight - 1)
            _G['TWThreat' .. name .. 'BG']:SetHeight(TWT_CONFIG.barHeight - 2)

            TWT.threatsFrames[name]:SetPoint("TOPLEFT", _G["TWTMain"], "TOPLEFT", 0,
                    (TWT_CONFIG.labelRow and -40 or -20) +
                            TWT_CONFIG.barHeight - 1 - index * TWT_CONFIG.barHeight)


            -- icons
            _G['TWThreat' .. name .. 'AGRO']:Hide()
            _G['TWThreat' .. name .. 'Role']:Hide()
            if TWT.roles[name] then
                _G['TWThreat' .. name .. 'Role']:SetTexture('Interface\\Icons\\' .. TWT.roles[name])
                _G['TWThreat' .. name .. 'Role']:SetWidth(TWT_CONFIG.barHeight - 2)
                _G['TWThreat' .. name .. 'Role']:SetHeight(TWT_CONFIG.barHeight - 2)
                _G['TWThreat' .. name .. 'Name']:SetPoint('LEFT', _G['TWThreat' .. name .. 'Role'], 'RIGHT', 1 + (TWT_CONFIG.barHeight / 15), -1)
                _G['TWThreat' .. name .. 'Role']:Show()
            end
            if name == TWT.AGRO then
                _G['TWThreat' .. name .. 'AGRO']:Show()
            end


            -- tps
            data.history[time()] = data.threat
            if UnitAffectingCombat('player') then
                data.tps = TWT.calcTPS(name, data)
            end
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

                if UnitName('target') ~= 'The Prophet Skeram' then
                    if name == string.char(77) .. string.lower(string.char(79, 77, 79)) and data.perc >= 95 then
                        _G['TWTWarningText']:SetText("- STOP DPS " .. string.char(77) .. string.lower(string.char(79, 77, 79)) .. " -");
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

                _G['TWTMainTitle']:SetText((TWT.guids[TWT.target] and TWT.unitNameForTitle(TWT.guids[TWT.target]) or '') .. ' (' .. data.perc .. '%)')

                --_G['TWThreat' .. name .. 'BG']:SetVertexColor(color.r, color.g, color.b, 1)
                _G['TWThreat' .. name .. 'Threat']:SetText(TWT.formatNumber(data.threat))

                TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = TWT.round((TWT.windowWidth - 2) * data.perc / 100)

            elseif name == TWT.AGRO then
                TWT.barAnimator.frames['TWThreat' .. name .. 'BG'] = nil

                _G['TWThreat' .. name .. 'BG']:SetWidth(TWT.windowWidth - 2)
                _G['TWThreat' .. name .. 'Threat']:SetText('+' .. TWT.formatNumber(data.threat - TWT.threats[TWT.target][TWT.name].threat))

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

    end

    _G['TWTMainTankModeWindow']:Hide()

    if TWT_CONFIG.tankMode then

        if TWT.threats[TWT.target] then
            if TWT.threats[TWT.target][TWT.name] then
                if TWT.threats[TWT.target][TWT.name].perc == 100 then
                    local found = false
                    for _, guid in next, TWT.tankModeTargets do
                        if guid == TWT.target then
                            found = true
                            break
                        end
                    end
                    if not found and TWT.tableSize(TWT.tankModeTargets) < 5 then
                        TWT.tankModeTargets[TWT.tableSize(TWT.tankModeTargets) + 1] = TWT.target
                        twtdebug('added ' .. TWT.target .. ' to tank mode targets')
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

        if table.getn(TWT.tankModeTargets) > 1 then

            for i, guid in TWT.tankModeTargets do

                local player = TWT.tankModeThreats[guid]

                if not player then
                    break
                end

                _G['TWTMainTankModeWindow']:SetHeight(i * 25 + 23)

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

                _G['TWTMainTankModeWindow']:Show()

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
            if currentW - w > 150 or w - currentW > 150 then
                _G[frame]:SetWidth(w)
                return true
            end
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
end)

TWT.ui:SetScript("OnShow", function()
    this.startTime = GetTime()
end)
TWT.ui:SetScript("OnUpdate", function()
    local plus = TWT.updateSpeed
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        this.startTime = GetTime()
        if UnitAffectingCombat('player') and UnitAffectingCombat('target') then

            if TWT.target == '' then
                twtdebug('ui onupdate target = blank ')
                return false
            end

            if TWT_CONFIG.tankMode then
                for _, guid in next, TWT.tankModeTargets do
                    --if guid ~= TWT.target then
                    TWT.TankTargetsThreatSituation(guid)
                    --end
                end
            end

            if TWT_CONFIG.glow or TWT_CONFIG.fullScreenGlow or TWT_CONFIG.tankmode or
                    TWT_CONFIG.perc or TWT_CONFIG.visible then
                TWT.UnitDetailedThreatSituation(TWT.target, TWT_CONFIG.visibleBars - 1)
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

        if TWT.tableSize(data.history) > 6 then
            data.history[older] = nil
        end

        local tps = 0
        local mean = 0

        for i = 0, TWT.tableSize(data.history) - 1 do
            local time = time()
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

function TWT.updateTargetFrameThreatIndicators(perc, creature)

    if TWT_CONFIG.fullScreenGlow then
        _G['TWTFullScreenGlow']:Show()
    else
        _G['TWTFullScreenGlow']:Hide()
    end

    if not UnitExists('target') or UnitIsPlayer('target') then
        _G['TWThreatDisplayTarget']:Hide()
        return false
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

    TWT_CONFIG.visibleBars = TWT.round((_G['TWTMain']:GetHeight() - (TWT_CONFIG.labelRow and 40 or 20)) / TWT_CONFIG.barHeight)
    TWT_CONFIG.visibleBars = TWT_CONFIG.visibleBars < 4 and 4 or TWT_CONFIG.visibleBars

    FrameHeightSlider_OnValueChanged()
end

function FrameHeightSlider_OnValueChanged()
    TWT_CONFIG.barHeight = _G['TWTMainSettingsFrameHeightSlider']:GetValue()

    _G['TWTMain']:SetHeight(TWT_CONFIG.barHeight * TWT_CONFIG.visibleBars + (TWT_CONFIG.labelRow and 40 or 20))

    TWT.setMinMaxResize()

    twtdebug(TWT_CONFIG.visibleBars)

    TWT.updateUI()
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
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -40)
        _G['TWTMainNameLabel']:Show()
    else
        _G['TWTMainBarsBG']:SetPoint('TOPLEFT', 1, -20)
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
        TWT.guids[69] = 'Patchwerk TESTMODE'
        TWT.roles['BarTestMode'] = 'ability_warrior_defensivestance'
        TWT.roles['Chad'] = 'spell_holy_auraoflight'
        TWT.roles[TWT.name] = 'ability_hunter_pet_turtle'
        TWT.roles['Olaf'] = 'ability_racial_bearform'
        TWT.roles['Jimmy'] = 'ability_backstab'
        TWT.roles['Miranda'] = 'spell_shadow_shadowwordpain'
        TWT.roles['Karen'] = 'spell_holy_powerinfusion'
        TWT.roles['Felix'] = 'spell_fire_sealoffire'
        TWT.roles['Tom'] = 'spell_shadow_shadowbolt'
        TWT.roles['Bill'] = 'ability_marksmanship'
        TWT.threats[69] = {
            [TWT.AGRO] = {
                class = 'agro', threat = 1100, perc = 110, tps = '',
                history = {}, melee = true, tank = false
            },
            ['BarTestMode'] = {
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
        TWT.target = 69
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

function TWTSettingsToggle_OnClick()
    if _G['TWTMainSettings']:IsVisible() == 1 then
        _G['TWTMainSettings']:Hide()
        TWT.testBars(false)
    else
        _G['TWTMainSettings']:Show()
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

function TWTTargetButton_OnClick(guid)

    if TWT.raidTargetIconIndex[guid] then
        if TWT.targetRaidIcon(TWT.raidTargetIconIndex[guid], guid) then
            return true
        end
    else
        if UnitExists(TWT.targetFromName(TWT.tankModeThreats[guid].name) .. 'target') then
            if not UnitIsPlayer(TWT.targetFromName(TWT.tankModeThreats[guid].name) .. 'target') then
                AssistByName(TWT.tankModeThreats[guid].name)
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
            TargetUnit(unit)
            return true
        end
        if UnitExists(unit .. "target") then
            if GetRaidTargetIndex(unit .. "target") == index then
                TargetUnit(unit .. "target")
                return true
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

TWT.hooks = {}
--https://github.com/shagu/pfUI/blob/master/compat/vanilla.lua#L37
function TWT.hooksecurefunc(name, func, append)
    if not _G[name] then
        return
    end

    TWT.hooks[tostring(func)] = {}
    TWT.hooks[tostring(func)]["old"] = _G[name]
    TWT.hooks[tostring(func)]["new"] = func

    if append then
        TWT.hooks[tostring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[tostring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[tostring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    else
        TWT.hooks[tostring(func)]["function"] = function(a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[tostring(func)]["new"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
            TWT.hooks[tostring(func)]["old"](a1, a2, a3, a4, a5, a6, a7, a8, a9, a10)
        end
    end

    _G[name] = TWT.hooks[tostring(func)]["function"]
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
