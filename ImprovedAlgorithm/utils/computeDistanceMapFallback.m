function distMapKm = computeDistanceMapFallback(islandMask, dx)
    [Nrow, Ncol] = size(islandMask);
    [rObs, cObs] = find(islandMask);
    if isempty(rObs)
        distMapKm = inf(Nrow, Ncol);
        return;
    end

    [C, R] = meshgrid(1:Ncol, 1:Nrow);
    xAll = (C(:) - 0.5) * dx;
    yAll = (R(:) - 0.5) * dx;
    xObs = (cObs - 0.5) * dx;
    yObs = (rObs - 0.5) * dx;

    minDist2 = inf(numel(xAll), 1);
    blockSize = 200;
    for s = 1:blockSize:numel(xObs)
        e = min(s + blockSize - 1, numel(xObs));
        xb = xObs(s:e)';
        yb = yObs(s:e)';
        d2 = (xAll - xb).^2 + (yAll - yb).^2;
        minDist2 = min(minDist2, min(d2, [], 2));
    end

    distMapKm = reshape(sqrt(minDist2), Nrow, Ncol);
end
