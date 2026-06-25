function [distToIslandKm, threatMap, forceX, forceY] = buildIslandThreatField(islandMask, params)
    if exist('bwdist', 'file') == 2
        distToIslandKm = bwdist(islandMask) * params.dx;
    else
        distToIslandKm = computeDistanceMapFallback(islandMask, params.dx);
    end

    d0 = params.usvThreatInfluenceKm;
    epsD = params.usvThreatEpsKm;
    threatMap = zeros(size(distToIslandKm));

    idx = distToIslandKm < d0;
    dEff = max(distToIslandKm(idx), epsD);
    threatMap(idx) = 0.5 * ((1 ./ dEff) - (1 / d0)).^2;

    if any(threatMap(:) > 0)
        threatMap = threatMap / max(threatMap(:));
    end
    threatMap(islandMask) = 1;

    [gradY, gradX] = gradient(threatMap, params.dx, params.dx);
    forceX = -gradX;
    forceY = -gradY;
end
