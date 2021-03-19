local _G, _ = _G or getfenv()

local TWT = CreateFrame("Frame")
TWT.addonVer = '0.0.0.1'

TWT.dev = true

function twprint(a)
    if a == nil then
        DEFAULT_CHAT_FRAME:AddMessage('[TWT]|cff0070de:' .. time() .. '|cffffffff attempt to print a nil value.')
        return false
    end
    DEFAULT_CHAT_FRAME:AddMessage("[TWT] |cffffffff" .. a)
end

TWT.channel = 'TWT'
TWT.name = UnitName('player')
local _, class = UnitClass('player')
TWT.class = string.lower(class)

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

TWT:RegisterEvent("CHAT_MSG_ADDON")
TWT:RegisterEvent("ADDON_LOADED")
TWT:RegisterEvent("PLAYER_REGEN_ENABLED")
TWT:RegisterEvent("PLAYER_TARGET_CHANGED")

TWT.threats = {};
TWT.target = '';

TWT.ui = CreateFrame("Frame")
TWT.ui:Hide()

-- todo clear TWT.threats on combat leave

TWT:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'TWThreat' then
            twprint('addonloaded')
            _G['TWTThreatListScrollFrameScrollBar']:Hide()
            TWTMainMainWindow_Resized()
            TWT.ui:Show()
            _G['TWTMainTitle']:SetText('Momometer v' .. TWT.addonVer)
        end
        if event == 'CHAT_MSG_ADDON' and string.find(arg1, 'TWT:', 1, true) then
            -- todo in raid check
            --twprint(arg1)
            -- server case
            --twprint('arg1 = ' .. arg1) msg:  "TWT:BossName=12345"
            --twprint('arg2 = ' .. arg2) []
            --twprint('arg3 = ' .. arg3) channel RAID
            --twprint('arg4 = ' .. arg4) tank
            local bossEx = string.split(arg1, ':')
            if bossEx[2] then
                local threatEx = string.split(bossEx[2], '=')
                if threatEx[1] and threatEx[2] then
                    TWT.send(TWT.class .. ':' .. threatEx[1] .. ':' .. threatEx[2])
                    --if not TWT.threats[threatEx[1]] then
                    --    TWT.threats[threatEx[1]] = {}
                    --end
                    --if not TWT.threats[threatEx[1]][TWT.name] then
                    --    TWT.threats[threatEx[1]][TWT.name] = {}
                    --end
                    --TWT.threats[threatEx[1]][TWT.name] = {
                    --    class = TWT.class,
                    --    threat = tonumber(threatEx[2]),
                    --    perc = 0,
                    --    tps = 0
                    --}
                end
            end
        end
        if event == 'CHAT_MSG_ADDON' and arg1 == TWT.channel then
            -- todo in raid check
            --twprint(arg2)
            -- normal case, from friends
            -- arg1 prefix TWT
            -- arg2 text   "priest:BossName:1234"
            -- arg3 channel       RAID
            -- arg4 sender  Er
            local ex = string.split(arg2, ':')
            if ex[1] and ex[2] and ex[3] then

                local target = ex[2]
                local player = arg4
                local threat = tonumber(ex[3])

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
                        threat = 1,
                        perc = 100,
                        tps = 0
                    }
                end

                if TWT.threats[target][player]['threat'] then
                    local time = GetTime()
                    --if time >= TWT.threats[target][player]['stamp'] + 3 then
                    --    tps = threat - TWT.threats[target][player]['stampThreat']
                    --    tps = math.floor(tps / 3)
                    --
                    --    TWT.threats[target][player]['tps'] = tps
                    --    TWT.threats[target][player]['stamp'] = time
                    --    TWT.threats[target][player]['stampThreat'] = threat
                    --end
                    -- 100 200 300 400 500



                    table.insert(TWT.threats[target][player]['history'], threat - TWT.threats[target][player].threat)

                    if table.getn(TWT.threats[target][player]['history']) > 5 then
                        table.remove(TWT.threats[target][player]['history'], 1)
                    end

                    TWT.threats[target][player].threat = threat

                    local totalThreat = 0
                    local divider = 0
                    for t, d in TWT.threats[target][player]['history'] do
                        --twprint(t .. ' ' .. d)
                        totalThreat = totalThreat + d
                        if d > 0 then
                            divider = divider + 1
                        end
                    end

                    if totalThreat == 0 then
                        divider = 1
                    end

                    TWT.threats[target][player].tps = math.floor(totalThreat / divider)


                else
                    TWT.threats[target][player] = {
                        class = ex[1],
                        threat = threat,
                        perc = 0,
                        tps = tps,
                        history = { [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0 }
                    }
                end

            end

        end
        if event == "PLAYER_REGEN_ENABLED" then
            --left combat
            TWT.threats = {};
        end
        if event == "PLAYER_TARGET_CHANGED" then
            if not UnitName('target') then
                return false
            end
            if not UnitIsPlayer('target') then
                TWT.target = UnitName('target')
                _G['TWTMainThreatTarget']:SetText('Threat: ' .. TWT.target);
            end
        end

    end
end)

