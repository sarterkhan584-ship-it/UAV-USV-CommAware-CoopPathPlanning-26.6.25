function z = getUAVAltitudeAtPos(posXY, params)
% getUAVAltitudeAtPos keeps UAVs above both cruise altitude and local terrain.
    terrainZ = getTerrainHeightAtPos(posXY, params);
    z = max(params.uavCruiseAltitudeKm, terrainZ + params.uavTerrainClearanceKm);
end
