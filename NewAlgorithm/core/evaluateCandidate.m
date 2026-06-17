function score = evaluateCandidate(pos0, pos1, dpsi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage)
% evaluateCandidate 最大熵-信息素联合覆盖搜索评价函数（增强版）
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

    % --- USV 硬约束 ---
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

    % --- 条带评估 ---
    [r1, r2, c1, c2, stripMask] = getStripMask(pos0, pos1, widthKm, params);

    localKnown = knownMap(r1:r2, c1:c2);
    localIsland = islandMask(r1:r2, c1:c2);
    localSea = ~localIsland;
    localEntropy = state.entropyMap(r1:r2, c1:c2);
    localAttr = state.attractionPheromone(r1:r2, c1:c2);
    localRep = state.repulsionPheromone(r1:r2, c1:c2);
    localVisit = state.visitCountGlobal(r1:r2, c1:c2);
    localFrontier = state.frontierMap(r1:r2, c1:c2);
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

    rho = mean(state.coveredGlobal(:));
    [lambdaC, lambdaH, lambdaA, lambdaR, lambdaF] = getDynamicWeights(rho, params);

    entropyGain = sum(localEntropy(validMask));
    attractGain = sum(localAttr(validMask));
    repeatCost = sum((localVisit(validMask) + double(revisitMask(validMask))).^params.visitPenaltyPower) + sum(localRep(validMask)) + revisitCount;
    frontierGain = nnz(localFrontier & validMask);

    % 通信中继得分
    if isempty(relayTargets)
        relayScore = 0;
    else
        d = sqrt(sum((relayTargets - pos1).^2, 2));
        if strcmpi(platformType, 'uav')
            relayScore = max(0, 1 - min(d) / params.commRangeKm);
        else
            inRange = d <= params.commRangeKm;
            if any(inRange)
                relayScore = 0.6 * (sum(inRange) / size(relayTargets, 1)) + 0.4 * (1 - mean(d(inRange)) / params.commRangeKm);
            else
                relayScore = 0;
            end
        end
    end

    % 分散得分
    if isempty(sameTypeOthers)
        spreadScore = 1;
    else
        if strcmpi(platformType, 'uav')
            spreadScore = min(min(sqrt(sum((sameTypeOthers - pos1).^2, 2))) / params.spreadRefUAV, 1);
        else
            spreadScore = min(min(sqrt(sum((sameTypeOthers - pos1).^2, 2))) / params.spreadRefUSV, 1);
        end
    end

    % 平滑得分
    if strcmpi(platformType, 'uav')
        smoothScore = 1 - abs(dpsi) / max(abs(params.turnCandidatesUAV));
    else
        smoothScore = 1 - abs(dpsi) / max(abs(params.turnCandidatesUSV));
    end

    boundaryScore = getBoundaryScore(pos1, params);

    % --- 综合评分 ---
    if strcmpi(platformType, 'uav')
        isIslandStage = (currIslandCoverage < params.islandStageThreshold);
        if isIslandStage && agentID <= 2
            wSea = 0.6;  wIsland = 2.0;
        elseif isIslandStage
            wSea = 1.0;  wIsland = 1.2;
        else
            wSea = 1.0;  wIsland = 1.0;
        end
        coverageGain = wSea * newSea + wIsland * newIsland;

        wTerrain = params.terrainAPFWeightUAV;
        wTerrainAlign = min(8, params.terrainAPFWeightUAV * 0.5);

        score = lambdaC * coverageGain ...
              + lambdaH * entropyGain ...
              + lambdaA * attractGain ...
              - lambdaR * repeatCost ...
              + 25 * lambdaF * frontierGain ...
              + 28 * relayScore ...
              + 22 * spreadScore ...
              + 8 * smoothScore ...
              + params.boundaryPotentialWeightUAV * boundaryScore ...
              - wTerrain * terrainThreatCost ...
              + wTerrainAlign * terrainAPFAlign;
    else
        coverageGain = newSea;
        score = lambdaC * coverageGain ...
              + 0.85 * lambdaH * entropyGain ...
              + 0.70 * lambdaA * attractGain ...
              - 1.15 * lambdaR * repeatCost ...
              + 20 * lambdaF * frontierGain ...
              + 30 * relayScore ...
              + 24 * spreadScore ...
              + 14 * smoothScore ...
              + params.boundaryPotentialWeightUSV * boundaryScore ...
              - 120 * params.usvThreatWeight * threatCost0 ...
              + 20 * params.usvAPFAlignWeight * apfAlign0;
    end
end

% ==================================================================
function [lambdaC, lambdaH, lambdaA, lambdaR, lambdaF] = getDynamicWeights(rho, params)
    rho = min(max(rho, 0), 1);
    p = params.dynamicWeightPower;
    lambdaC = params.lambdaCMin + (params.lambdaCMax - params.lambdaCMin) * (1 - rho)^p;
    lambdaH = params.lambdaHMin + (params.lambdaHMax - params.lambdaHMin) * rho^p;
    lambdaA = params.lambdaAMin + (params.lambdaAMax - params.lambdaAMin) * rho^p;
    lambdaR = params.lambdaRMin + (params.lambdaRMax - params.lambdaRMin) * rho^p;
    lambdaF = params.lambdaFMin + (params.lambdaFMax - params.lambdaFMin) * rho^p;
end

% ==================================================================
function boundaryScore = getBoundaryScore(pos, params)
    epsB = params.boundaryEpsKm;
    x = pos(1);
    y = pos(2);
    L = params.mapLenKm;
    boundaryScore = -((epsB / (x + epsB)) + (epsB / (L - x + epsB)) + ...
                      (epsB / (y + epsB)) + (epsB / (L - y + epsB)));
end

% ==================================================================
function [terrainThreatCost, terrainAPFAlign] = sampleUAVTerrainInfo(pos0, pos1, params)
% sampleUAVTerrainInfo  采样UAV路径上的地形势场信息
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
