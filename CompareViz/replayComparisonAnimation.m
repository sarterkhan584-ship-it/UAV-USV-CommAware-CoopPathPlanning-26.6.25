function replayComparisonAnimation(oldResults, newResults, params, mapData, cfg)
% replayComparisonAnimation 同步回放两种算法的动态航迹与覆盖率曲线。
% 左右两个画面分别显示原算法和最大熵-信息素算法的 无人机/无人艇航迹、无人机短距通信圆、通信链路与通信状态。

    if ~isfield(cfg, 'enableComparisonAnimation') || ~cfg.enableComparisonAnimation
        return;
    end

    islandMask = mapData.islandMask;
    xGrid = mapData.xGrid;
    yGrid = mapData.yGrid;
    maxStep = min([size(oldResults.uavTrail,1), size(newResults.uavTrail,1), numel(oldResults.coverageHist), numel(newResults.coverageHist)]) - 1;
    if maxStep < 1
        return;
    end
    stride = getFieldOrDefault(cfg, 'comparisonAnimationStride', 5);
    pauseTime = getFieldOrDefault(cfg, 'comparisonAnimationPause', 0.001);

    oldCovered = false(params.N, params.N);
    newCovered = false(params.N, params.N);
    oldCovered = observeInitial(oldCovered, oldResults, islandMask, params);
    newCovered = observeInitial(newCovered, newResults, islandMask, params);

    colors.uav = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    colors.usv = [0.00 0.40 0.95; 0.00 0.75 0.85; 0.25 0.25 0.25];
    colors.connected = params.connectedUAVColor;

    mapFig = figure('Color','w','Position',[40 60 1500 720], 'Name', '动态航迹对比：原算法 / 最大熵-信息素算法');
    tl = tiledlayout(mapFig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');
    oldViz = initMapPanel(nexttile(tl, 1), oldCovered, islandMask, xGrid, yGrid, oldResults, 0, params, colors, '原算法');
    newViz = initMapPanel(nexttile(tl, 2), newCovered, islandMask, xGrid, yGrid, newResults, 0, params, colors, '最大熵-信息素算法');
    sgtitle(tl, '无人机/无人艇动态航迹与通信状态对比', 'FontSize', 14, 'FontWeight', 'bold');

    curveFig = figure('Color','w','Position',[120 120 900 620], 'Name', '动态覆盖率曲线对比');
    curveAx = axes(curveFig); hold(curveAx, 'on'); grid(curveAx, 'on'); box(curveAx, 'on');
    xlabel(curveAx, '时间/s', 'FontSize', 12);
    ylabel(curveAx, '覆盖率/%', 'FontSize', 12);
    title(curveAx, '两种算法覆盖率动态变化对比', 'FontSize', 13);
    xlim(curveAx, [0, maxStep * params.dt]); ylim(curveAx, [0, 100]);
    hNewCurve = plot(curveAx, 0, 100*newResults.coverageHist(1), '-', 'LineWidth', 2.0, 'Color', [0 0.45 0.74]);
    hOldCurve = plot(curveAx, 0, 100*oldResults.coverageHist(1), '-', 'LineWidth', 2.0, 'Color', [0.85 0.33 0.10]);
    plot(curveAx, [0, maxStep*params.dt], 100*cfg.coverageThreshold*[1 1], '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
    legend(curveAx, {'最大熵-信息素算法', '原算法', sprintf('%.0f%%覆盖阈值', 100*cfg.coverageThreshold)}, 'Location', 'southeast');

    mapVideo = [];
    curveVideo = [];
    if getFieldOrDefault(cfg, 'saveComparisonAnimationVideo', false) && exist('VideoWriter', 'class') == 8
        try
            mapVideo = VideoWriter(cfg.comparisonMapVideoName, 'MPEG-4');
            curveVideo = VideoWriter(cfg.comparisonCurveVideoName, 'MPEG-4');
        catch
            mapVideo = VideoWriter(strrep(cfg.comparisonMapVideoName, '.mp4', '.avi'));
            curveVideo = VideoWriter(strrep(cfg.comparisonCurveVideoName, '.mp4', '.avi'));
        end
        mapVideo.FrameRate = 12; curveVideo.FrameRate = 12;
        open(mapVideo); open(curveVideo);
    end

    for k = 1:maxStep
        oldCovered = observeStep(oldCovered, oldResults, k, islandMask, params);
        newCovered = observeStep(newCovered, newResults, k, islandMask, params);

        if mod(k, stride) == 0 || k == 1 || k == maxStep
            oldViz = updateMapPanel(oldViz, oldCovered, islandMask, oldResults, k, params, colors, '原算法');
            newViz = updateMapPanel(newViz, newCovered, islandMask, newResults, k, params, colors, '最大熵-信息素算法');
            tNow = (0:k) * params.dt;
            set(hNewCurve, 'XData', tNow, 'YData', 100*newResults.coverageHist(1:k+1));
            set(hOldCurve, 'XData', tNow, 'YData', 100*oldResults.coverageHist(1:k+1));
            drawnow;
            if pauseTime > 0, pause(pauseTime); end
            if ~isempty(mapVideo)
                writeVideo(mapVideo, getframe(mapFig));
                writeVideo(curveVideo, getframe(curveFig));
            end
        end
    end

    if ~isempty(mapVideo)
        close(mapVideo); close(curveVideo);
    end
    saveFigureLocal(mapFig, fullfile(cfg.compareOutputDir, 'figure_00_dynamic_tracks_comparison_final.png'));
    saveFigureLocal(curveFig, fullfile(cfg.compareOutputDir, 'figure_00_dynamic_coverage_curve_final.png'));
end

function viz = initMapPanel(ax, covered, islandMask, xGrid, yGrid, results, step, params, colors, algName)
    axes(ax); %#ok<LAXES>
    viz.ax = ax;
    viz.hImg = image(ax, [xGrid(1), xGrid(end)], [yGrid(1), yGrid(end)], buildCoverageRGBLocal(islandMask, covered));
    set(ax, 'YDir', 'normal'); hold(ax, 'on'); axis(ax, 'equal');
    xlim(ax, [0, params.mapLenKm]); ylim(ax, [0, params.mapLenKm]);
    grid(ax, 'on'); box(ax, 'on');
    xlabel(ax, 'X/km'); ylabel(ax, 'Y/km');

    nUAV = size(results.uavTrail, 2);
    nUSV = size(results.usvTrail, 2);
    viz.hUAVLines = gobjects(nUAV, 1);
    viz.hUAVMarkers = gobjects(nUAV, 1);
    viz.hUSVLines = gobjects(nUSV, 1);
    viz.hUSVMarkers = gobjects(nUSV, 1);
    viz.hCommCircles = gobjects(nUAV, 1);
    viz.hCommLinks = gobjects(0, 1);

    for i = 1:nUAV
        xi = squeeze(results.uavTrail(1:step+1, i, 1));
        yi = squeeze(results.uavTrail(1:step+1, i, 2));
        viz.hUAVLines(i) = plot(ax, xi, yi, '-', 'Color', colors.uav(i,:), 'LineWidth', 1.4);
        conn = isUAVConnected(results, step, i);
        faceColor = colors.uav(i,:);
        if conn, faceColor = colors.connected; end
        viz.hCommCircles(i) = rectangle(ax, 'Position', [xi(end)-params.commRangeKm, yi(end)-params.commRangeKm, 2*params.commRangeKm, 2*params.commRangeKm], ...
            'Curvature', [1, 1], 'EdgeColor', colors.uav(i,:), 'LineStyle', ':', 'LineWidth', 1.0);
        viz.hUAVMarkers(i) = plot(ax, xi(end), yi(end), 'o', 'MarkerSize', 7, 'MarkerFaceColor', faceColor, 'MarkerEdgeColor', faceColor);
    end

    for j = 1:nUSV
        xj = squeeze(results.usvTrail(1:step+1, j, 1));
        yj = squeeze(results.usvTrail(1:step+1, j, 2));
        viz.hUSVLines(j) = plot(ax, xj, yj, '--', 'Color', colors.usv(1+mod(j-1,size(colors.usv,1)),:), 'LineWidth', 1.4);
        viz.hUSVMarkers(j) = plot(ax, xj(end), yj(end), '^', 'MarkerSize', 7, 'MarkerFaceColor', colors.usv(1+mod(j-1,size(colors.usv,1)),:), 'MarkerEdgeColor', colors.usv(1+mod(j-1,size(colors.usv,1)),:));
    end
    viz = updateCommLinks(viz, results, step, params);
    title(ax, makeMapTitle(algName, results, step, params), 'FontSize', 12);
end

function viz = updateMapPanel(viz, covered, islandMask, results, step, params, colors, algName)
    set(viz.hImg, 'CData', buildCoverageRGBLocal(islandMask, covered));
    nUAV = size(results.uavTrail, 2);
    nUSV = size(results.usvTrail, 2);
    for i = 1:nUAV
        xi = squeeze(results.uavTrail(1:step+1, i, 1));
        yi = squeeze(results.uavTrail(1:step+1, i, 2));
        set(viz.hUAVLines(i), 'XData', xi, 'YData', yi);
        conn = isUAVConnected(results, step, i);
        faceColor = colors.uav(i,:);
        if conn, faceColor = colors.connected; end
        set(viz.hCommCircles(i), 'Position', [xi(end)-params.commRangeKm, yi(end)-params.commRangeKm, 2*params.commRangeKm, 2*params.commRangeKm]);
        set(viz.hUAVMarkers(i), 'XData', xi(end), 'YData', yi(end), 'MarkerFaceColor', faceColor, 'MarkerEdgeColor', faceColor);
    end
    for j = 1:nUSV
        xj = squeeze(results.usvTrail(1:step+1, j, 1));
        yj = squeeze(results.usvTrail(1:step+1, j, 2));
        set(viz.hUSVLines(j), 'XData', xj, 'YData', yj);
        set(viz.hUSVMarkers(j), 'XData', xj(end), 'YData', yj(end));
    end
    viz = updateCommLinks(viz, results, step, params);
    title(viz.ax, makeMapTitle(algName, results, step, params), 'FontSize', 12);
end

function viz = updateCommLinks(viz, results, step, params)
    if isfield(viz, 'hCommLinks') && ~isempty(viz.hCommLinks)
        delete(viz.hCommLinks(ishandle(viz.hCommLinks)));
    end
    ax = viz.ax;
    uavPos = squeeze(results.uavTrail(step+1, :, :));
    usvPos = squeeze(results.usvTrail(step+1, :, :));
    if size(uavPos, 2) ~= 2, uavPos = uavPos'; end
    if size(usvPos, 2) ~= 2, usvPos = usvPos'; end
    h = gobjects(0,1);
    for i = 1:size(uavPos,1)
        for j = i+1:size(uavPos,1)
            if norm(uavPos(i,:) - uavPos(j,:)) <= params.commRangeKm
                h(end+1,1) = plot(ax, [uavPos(i,1), uavPos(j,1)], [uavPos(i,2), uavPos(j,2)], '-', 'Color', [0.10 0.65 0.10], 'LineWidth', 1.0); %#ok<AGROW>
            end
        end
        for m = 1:size(usvPos,1)
            if norm(uavPos(i,:) - usvPos(m,:)) <= params.commRangeKm
                h(end+1,1) = plot(ax, [uavPos(i,1), usvPos(m,1)], [uavPos(i,2), usvPos(m,2)], '-', 'Color', [0.10 0.65 0.10], 'LineWidth', 1.0); %#ok<AGROW>
            end
        end
    end
    viz.hCommLinks = h;
end

function titleStr = makeMapTitle(algName, results, step, params)
    connCount = 0;
    if isfield(results, 'uavConnectedHist') && step+1 <= size(results.uavConnectedHist,1)
        connCount = sum(results.uavConnectedHist(step+1,:));
    elseif isfield(results, 'connectedAnyCountHist') && step+1 <= numel(results.connectedAnyCountHist)
        connCount = results.connectedAnyCountHist(step+1);
    end
    cov = 100 * results.coverageHist(min(step+1, numel(results.coverageHist)));
    rep = 100 * results.repeatRateHist(min(step+1, numel(results.repeatRateHist)));
    titleStr = sprintf('%s | 步长 %d | 时间 %.0f s | 覆盖率 %.2f%% | 重复率 %.2f%% | 接入无人艇网络的无人机数 %d', ...
        algName, step, step*params.dt, cov, rep, connCount);
end

function conn = isUAVConnected(results, step, i)
    conn = false;
    if isfield(results, 'uavConnectedHist') && step+1 <= size(results.uavConnectedHist,1) && i <= size(results.uavConnectedHist,2)
        conn = results.uavConnectedHist(step+1, i);
    end
end

function covered = observeInitial(covered, results, islandMask, params)
    for i = 1:size(results.uavTrail, 2)
        pos = squeeze(results.uavTrail(1, i, :))';
        covered = applyObservation(pos, pos, covered, islandMask, params, 'uav');
    end
    for j = 1:size(results.usvTrail, 2)
        pos = squeeze(results.usvTrail(1, j, :))';
        covered = applyObservation(pos, pos, covered, islandMask, params, 'usv');
    end
end

function covered = observeStep(covered, results, k, islandMask, params)
    for i = 1:size(results.uavTrail, 2)
        pos0 = squeeze(results.uavTrail(k, i, :))';
        pos1 = squeeze(results.uavTrail(k+1, i, :))';
        covered = applyObservation(pos0, pos1, covered, islandMask, params, 'uav');
    end
    for j = 1:size(results.usvTrail, 2)
        pos0 = squeeze(results.usvTrail(k, j, :))';
        pos1 = squeeze(results.usvTrail(k+1, j, :))';
        covered = applyObservation(pos0, pos1, covered, islandMask, params, 'usv');
    end
end

function covered = applyObservation(pos0, pos1, covered, islandMask, params, platformType)
    if strcmpi(platformType, 'uav')
        widthKm = params.sensorStripWidthUAVKm;
    else
        widthKm = params.sensorStripWidthUSVKm;
    end
    [r1, r2, c1, c2, stripMask] = getStripMaskLocal(pos0, pos1, widthKm, params);
    if isempty(stripMask), return; end
    islandLocal = islandMask(r1:r2, c1:c2);
    if strcmpi(platformType, 'uav')
        validMask = stripMask;
    else
        validMask = stripMask & (~islandLocal);
    end
    localCovered = covered(r1:r2, c1:c2);
    localCovered(validMask) = true;
    covered(r1:r2, c1:c2) = localCovered;
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
    cols = c1:c2; rows = r1:r2;
    if isempty(rows) || isempty(cols)
        stripMask = false(0, 0); return;
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
        dist = hypot(X - A(1), Y - A(2)); return;
    end
    t = ((X - A(1)).*AB(1) + (Y - A(2)).*AB(2)) / denom;
    t = min(max(t, 0), 1);
    projX = A(1) + t .* AB(1);
    projY = A(2) + t .* AB(2);
    dist = hypot(X - projX, Y - projY);
end

function rgb = buildCoverageRGBLocal(islandMask, coveredGlobal)
    seaCovered = coveredGlobal & ~islandMask;
    islandCovered = coveredGlobal & islandMask;
    rgb = zeros([size(islandMask), 3]);
    rgb(:, :, 1) = 0.78 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
    rgb(:, :, 2) = 0.90 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
    rgb(:, :, 3) = 1.00 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
end

function val = getFieldOrDefault(s, name, defaultVal)
    if isfield(s, name) && ~isempty(s.(name))
        val = s.(name);
    else
        val = defaultVal;
    end
end

function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
end
