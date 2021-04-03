local _G, _ = _G or getfenv()

local TWT = {}

TWT.TALENT_BRANCH_ARRAY = {}

TWT.talentDescriptions = TWTTalentDescriptions

function TWTTalentName(i, j)
    return TWT_SPEC[i][j].name
end

function fixDescriptionLength(d)

    local lineLength = 40

    if string.len(d) <= lineLength then
        return d
    end
    d = TWT.replace(d, '. ', '.')
    d = TWT.replace(d, '.', '.\n')

    return d
end

function TWTTalentDescription(i, j)

    for _, d in TWT.talentDescriptions[TWT_SPEC.class .. TWT_SPEC[i].name] do
        if d.n == TWT_SPEC[i][j].name then
            return fixDescriptionLength(d.d[TWT_SPEC[i][j].rank > 0 and TWT_SPEC[i][j].rank or 1])
        end
    end
    return ''
end

function TWTTalentRank(i, j)
    return 'Rank ' .. TWT_SPEC[i][j].rank .. '/' .. TWT_SPEC[i][j].maxRank
end

function TWT.GetTalentTabInfo(i)
    local name = TWT_SPEC[i].name
    local iconTexture = '' -- TWT_SPEC[i].iconTexture
    local pointsSpent = TWT_SPEC[i].pointsSpent

    local spec = name

    if name == 'Affliction' then
        spec = 'Curses'
    elseif name == 'Demonology' then
        spec = 'Summoning'
    elseif name == 'Feral Combat' then
        spec = 'FeralCombat'
    elseif name == 'Beast Mastery' then
        spec = 'BeastMastery'
    elseif name == 'Retribution' then
        spec = 'Combat'
    elseif name == 'Elemental' then
        spec = 'ElementalCombat'
    end

    local fileName = TWT_SPEC.class .. spec

    return name, iconTexture, pointsSpent, fileName
end

function TWT.GetNumTalents(i)
    local num = TWT_SPEC[i].numTalents
    return num
end

function TWT.GetTalentInfo(i, j)

    local name = TWT_SPEC[i][j].name
    local texture = ''
    for _, d in TWT.talentDescriptions[TWT_SPEC.class .. TWT_SPEC[i].name] do
        if d.n == name then
            texture = d.iconTexture
        end
    end
    local iconTexture = 'Interface\\Icons\\' .. texture --TWT_SPEC[i][j].iconTexture

    local tier = TWT_SPEC[i][j].tier
    local column = TWT_SPEC[i][j].column
    local rank = TWT_SPEC[i][j].rank
    local maxRank = TWT_SPEC[i][j].maxRank
    local meetsPrereq = TWT_SPEC[i][j].meetsPrereq

    return name, iconTexture, tier, column, rank, maxRank, 0, meetsPrereq

end

function TWT.GetTalentPrereqs(i, j)
    local tier = TWT_SPEC[i][j].ptier
    local column = TWT_SPEC[i][j].pcolumn
    local isLearnable = TWT_SPEC[i][j].isLearnable
    return tier, column, isLearnable
end