function TWT.send(msg)
    SendAddonMessage(TWT.channel, msg, "RAID")
end

TWT.threats = {};

TWT.AGRO = '-Pull Aggro at-'

if TWT.dev then
    TWT.threats = {
        ['Tham\'Grarr'] = {
            [TWT.AGRO] = {
                class = 'agro',
                threat = 9999,
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
    };

end

TWT.threatsFrames = {}

function TWT.updateUI()

    _G['TWTThreatListScrollFrameScrollBar']:Hide()

    for index in next, TWT.threatsFrames do
        TWT.threatsFrames[index]:Hide()
    end

    local index = 0

    --temp probably
    for boss, data in next, TWT.threats do
        for player, threatData in next, data do

            if player == TWT.AGRO then
                threatData.tps = ''
                threatData.threat = 20
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
    local myThreat = 0
    for name, data in next, TWT.threats[TWT.target] do
        if data.threat > maxThreat then
            maxThreat = data.threat
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
            TWT.threatsFrames[name] = CreateFrame('Frame', 'TWTThreat' .. name, _G["TWTThreatListScrollFrameChildren"], 'TWTThreat')
        end

        TWT.threatsFrames[name]:SetPoint("TOPLEFT", _G["TWTThreatListScrollFrameChildren"], "TOPLEFT", 0, 20 - index * 21)

        data.perc = math.floor((data.threat * 100) / maxThreat)

        local color = TWT.classColors[data.class]
        if name == TWT.name then
            --_G['TWTThreat' .. name .. 'BG']:SetTexture(color.r, color.g, color.b, 0.7);
            --_G['TWTThreat' .. name .. 'BG']:SetTexture(TWT.classColors['agro'].r, TWT.classColors['agro'].g, TWT.classColors['agro'].b,
            --        data.threat / maxThreat - 0.2);
            if data.perc >= 0 and data.perc <= 50 then
                _G['TWTThreat' .. name .. 'BG']:SetTexture(0, 1, 0, 0.5);
            elseif data.perc > 50 and data.perc <= 80 then
                _G['TWTThreat' .. name .. 'BG']:SetTexture(1, 0.5, 0.1, 0.8);
            else
                _G['TWTThreat' .. name .. 'BG']:SetTexture(1, 0.1, 0.1, 0.5);
            end

        else
            _G['TWTThreat' .. name .. 'BG']:SetTexture(color.r, color.g, color.b, 0.3);
        end

        if name == TWT.name then
            _G['TWTThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)
        else
            _G['TWTThreat' .. name .. 'Name']:SetText(TWT.classColors['priest'].c .. name)
        end
        _G['TWTThreat' .. name .. 'TPS']:SetText(data.tps)

        local threatText = data.threat;
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

            _G['TWTThreat' .. name .. 'Threat']:SetText(agroInText)
            --_G['TWTThreat' .. name .. 'Threat']:SetText('+' .. (maxThreat - myThreat))
        else
            _G['TWTThreat' .. name .. 'Threat']:SetText(threatText)
        end

        _G['TWTThreat' .. name .. 'Perc']:SetText(data.perc .. '%')

        _G['TWTThreat' .. name .. 'BG']:SetWidth(298 * data.perc / 100)

        TWT.threatsFrames[name]:Show()

    end

    _G['TWTThreatListScrollFrameScrollBar']:Hide()

    _G['TWTThreatListScrollFrame']:UpdateScrollChildRect()
    _G['TWTThreatListScrollFrameScrollBar']:Hide()

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
        TWT.updateUI()
    end
end)

function TWTMainWindow_Resizing()
    _G['TWTMain']:SetAlpha(0.5)
end

function TWTMainMainWindow_Resized()
    --_G['TWTThreatListScrollFrame']:SetHeight(_G['TWTMain']:GetHeight() - 60)
    --_G['TWTThreatListScrollFrameChildren']:SetHeight(_G['TWTThreatListScrollFrame']:GetHeight())
    --_G['TWTThreatListScrollFrame']:UpdateScrollChildRect()

    _G['TWTMain']:SetAlpha(1)
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
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
