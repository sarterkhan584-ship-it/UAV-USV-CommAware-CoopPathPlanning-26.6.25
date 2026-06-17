function [minCenterDistKm, threatCost, apfAlign] = sampleUSVThreatInfo(pos0, pos1, stripWidthKm, params)
    segLen = norm(pos1 - pos0);
    nSample = max(5, ceil(segLen / (params.dx / 2)) + 1);

    distVals = zeros(nSample, 1);
    threatVals = zeros(nSample, 1);
    forceVals = zeros(nSample, 2);

    for kk = 1:nSample
        a = (kk - 1) / max(nSample - 1, 1);
        p = pos0 + a * (pos1 - pos0);
        [row, col] = posToIndex(p, params);

        distVals(kk) = params.distToIslandKm(row, col);
        threatVals(kk) = params.islandThreatMap(row, col);
        forceVals(kk, 1) = params.islandForceX(row, col);
        forceVals(kk, 2) = params.islandForceY(row, col);
    end

    minCenterDistKm = min(distVals);
    maxThreat = max(threatVals);
    meanThreat = mean(threatVals);

    clearanceVals = max(distVals - stripWidthKm/2, 0);
    clearancePenalty = max(0, 1 - min(clearanceVals) / max(params.usvThreatInfluenceKm, eps));
    threatCost = 0.55 * meanThreat + 0.30 * maxThreat + 0.15 * clearancePenalty;
    threatCost = min(max(threatCost, 0), 1.5);

    moveVec = pos1 - pos0;
    avgForce = mean(forceVals, 1);
    if norm(moveVec) < 1e-12 || norm(avgForce) < 1e-12
        apfAlign = 0;
    else
        moveHat = moveVec / norm(moveVec);
        forceHat = avgForce / norm(avgForce);
        apfAlign = max(0, dot(moveHat, forceHat));
    end
end
