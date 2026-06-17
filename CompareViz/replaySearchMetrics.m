function replay = replaySearchMetrics(results, islandMask, params, snapshotSteps)
% replaySearchMetrics 根据保存的 UAV/USV 航迹回放覆盖过程，统计快照与重复探测次数。

    N = params.N;
    covered = false(N, N);
    visitCount = zeros(N, N);
    snapshots = cell(numel(snapshotSteps), 1);
    snapshotSaved = false(numel(snapshotSteps), 1);

    nUAV = size(results.uavTrail, 2);
    nUSV = size(results.usvTrail, 2);
    totalSteps = max(size(results.uavTrail, 1), size(results.usvTrail, 1)) - 1;
    maxReplayStep = max(snapshotSteps);
    totalSteps = min(totalSteps, maxReplayStep);

    % 初始点观测。
    for i = 1:nUAV
        pos = squeeze(results.uavTrail(1, i, :))';
        [covered, visitCount] = applyReplayObservation(pos, pos, covered, visitCount, islandMask, params, 'uav');
    end
    for j = 1:nUSV
        pos = squeeze(results.usvTrail(1, j, :))';
        [covered, visitCount] = applyReplayObservation(pos, pos, covered, visitCount, islandMask, params, 'usv');
    end

    for s = 1:numel(snapshotSteps)
        if snapshotSteps(s) == 0
            snapshots{s} = covered;
            snapshotSaved(s) = true;
        end
    end

    for k = 1:totalSteps
        for i = 1:nUAV
            if k + 1 <= size(results.uavTrail, 1)
                pos0 = squeeze(results.uavTrail(k, i, :))';
                pos1 = squeeze(results.uavTrail(k + 1, i, :))';
                [covered, visitCount] = applyReplayObservation(pos0, pos1, covered, visitCount, islandMask, params, 'uav');
            end
        end
        for j = 1:nUSV
            if k + 1 <= size(results.usvTrail, 1)
                pos0 = squeeze(results.usvTrail(k, j, :))';
                pos1 = squeeze(results.usvTrail(k + 1, j, :))';
                [covered, visitCount] = applyReplayObservation(pos0, pos1, covered, visitCount, islandMask, params, 'usv');
            end
        end

        for s = 1:numel(snapshotSteps)
            if ~snapshotSaved(s) && k >= snapshotSteps(s)
                snapshots{s} = covered;
                snapshotSaved(s) = true;
            end
        end
    end

    for s = 1:numel(snapshotSteps)
        if ~snapshotSaved(s)
            snapshots{s} = covered;
        end
    end

    replay.visitCount = visitCount;
    replay.finalCovered = covered;
    replay.snapshots = snapshots;
end

function [covered, visitCount] = applyReplayObservation(pos0, pos1, covered, visitCount, islandMask, params, platformType)
    if strcmpi(platformType, 'uav')
        widthKm = params.sensorStripWidthUAVKm;
    else
        widthKm = params.sensorStripWidthUSVKm;
    end
    [r1, r2, c1, c2, stripMask] = getStripMaskLocal(pos0, pos1, widthKm, params);
    if isempty(stripMask)
        return;
    end
    islandLocal = islandMask(r1:r2, c1:c2);
    if strcmpi(platformType, 'uav')
        validMask = stripMask;
    else
        validMask = stripMask & (~islandLocal);
    end
    localCovered = covered(r1:r2, c1:c2);
    localVisit = visitCount(r1:r2, c1:c2);
    localCovered(validMask) = true;
    localVisit(validMask) = localVisit(validMask) + 1;
    covered(r1:r2, c1:c2) = localCovered;
    visitCount(r1:r2, c1:c2) = localVisit;
end

function [r1, r2, c1, c2, stripMask] = getStripMaskLocal(pos0, pos1, widthKm, params)
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

    dist = pointToSegmentDistanceLocal(Xc, Yc, pos0, pos1);
    stripMask = reshape(dist <= halfW, numel(rows), numel(cols));
end

function dist = pointToSegmentDistanceLocal(X, Y, A, B)
    AB = B - A;
    denom = AB(1)^2 + AB(2)^2;
    if denom < 1e-12
        dist = hypot(X - A(1), Y - A(2));
        return;
    end
    t = ((X - A(1)).*AB(1) + (Y - A(2)).*AB(2)) / denom;
    t = min(max(t, 0), 1);
    projX = A(1) + t .* AB(1);
    projY = A(2) + t .* AB(2);
    dist = hypot(X - projX, Y - projY);
end
