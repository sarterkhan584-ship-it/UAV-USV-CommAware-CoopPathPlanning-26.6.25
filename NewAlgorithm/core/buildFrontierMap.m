function frontierMap = buildFrontierMap(coveredGlobal, islandMask, params) %#ok<INUSD>
% buildFrontierMap 构造“已覆盖-未覆盖”交界区域，用于后期牵引至未覆盖空洞。

    neighborCovered = conv2(double(coveredGlobal), ones(3), 'same') > 0;
    frontier = (~coveredGlobal) & neighborCovered;

    radiusCell = max(1, ceil(params.frontierRadiusKm / params.dx));
    radiusCell = min(radiusCell, 12);
    frontierMap = conv2(double(frontier), ones(2*radiusCell + 1), 'same') > 0;
    frontierMap = frontierMap & (~coveredGlobal);
end
