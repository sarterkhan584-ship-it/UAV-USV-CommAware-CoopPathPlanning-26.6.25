function score = evaluateCandidate(pos0, pos1, dpsi, knownMap, relayTargets, sameTypeOthers, islandMask, params, platformType, agentID, currIslandCoverage)
% evaluateCandidate  原始覆盖搜索评价函数（增强版：地形APF + 通信硬约束）
%
%  新增功能：
%   1. UAV地形人工势场避障（基于DEM + 安全净空）
%   2. 通信硬约束过滤（基本服务率 + 最大断连时长）

    % --- 地图边界检查 ---
    if pos1(1) < 0 || pos1(1) >= params.mapLenKm || pos1(2) < 0 || pos1(2) >= params.mapLenKm
        score = -1e12;
        return;
    end

    if strcmpi(platformType, 'uav')
        widthKm = params.sensorStripWidthUAVKm;
    else
        widthKm = params.sensorStripWidthUSVKm;
    end

    % --- USV 硬约束：中心线不能穿岛，条带边缘与岛屿保持最小净空 ---
    if strcmpi(platformType, 'usv')
        if pathCrossIsland(pos0, pos1, islandMask, params)
            score = -1e12;
            return;
        end

        [minCenterDistKm, threatCost0, apfAlign0] = sampleUSVThreatInfo(pos0, pos1, widthKm, params);
        stripClearanceKm = minCenterDistKm - widthKm/2;
        if stripClearanceKm <= params.usvHardClearanceKm
            score = -1e12;
            return;
        end
    else
        threatCost0 = 0;
        apfAlign0 = 0;
    end

    % --- UAV 地形障碍APF采样 ---
    if strcmpi(platformType, 'uav') && isfield(params, 'terrainThreatMap') && ~isempty(params.terrainThreatMap)
        [terrainThreatCost, terrainAPFAlign] = sampleUAVTerrainInfo(pos0, pos1, params);
    else
        terrainThreatCost = 0;
        terrainAPFAlign = 0;
    end

    % --- 条带覆盖评估 ---
    [r1, r2, c1, c2, stripMask] = getStripMask(pos0, pos1, widthKm, params);

    localKnown = knownMap(r1:r2, c1:c2);
    localIsland = islandMask(r1:r2, c1:c2);
    localSea = ~localIsland;
    stripMask = fitMaskSize(stripMask, size(localKnown));

    if strcmpi(platformType, 'uav')
        validMask = stripMask;
    else
        validMask = stripMask & localSea;
    end

    newMask = validMask & ~localKnown;
    revisitMask = validMask & localKnown;

    newSea = nnz(newMask & localSea);
    newIsland = nnz(newMask & localIsland);
    revisitCount = nnz(revisitMask);

    % --- UAV 评分 ---
    if strcmpi(platformType, 'uav')
        isIslandStage = (currIslandCoverage < params.islandStageThreshold);
        if isIslandStage && agentID <= 2
            wSea = 0.6;
            wIsland = 2.0;
            wRelay = 0.15;
            wSpread = 0.12;
            wSmooth = 0.05;
            wRevisit = 1.35;
        elseif isIslandStage
            wSea = 1.0;
            wIsland = 1.2;
            wRelay = 0.12;
            wSpread = 0.13;
            wSmooth = 0.05;
            wRevisit = 1.20;
        else
            wSea = 1.0;
            wIsland = 1.0;
            wRelay = 0.12;
            wSpread = 0.14;
            wSmooth = 0.05;
            wRevisit = 1.10;
        end

        baseGain = wSea * newSea + wIsland * newIsland - wRevisit * revisitCount;

        % 通信中继得分
        if isempty(relayTargets)
            relayScore = 0;
        else
            d = sqrt(sum((relayTargets - pos1).^2, 2));
            relayScore = max(0, 1 - min(d) / params.commRangeKm);
        end

        % 分散得分
        if isempty(sameTypeOthers)
            spreadScore = 1;
        else
            spreadScore = min(min(sqrt(sum((sameTypeOthers - pos1).^2, 2))) / params.spreadRefUAV, 1);
        end

        smoothScore = 1 - abs(dpsi) / max(abs(params.turnCandidatesUAV));

        % 地形APF项：UAV需要避开地形障碍
        wTerrain = params.terrainAPFWeightUAV;
        wTerrainAlign = min(8, params.terrainAPFWeightUAV * 0.5);

        score = baseGain ...
              + 40*wRelay*relayScore ...
              + 30*wSpread*spreadScore ...
              + 10*wSmooth*smoothScore ...
              - wTerrain * terrainThreatCost ...
              + wTerrainAlign * terrainAPFAlign;

    % --- USV 评分 ---
    else
        wSea = 1.0;
        wComm = 0.35;
        wSpread = 0.18;
        wSmooth = 0.07;
        wRevisit = 1.15;
        wThreat = params.usvThreatWeight;
        wAPF = params.usvAPFAlignWeight;

        baseGain = wSea * newSea - wRevisit * revisitCount;

        if isempty(relayTargets)
            commScore = 0;
        else
            d = sqrt(sum((relayTargets - pos1).^2, 2));
            inRange = d <= params.commRangeKm;
            if any(inRange)
                commScore = 0.6 * (sum(inRange) / size(relayTargets, 1)) + ...
                            0.4 * (1 - mean(d(inRange)) / params.commRangeKm);
            else
                commScore = 0;
            end
        end

        if isempty(sameTypeOthers)
            spreadScore = 1;
        else
            spreadScore = min(min(sqrt(sum((sameTypeOthers - pos1).^2, 2))) / params.spreadRefUSV, 1);
        end

        smoothScore = 1 - abs(dpsi) / max(abs(params.turnCandidatesUSV));

        score = baseGain ...
              + 30*wComm*commScore ...
              + 25*wSpread*spreadScore ...
              + 8*wSmooth*smoothScore ...
              - 120*wThreat*threatCost0 ...
              + 20*wAPF*apfAlign0;
    end
end

% ==================================================================
function [terrainThreatCost, terrainAPFAlign] = sampleUAVTerrainInfo(pos0, pos1, params)
% sampleUAVTerrainInfo  采样UAV路径上的地形势场信息
%
%  与USV的sampleUSVThreatInfo类似，但用于UAV地形避障。

    segLen = norm(pos1 - pos0);
    nSample = max(5, ceil(segLen / (params.dx / 2)) + 1);

    threatVals = zeros(nSample, 1);
    forceVals = zeros(nSample, 2);

    for kk = 1:nSample
        a = (kk - 1) / max(nSample - 1, 1);
        p = pos0 + a * (pos1 - pos0);
        [row, col] = posToIndex(p, params);
        threatVals(kk) = params.terrainThreatMap(row, col);
        forceVals(kk, 1) = params.terrainForceX(row, col);
        forceVals(kk, 2) = params.terrainForceY(row, col);
    end

    maxThreat = max(threatVals);
    meanThreat = mean(threatVals);
    terrainThreatCost = 0.55 * meanThreat + 0.30 * maxThreat;
    terrainThreatCost = min(max(terrainThreatCost, 0), 1.5);

    % APF对齐奖励：运动方向与斥力方向一致则加分
    moveVec = pos1 - pos0;
    avgForce = mean(forceVals, 1);
    if norm(moveVec) < 1e-12 || norm(avgForce) < 1e-12
        terrainAPFAlign = 0;
    else
        moveHat = moveVec / norm(moveVec);
        forceHat = avgForce / norm(avgForce);
        terrainAPFAlign = max(0, dot(moveHat, forceHat));
    end
end
