function h = getTerrainHeightAtPos(pos, params)
% getTerrainHeightAtPos returns nearest-cell terrain elevation in km.
    if ~isfield(params, 'terrainHeightMap') || isempty(params.terrainHeightMap)
        h = 0;
        return;
    end
    row = min(max(floor(pos(2) / params.dx) + 1, 1), params.N);
    col = min(max(floor(pos(1) / params.dx) + 1, 1), params.N);
    h = params.terrainHeightMap(row, col);
end
