function [terrainHeightMap, terrainSlopeMap, terrainSurfaceWeight, terrainStats] = buildTerrainDEM(islandMask, xGrid, yGrid, params)
% buildTerrainDEM builds a repeatable island DEM on top of the 2-D island mask.
% Units are km so the map can be used directly with the existing planner.

    rng(params.mapSeed + params.terrainSeedOffset);

    [X, Y] = meshgrid(xGrid, yGrid);
    terrainHeightMap = zeros(size(islandMask));
    islandIdx = find(islandMask);

    if isempty(islandIdx)
        terrainSlopeMap = zeros(size(islandMask));
        terrainSurfaceWeight = ones(size(islandMask));
        terrainStats = makeStats(terrainHeightMap, terrainSlopeMap, terrainSurfaceWeight, islandMask);
        return;
    end

    if exist('bwdist', 'file') == 2
        distToSeaKm = bwdist(~islandMask) * params.dx;
    else
        distToSeaKm = computeDistanceMapFallback(~islandMask, params.dx);
    end
    edgeTaper = min(distToSeaKm / max(params.terrainCoastTaperKm, eps), 1);
    edgeTaper = edgeTaper .^ 0.8;
    edgeTaper(~islandMask) = 0;

    % Main ridge, aligned obliquely
    ridgeCenter = [0.38 * params.mapLenKm, 0.54 * params.mapLenKm];
    ridgePhi = deg2rad(22);
    xr =  cos(ridgePhi) * (X - ridgeCenter(1)) + sin(ridgePhi) * (Y - ridgeCenter(2));
    yr = -sin(ridgePhi) * (X - ridgeCenter(1)) + cos(ridgePhi) * (Y - ridgeCenter(2));
    ridge = exp(-(xr.^2 / (2 * params.terrainRidgeLengthKm^2) + yr.^2 / (2 * params.terrainRidgeWidthKm^2)));
    terrainHeightMap = terrainHeightMap + 0.65 * params.terrainMaxElevationKm * ridge;

    [rows, cols] = ind2sub(size(islandMask), islandIdx);
    peakCount = min(params.terrainPeakCount, numel(islandIdx));
    peakPick = islandIdx(randperm(numel(islandIdx), peakCount));
    [peakRows, peakCols] = ind2sub(size(islandMask), peakPick);

    for k = 1:peakCount
        cx = xGrid(peakCols(k));
        cy = yGrid(peakRows(k));
        sigma = params.terrainPeakSigmaMinKm + ...
            (params.terrainPeakSigmaMaxKm - params.terrainPeakSigmaMinKm) * rand;
        amp = (0.25 + 0.75 * rand) * params.terrainMaxElevationKm;
        terrainHeightMap = terrainHeightMap + amp * exp(-((X - cx).^2 + (Y - cy).^2) / (2 * sigma^2));
    end

    undulation = 0.04 * params.terrainMaxElevationKm * ...
        (sin(2*pi*X/params.mapLenKm + 0.7) + cos(2*pi*Y/params.mapLenKm + 1.1));
    terrainHeightMap = max(terrainHeightMap + undulation, 0);
    terrainHeightMap = terrainHeightMap .* edgeTaper;
    terrainHeightMap(~islandMask) = 0;

    kernel = gaussianKernel(params.terrainSmoothRadiusCells);
    terrainHeightMap = conv2(terrainHeightMap, kernel, 'same');
    terrainHeightMap = terrainHeightMap .* islandMask;
    if max(terrainHeightMap(:)) > 0
        terrainHeightMap = terrainHeightMap / max(terrainHeightMap(:)) * params.terrainMaxElevationKm;
    end

    [gradY, gradX] = gradient(terrainHeightMap, params.dx, params.dx);
    terrainSlopeMap = hypot(gradX, gradY);
    terrainSlopeMap(~islandMask) = 0;
    terrainSurfaceWeight = sqrt(1 + terrainSlopeMap.^2);
    terrainSurfaceWeight(~islandMask) = 1;

    terrainStats = makeStats(terrainHeightMap, terrainSlopeMap, terrainSurfaceWeight, islandMask);
    terrainStats.peakCount = peakCount;
    terrainStats.seed = params.mapSeed + params.terrainSeedOffset;
end

function kernel = gaussianKernel(radiusCells)
    radiusCells = max(1, round(radiusCells));
    [X, Y] = meshgrid(-radiusCells:radiusCells, -radiusCells:radiusCells);
    sigma = max(radiusCells / 2, 0.5);
    kernel = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
    kernel = kernel / sum(kernel(:));
end

function stats = makeStats(heightMap, slopeMap, surfaceWeight, islandMask)
    h = heightMap(islandMask);
    s = slopeMap(islandMask);
    w = surfaceWeight(islandMask);
    if isempty(h)
        h = 0; s = 0; w = 1;
    end
    stats.maxElevationKm = max(h);
    stats.meanElevationKm = mean(h);
    stats.maxSlope = max(s);
    stats.meanSlope = mean(s);
    stats.surfaceAreaFactor = mean(w);
end
