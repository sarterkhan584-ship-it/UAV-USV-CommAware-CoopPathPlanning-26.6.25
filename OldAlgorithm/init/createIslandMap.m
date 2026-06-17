function [map, x, y, stats] = createIslandMap(mapLenKm, N, seed)
% createIslandMap  生成二维海岛地图
%
% 输出：
%   map   : N×N 二值地图，1-岛屿，0-海洋
%   x, y  : 地图坐标（单位：km）
%   stats : 面积占比统计信息
%
% 输入：
%   mapLenKm : 地图边长（km），默认 10
%   N        : 栅格分辨率，默认 200（对应 50 m 网格）
%   seed     : 随机种子，默认 1
%
% 说明：
%   以 10 km × 10 km 地图为基准几何，保持“大岛 25% + 零散岛屿 15%”
%   的整体形状与面积占比。若输入其他 mapLenKm，则做等比缩放。

    if nargin < 1
        mapLenKm = 10;
    end
    if nargin < 2
        N = 200;
    end
    if nargin < 3
        seed = 1;
    end

    rng(seed);

    %% 1) 网格坐标
    dx = mapLenKm / N;
    x = dx/2 : dx : mapLenKm - dx/2;
    y = dx/2 : dx : mapLenKm - dx/2;
    [X, Y] = meshgrid(x, y);

    totalArea = mapLenKm^2;
    bigAreaTarget   = 0.25 * totalArea;
    smallAreaTarget = 0.15 * totalArea;

    bigCellsTarget   = round(bigAreaTarget   / dx^2);
    smallCellsTarget = round(smallAreaTarget / dx^2);

    %% 2) 以 10 km 地图为基准做等比缩放
    scale = mapLenKm / 10;

    %% 3) 大岛
    cx = 3.5  * scale;
    cy = 5.2  * scale;
    a  = 3.1  * scale;
    b  = 2.45 * scale;
    phi = deg2rad(18);

    [xr, yr] = rotateShift(X, Y, cx, cy, phi);
    theta = atan2(yr, xr);
    shapeBig = 1 + 0.10*cos(3*theta) + 0.06*sin(5*theta + 0.8);
    Fbig = (xr ./ (a * shapeBig)).^2 + (yr ./ (b * shapeBig)).^2;

    valsBig = sort(Fbig(:), 'ascend');
    thBig = valsBig(bigCellsTarget);
    bigMask = (Fbig <= thBig);

    %% 4) 零散岛
    islandNum = 18;
    centers = zeros(islandNum, 2);
    count = 0;
    tries = 0;
    maxTries = 5000;

    while count < islandNum && tries < maxTries
        tries = tries + 1;
        cxk = 0.6*scale + (mapLenKm - 1.2*scale) * rand;
        cyk = 0.6*scale + (mapLenKm - 1.2*scale) * rand;

        [xrc, yrc] = rotateShift(cxk, cyk, cx, cy, phi);
        theta0 = atan2(yrc, xrc);
        shape0 = 1 + 0.10*cos(3*theta0) + 0.06*sin(5*theta0 + 0.8);
        F0 = (xrc / (a * shape0))^2 + (yrc / (b * shape0))^2;
        if F0 < 2.0
            continue;
        end

        if count > 0
            distMin = min(vecnorm(centers(1:count, :) - [cxk, cyk], 2, 2));
            if distMin < 0.9*scale
                continue;
            end
        end

        count = count + 1;
        centers(count, :) = [cxk, cyk];
    end

    if count < islandNum
        error('小岛中心生成失败，请适当增大 maxTries 或减小 islandNum。');
    end

    Fsmall = inf(size(X));
    for k = 1:islandNum
        cxk = centers(k, 1);
        cyk = centers(k, 2);

        ak = (0.22 + 0.40 * rand) * scale;
        bk = (0.15 + 0.30 * rand) * scale;
        phik = pi * rand;
        phase1 = 2*pi*rand;
        phase2 = 2*pi*rand;

        [xrk, yrk] = rotateShift(X, Y, cxk, cyk, phik);
        thetak = atan2(yrk, xrk);
        shapeSmall = 1 + 0.12*cos(2*thetak + phase1) + 0.07*sin(4*thetak + phase2);
        Fk = (xrk ./ (ak * shapeSmall)).^2 + (yrk ./ (bk * shapeSmall)).^2;
        Fsmall = min(Fsmall, Fk);
    end

    Fsmall(bigMask) = inf;
    valsSmall = sort(Fsmall(~bigMask), 'ascend');
    thSmall = valsSmall(smallCellsTarget);
    smallMask = (Fsmall <= thSmall) & (~bigMask);

    %% 5) 合成地图
    map = bigMask | smallMask;

    %% 6) 统计信息
    stats.bigPct   = nnz(bigMask)   / numel(map) * 100;
    stats.smallPct = nnz(smallMask) / numel(map) * 100;
    stats.totalPct = nnz(map)       / numel(map) * 100;
    stats.oceanPct = 100 - stats.totalPct;
    stats.dx = dx;
    stats.mapLenKm = mapLenKm;
end

function [xr, yr] = rotateShift(X, Y, cx, cy, phi)
% 将坐标平移到 (cx, cy) 为中心，并旋转 phi
    x0 = X - cx;
    y0 = Y - cy;
    xr =  cos(phi) * x0 + sin(phi) * y0;
    yr = -sin(phi) * x0 + cos(phi) * y0;
end
