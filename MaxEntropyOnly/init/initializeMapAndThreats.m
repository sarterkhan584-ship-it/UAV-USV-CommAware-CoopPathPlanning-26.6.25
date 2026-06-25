function [islandMask, seaMask, xGrid, yGrid, mapStats, params] = initializeMapAndThreats(params)
% initializeMapAndThreats 生成地图、预计算岛屿威胁场，并构建3D地形DEM

    [islandMask, xGrid, yGrid, mapStats] = createIslandMap(params.mapLenKm, params.N, params.mapSeed);
    seaMask = ~islandMask;

    % 岛屿威胁场（USV避障用）
    [distToIslandKm, islandThreatMap, islandForceX, islandForceY] = buildIslandThreatField(islandMask, params);
    params.distToIslandKm = distToIslandKm;
    params.islandThreatMap = islandThreatMap;
    params.islandForceX = islandForceX;
    params.islandForceY = islandForceY;

    % 3D地形DEM（通信LoS判定 + UAV地形APF避障用）
    [terrainHeightMap, terrainSlopeMap, terrainSurfaceWeight, terrainStats] = ...
        buildTerrainDEM(islandMask, xGrid, yGrid, params);
    params.terrainHeightMap = terrainHeightMap;
    params.terrainSlopeMap = terrainSlopeMap;
    params.terrainSurfaceWeight = terrainSurfaceWeight;
    params.terrainStats = terrainStats;

    % 地形势场（UAV避障用）
    [~, terrainThreatMap, terrainForceX, terrainForceY] = buildTerrainThreatField(terrainHeightMap, params);
    params.terrainThreatMap = terrainThreatMap;
    params.terrainForceX = terrainForceX;
    params.terrainForceY = terrainForceY;

    fprintf('========== 地图信息 ==========' ); fprintf('\n');
    fprintf('地图尺寸             : %.1f km × %.1f km\n', params.mapLenKm, params.mapLenKm);
    fprintf('网格尺寸             : %.0f m × %.0f m\n', params.dx*1000, params.dx*1000);
    fprintf('网格数               : %d × %d\n', params.N, params.N);
    fprintf('岛屿占比             : %.2f%%\n', mapStats.totalPct);
    fprintf('海洋占比             : %.2f%%\n', mapStats.oceanPct);
    fprintf('地形最大高程         : %.0f m\n', terrainStats.maxElevationKm*1000);
    fprintf('地形平均高程         : %.0f m\n', terrainStats.meanElevationKm*1000);
    fprintf('终止覆盖率阈值       : %.2f %%\n', 100*params.targetCoverage);
    fprintf('USV 岛屿影响半径     : %.0f m\n', params.usvThreatInfluenceKm*1000);
    fprintf('USV 硬安全净空       : %.0f m\n', params.usvHardClearanceKm*1000);
    fprintf('================================\n\n');
end
