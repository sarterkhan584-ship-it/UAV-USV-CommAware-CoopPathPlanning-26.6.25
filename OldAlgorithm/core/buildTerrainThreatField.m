function [distToTerrainKm, threatMap, forceX, forceY] = buildTerrainThreatField(terrainHeightMap, params)
% buildTerrainThreatField  从地形DEM构建UAV地形避碰人工势场
%
%  在岛屿地形区域，UAV需要保持minTerrainClearanceKm的最低净空。
%  地形势场对低于安全高度的区域产生斥力，引导UAV避开地形障碍。
%
%  输入:
%    terrainHeightMap - NxN DEM (km)
%    params - 参数结构体（需含 dx, uavCruiseAltitudeKm, uavTerrainClearanceKm,
%                        minTerrainClearanceKm, terrainInfluenceKm）
%
%  输出:
%    distToTerrainKm - 到地形危险区的距离 (km)
%    threatMap       - 归一化威胁值 [0,1]
%    forceX, forceY  - 斥力场 (负梯度方向)

    % 地形危险区域：DEM高度 > UAV安全高度 - minTerrainClearanceKm
    minSafeAlt = params.uavCruiseAltitudeKm - params.minTerrainClearanceKm;
    dangerMask = terrainHeightMap > minSafeAlt;

    % 计算到危险区的距离
    if any(dangerMask(:))
        if exist('bwdist', 'file') == 2
            distToTerrainPx = bwdist(dangerMask);
        else
            distToTerrainPx = computeDistanceMapFallback(dangerMask, 1);
        end
        distToTerrainKm = distToTerrainPx * params.dx;
    else
        distToTerrainKm = inf(size(terrainHeightMap));
    end

    % 构建威胁场（类似USV岛屿威胁场）
    d0 = params.terrainInfluenceKm;  % terrain repulsion influence radius
    epsD = 0.01;  % epsilon to prevent division by zero
    threatMap = zeros(size(distToTerrainKm));

    idx = distToTerrainKm < d0;
    dEff = max(distToTerrainKm(idx), epsD);
    threatMap(idx) = 0.5 * ((1 ./ dEff) - (1 / d0)).^2;

    if any(threatMap(:) > 0)
        threatMap = threatMap / max(threatMap(:));
    end
    threatMap(dangerMask) = 1;

    % 梯度 = 斥力方向（远离高威胁区域）
    [gradY, gradX] = gradient(threatMap, params.dx, params.dx);
    forceX = -gradX;
    forceY = -gradY;
end