function TWTTalentFrame_Update()

    -- Setup Tabs
    local tab, name, iconTexture, pointsSpent, button;
    local numTabs = 3;
    for i = 1, MAX_TALENT_TABS do
        tab = _G['TWTTalentFrameTab' .. i]
        if i <= numTabs then
            name, iconTexture, pointsSpent = TWT.GetTalentTabInfo(i)
            if i == PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']) then
                -- If tab is the selected tab set the points spent info
                _G['TWTTalentFrameSpentPoints']:SetText(format(MASTERY_POINTS_SPENT, name) .. " " .. HIGHLIGHT_FONT_COLOR_CODE .. pointsSpent .. FONT_COLOR_CODE_CLOSE);
                _G['TWTTalentFrame'].pointsSpent = pointsSpent;
            end
            tab:SetText(name);
            PanelTemplates_TabResize(10, tab);
            tab:Show();
        else
            tab:Hide();
        end
    end

    PanelTemplates_SetNumTabs(_G['TWTTalentFrame'], numTabs);
    PanelTemplates_UpdateTabs(_G['TWTTalentFrame']);

    -- Setup Frame
    SetPortraitTexture(_G['TWTTalentFramePortrait'], "target");

    local cp = UnitLevel('target') - 9 - TWT_SPEC[1].pointsSpent - TWT_SPEC[2].pointsSpent - TWT_SPEC[3].pointsSpent

    _G['TWTTalentFrameTalentPointsText']:SetText(cp)
    _G['TWTTalentFrame'].talentPoints = cp

    local talentTabName = TWT.GetTalentTabInfo(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']));
    local base;
    local name, texture, points, fileName = TWT.GetTalentTabInfo(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']));
    if talentTabName then
        base = "Interface\\TalentFrame\\" .. fileName .. "-";
    else
        -- temporary default for classes without talents poor guys
        base = "Interface\\TalentFrame\\MageFire-";
    end

    _G['TWTTalentFrameBackgroundTopLeft']:SetTexture(base .. "TopLeft");
    _G['TWTTalentFrameBackgroundTopRight']:SetTexture(base .. "TopRight");
    _G['TWTTalentFrameBackgroundBottomLeft']:SetTexture(base .. "BottomLeft");
    _G['TWTTalentFrameBackgroundBottomRight']:SetTexture(base .. "BottomRight");

    local numTalents = TWT.GetNumTalents(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']));

    if numTalents > MAX_NUM_TALENTS then
        message("Too many talents in talent frame!");
    end

    TWT.TalentFrame_ResetBranches();

    local tier, column, rank, maxRank, isLearnable, meetsPrereq;
    local forceDesaturated, tierUnlocked;
    for i = 1, MAX_NUM_TALENTS do
        button = _G['TWTTalentFrameTalent' .. i];
        if (i <= numTalents) then
            -- Set the button info
            name, iconTexture, tier, column, rank, maxRank, _, meetsPrereq = TWT.GetTalentInfo(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']), i);
            _G['TWTTalentFrameTalent' .. i .. 'Rank']:SetText(rank);
            SetTalentButtonLocation(button, tier, column);
            TWT.TALENT_BRANCH_ARRAY[tier][column].id = button:GetID();

            -- If player has no talent points then show only talents with points in them
            if ((_G['TWTTalentFrame'].talentPoints <= 0 and rank == 0)) then
                forceDesaturated = 1;
            else
                forceDesaturated = nil;
            end

            -- If the player has spent at least 5 talent points in the previous tier
            if (((tier - 1) * 5 <= _G['TWTTalentFrame'].pointsSpent)) then
                tierUnlocked = 1;
            else
                tierUnlocked = nil;
            end

            SetItemButtonTexture(button, iconTexture);

            -- Talent must meet prereqs or the player must have no points to spend
            --if TWT.TalentFrame_SetPrereqs(tier, column, forceDesaturated, tierUnlocked, GetTalentPrereqs(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']), i)) and meetsPrereq then
            --if TWT.TalentFrame_SetPrereqs(tier, column, forceDesaturated, tierUnlocked, GetTalentPrereqs(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']), i)) and meetsPrereq then
            local a1, a2, a3 = TWT.GetTalentPrereqs(PanelTemplates_GetSelectedTab(_G['TWTTalentFrame']), i)
            if TWT.TalentFrame_SetPrereqs(tier, column, forceDesaturated, tierUnlocked, a1, a2, a3) and meetsPrereq then

                SetItemButtonDesaturated(button, nil);

                if (rank < maxRank) then
                    -- Rank is green if not maxed out
                    _G['TWTTalentFrameTalent' .. i .. 'Slot']:SetVertexColor(0.1, 1.0, 0.1);
                    _G['TWTTalentFrameTalent' .. i .. 'Rank']:SetTextColor(GREEN_FONT_COLOR.r, GREEN_FONT_COLOR.g, GREEN_FONT_COLOR.b);
                else
                    _G['TWTTalentFrameTalent' .. i .. 'Slot']:SetVertexColor(1.0, 0.82, 0);
                    _G['TWTTalentFrameTalent' .. i .. 'Rank']:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
                end
                _G['TWTTalentFrameTalent' .. i .. 'RankBorder']:Show()
                _G['TWTTalentFrameTalent' .. i .. 'Rank']:Show()
            else
                SetItemButtonDesaturated(button, 1, 0.65, 0.65, 0.65);
                _G["TWTTalentFrameTalent" .. i .. "Slot"]:SetVertexColor(0.5, 0.5, 0.5);
                if (rank == 0) then
                    _G["TWTTalentFrameTalent" .. i .. "RankBorder"]:Hide();
                    _G["TWTTalentFrameTalent" .. i .. "Rank"]:Hide();
                else
                    _G["TWTTalentFrameTalent" .. i .. "RankBorder"]:SetVertexColor(0.5, 0.5, 0.5);
                    _G["TWTTalentFrameTalent" .. i .. "Rank"]:SetTextColor(GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b);
                end
            end

            button:Show();
        else
            button:Hide();
        end
    end


    -- Draw the prerq branches
    local node;
    local textureIndex = 1;
    local xOffset, yOffset;
    local texCoords;
    -- Variable that decides whether or not to ignore drawing pieces
    local ignoreUp;
    local tempNode;

    _G['TWTTalentFrame'].textureIndex = 1;

    _G['TWTTalentFrame'].arrowIndex = 1;

    for i = 1, MAX_NUM_TALENT_TIERS do
        for j = 1, NUM_TALENT_COLUMNS do

            node = TWT.TALENT_BRANCH_ARRAY[i][j];

            -- Setup offsets
            xOffset = ((j - 1) * 63) + INITIAL_TALENT_OFFSET_X + 2;
            yOffset = -((i - 1) * 63) - INITIAL_TALENT_OFFSET_Y - 2;

            if (node.id) then
                -- Has talent
                if (node.up ~= 0) then
                    if (not ignoreUp) then
                        TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset + TALENT_BUTTON_SIZE);
                    else
                        ignoreUp = nil;
                    end
                end
                if (node.down ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - TALENT_BUTTON_SIZE + 1);
                end
                if (node.left ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset - TALENT_BUTTON_SIZE, yOffset);
                end
                if (node.right ~= 0) then
                    -- See if any connecting branches are gray and if so color them gray
                    tempNode = TWT.TALENT_BRANCH_ARRAY[i][j + 1];
                    if (tempNode.left ~= 0 and tempNode.down < 0) then
                        TWT.TalentFrame_SetBranchTexture(i, j - 1, TALENT_BRANCH_TEXTURECOORDS["right"][tempNode.down], xOffset + TALENT_BUTTON_SIZE, yOffset);
                    else
                        TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + TALENT_BUTTON_SIZE + 1, yOffset);
                    end

                end
                -- Draw arrows
                if (node.rightArrow ~= 0) then
                    TWT.TalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["right"][node.rightArrow], xOffset + TALENT_BUTTON_SIZE / 2 + 5, yOffset);
                end
                if (node.leftArrow ~= 0) then
                    TWT.TalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["left"][node.leftArrow], xOffset - TALENT_BUTTON_SIZE / 2 - 5, yOffset);
                end
                if (node.topArrow ~= 0) then
                    TWT.TalentFrame_SetArrowTexture(i, j, TALENT_ARROW_TEXTURECOORDS["top"][node.topArrow], xOffset, yOffset + TALENT_BUTTON_SIZE / 2 + 5);
                end
            else
                -- Doesn't have a talent
                if (node.up ~= 0 and node.left ~= 0 and node.right ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tup"][node.up], xOffset, yOffset);
                elseif (node.down ~= 0 and node.left ~= 0 and node.right ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["tdown"][node.down], xOffset, yOffset);
                elseif (node.left ~= 0 and node.down ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topright"][node.left], xOffset, yOffset);
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - 32);
                elseif (node.left ~= 0 and node.up ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomright"][node.left], xOffset, yOffset);
                elseif (node.left ~= 0 and node.right ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["right"][node.right], xOffset + TALENT_BUTTON_SIZE, yOffset);
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["left"][node.left], xOffset + 1, yOffset);
                elseif (node.right ~= 0 and node.down ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["topleft"][node.right], xOffset, yOffset);
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - 32);
                elseif (node.right ~= 0 and node.up ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["bottomleft"][node.right], xOffset, yOffset);
                elseif (node.up ~= 0 and node.down ~= 0) then
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["up"][node.up], xOffset, yOffset);
                    TWT.TalentFrame_SetBranchTexture(i, j, TALENT_BRANCH_TEXTURECOORDS["down"][node.down], xOffset, yOffset - 32);
                    ignoreUp = 1;
                end
            end
        end
        _G['TWTTalentFrameScrollFrame']:UpdateScrollChildRect();
    end
    -- Hide any unused branch textures
    for i = _G['TWTTalentFrame'].textureIndex, MAX_NUM_BRANCH_TEXTURES do
        getglobal("TWTTalentFrameBranch" .. i):Hide();
    end
    -- Hide and unused arrowl textures
    for i = _G['TWTTalentFrame'].arrowIndex, MAX_NUM_ARROW_TEXTURES do
        getglobal("TWTTalentFrameArrow" .. i):Hide();
    end
end

function TWTTalentFrame_OnShow()

    PanelTemplates_SetNumTabs(_G['TWTTalentFrame'], 3);
    PanelTemplates_SetTab(_G['TWTTalentFrame'], 1);

    for i = 1, MAX_NUM_TALENT_TIERS do
        TWT.TALENT_BRANCH_ARRAY[i] = {};
        for j = 1, NUM_TALENT_COLUMNS do
            TWT.TALENT_BRANCH_ARRAY[i][j] = { id = nil, up = 0, left = 0, right = 0, down = 0, leftArrow = 0, rightArrow = 0, topArrow = 0 };
        end
    end

    PlaySound("TalentScreenOpen");
    TWTTalentFrame_Update();
    _G['TWTTalentFrameScrollFrame']:UpdateScrollChildRect();
end

function TWTTalentFrame_OnHide()
    PlaySound("TalentScreenClose");
end

function TWT.TalentFrame_ResetBranches()
    for i = 1, MAX_NUM_TALENT_TIERS do
        for j = 1, NUM_TALENT_COLUMNS do
            TWT.TALENT_BRANCH_ARRAY[i][j].id = nil;
            TWT.TALENT_BRANCH_ARRAY[i][j].up = 0;
            TWT.TALENT_BRANCH_ARRAY[i][j].down = 0;
            TWT.TALENT_BRANCH_ARRAY[i][j].left = 0;
            TWT.TALENT_BRANCH_ARRAY[i][j].right = 0;
            TWT.TALENT_BRANCH_ARRAY[i][j].rightArrow = 0;
            TWT.TALENT_BRANCH_ARRAY[i][j].leftArrow = 0;
            TWT.TALENT_BRANCH_ARRAY[i][j].topArrow = 0;
        end
    end
end

function TWT.TalentFrame_GetBranchTexture()
    local branchTexture = getglobal("TWTTalentFrameBranch" .. _G['TWTTalentFrame'].textureIndex);
    _G['TWTTalentFrame'].textureIndex = _G['TWTTalentFrame'].textureIndex + 1;
    if not branchTexture then
        message("Not enough branch textures");
    else
        branchTexture:Show();
        return branchTexture;
    end
end

function TWT.TalentFrame_SetBranchTexture(tier, column, texCoords, xOffset, yOffset)
    local branchTexture = TWT.TalentFrame_GetBranchTexture();
    branchTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
    branchTexture:SetPoint("TOPLEFT", "TWTTalentFrameScrollChildFrame", "TOPLEFT", xOffset, yOffset);
end

function TWT.TalentFrame_GetArrowTexture()
    local arrowTexture = getglobal("TWTTalentFrameArrow" .. _G['TWTTalentFrame'].arrowIndex);
    _G['TWTTalentFrame'].arrowIndex = _G['TWTTalentFrame'].arrowIndex + 1;
    if (not arrowTexture) then
        message("Not enough arrow textures");
    else
        arrowTexture:Show();
        return arrowTexture;
    end
end

function TWT.TalentFrame_SetArrowTexture(tier, column, texCoords, xOffset, yOffset)
    local arrowTexture = TWT.TalentFrame_GetArrowTexture();
    arrowTexture:SetTexCoord(texCoords[1], texCoords[2], texCoords[3], texCoords[4]);
    arrowTexture:SetPoint("TOPLEFT", "TWTTalentFrameArrowFrame", "TOPLEFT", xOffset, yOffset);
end

function TWT.TalentFrame_SetPrereqs(a1, a2, a3, a4, ar1, ar2, ar3)
    local buttonTier = a1
    local buttonColumn = a2
    local forceDesaturated = a3
    local tierUnlocked = a4
    local tier, column, isLearnable;
    local requirementsMet;
    if tierUnlocked and not forceDesaturated then
        requirementsMet = 1;
    else
        requirementsMet = nil;
    end
    --for i = 5, arg.n, 3 do
    if ar1 and ar2 and ar3 then
        tier = ar1
        column = ar2
        isLearnable = ar3
        if not isLearnable or forceDesaturated then
            requirementsMet = nil;
        end
        TWT.TalentFrame_DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet);

    end
    --end
    return requirementsMet;
end

function TWT.TalentFrame_DrawLines(buttonTier, buttonColumn, tier, column, requirementsMet)
    if (requirementsMet) then
        requirementsMet = 1;
    else
        requirementsMet = -1;
    end

    -- Check to see if are in the same column
    if (buttonColumn == column) then
        -- Check for blocking talents
        if ((buttonTier - tier) > 1) then
            -- If more than one tier difference
            for i = tier + 1, buttonTier - 1 do
                if (TWT.TALENT_BRANCH_ARRAY[i][buttonColumn].id) then
                    -- If there's an id, there's a blocker
                    message("Error this layout is blocked vertically " .. TWT.TALENT_BRANCH_ARRAY[buttonTier][i].id);
                    return ;
                end
            end
        end

        -- Draw the lines
        for i = tier, buttonTier - 1 do
            TWT.TALENT_BRANCH_ARRAY[i][buttonColumn].down = requirementsMet;
            if ((i + 1) <= (buttonTier - 1)) then
                TWT.TALENT_BRANCH_ARRAY[i + 1][buttonColumn].up = requirementsMet;
            end
        end

        -- Set the arrow
        TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].topArrow = requirementsMet;
        return ;
    end
    -- Check to see if they're in the same tier
    if (buttonTier == tier) then
        local left = min(buttonColumn, column);
        local right = max(buttonColumn, column);

        -- See if the distance is greater than one space
        if ((right - left) > 1) then
            -- Check for blocking talents
            for i = left + 1, right - 1 do
                if (TWT.TALENT_BRANCH_ARRAY[tier][i].id) then
                    -- If there's an id, there's a blocker
                    message("there's a blocker");
                    return ;
                end
            end
        end
        -- If we get here then we're in the clear
        for i = left, right - 1 do
            TWT.TALENT_BRANCH_ARRAY[tier][i].right = requirementsMet;
            TWT.TALENT_BRANCH_ARRAY[tier][i + 1].left = requirementsMet;
        end
        -- Determine where the arrow goes
        if (buttonColumn < column) then
            TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].rightArrow = requirementsMet;
        else
            TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].leftArrow = requirementsMet;
        end
        return ;
    end
    -- Now we know the prereq is diagonal from us
    local left = min(buttonColumn, column)
    local right = max(buttonColumn, column)
    -- Don't check the location of the current button
    if left == column then
        left = left + 1
    else
        right = right - 1
    end
    -- Check for blocking talents
    local blocked = nil;
    for i = left, right do
        if (TWT.TALENT_BRANCH_ARRAY[tier][i].id) then
            -- If there's an id, there's a blocker
            blocked = 1;
        end
    end
    left = min(buttonColumn, column);
    right = max(buttonColumn, column);
    if (not blocked) then
        TWT.TALENT_BRANCH_ARRAY[tier][buttonColumn].down = requirementsMet;
        TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].up = requirementsMet;

        for i = tier, buttonTier - 1 do
            TWT.TALENT_BRANCH_ARRAY[i][buttonColumn].down = requirementsMet;
            TWT.TALENT_BRANCH_ARRAY[i + 1][buttonColumn].up = requirementsMet;
        end

        for i = left, right - 1 do
            TWT.TALENT_BRANCH_ARRAY[tier][i].right = requirementsMet;
            TWT.TALENT_BRANCH_ARRAY[tier][i + 1].left = requirementsMet;
        end
        -- Place the arrow
        TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].topArrow = requirementsMet;
        return ;
    end
    -- If we're here then we were blocked trying to go vertically first so we have to go over first, then up
    if (left == buttonColumn) then
        left = left + 1;
    else
        right = right - 1;
    end
    -- Check for blocking talents
    for i = left, right do
        if (TWT.TALENT_BRANCH_ARRAY[buttonTier][i].id) then
            -- If there's an id, then throw an error
            message("Error, this layout is undrawable " .. TWT.TALENT_BRANCH_ARRAY[buttonTier][i].id);
            return ;
        end
    end
    -- If we're here we can draw the line
    left = min(buttonColumn, column);
    right = max(buttonColumn, column);
    --TALENT_BRANCH_ARRAY[tier][column].down = requirementsMet;
    --TALENT_BRANCH_ARRAY[buttonTier][column].up = requirementsMet;

    for i = tier, buttonTier - 1 do
        TWT.TALENT_BRANCH_ARRAY[i][column].up = requirementsMet;
        TWT.TALENT_BRANCH_ARRAY[i + 1][column].down = requirementsMet;
    end

    -- Determine where the arrow goes
    if (buttonColumn < column) then
        TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].rightArrow = requirementsMet;
    else
        TWT.TALENT_BRANCH_ARRAY[buttonTier][buttonColumn].leftArrow = requirementsMet;
    end
end

function TWTTalentFrameTab_OnClick()
    PanelTemplates_SetTab(_G['TWTTalentFrame'], this:GetID())
    TWTTalentFrame_Update()
    PlaySound("igCharacterInfoTab");
end

function TWT.replace(text, search, replace)
    if (search == replace) then
        return text;
    end
    local searchedtext = "";
    local textleft = text;
    while (strfind(textleft, search, 1, true)) do
        searchedtext = searchedtext .. strsub(textleft, 1, strfind(textleft, search, 1, true) - 1) .. replace;
        textleft = strsub(textleft, strfind(textleft, search, 1, true) + strlen(search));
    end
    if (strlen(textleft) > 0) then
        searchedtext = searchedtext .. textleft;
    end
    return searchedtext;
end
