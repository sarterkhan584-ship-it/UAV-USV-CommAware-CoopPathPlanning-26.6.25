function [r1, r2, c1, c2, stripMask] = getStripMask(pos0, pos1, widthKm, params)
    halfW = widthKm / 2;

    xMin = max(0, min(pos0(1), pos1(1)) - halfW);
    xMax = min(params.mapLenKm, max(pos0(1), pos1(1)) + halfW);
    yMin = max(0, min(pos0(2), pos1(2)) - halfW);
    yMax = min(params.mapLenKm, max(pos0(2), pos1(2)) + halfW);

    c1 = max(1, floor(xMin / params.dx) + 1);
    c2 = min(params.N, floor(max(xMax - eps, 0) / params.dx) + 1);
    r1 = max(1, floor(yMin / params.dx) + 1);
    r2 = min(params.N, floor(max(yMax - eps, 0) / params.dx) + 1);

    cols = c1:c2;
    rows = r1:r2;
    if isempty(rows) || isempty(cols)
        stripMask = false(0, 0);
        return;
    end

    xCells = (cols - 0.5) * params.dx;
    yCells = (rows - 0.5) * params.dx;
    [Xc, Yc] = meshgrid(xCells, yCells);

    dist = pointToSegmentDistance(Xc, Yc, pos0, pos1);
    stripMask = reshape(dist <= halfW, numel(rows), numel(cols));
end
