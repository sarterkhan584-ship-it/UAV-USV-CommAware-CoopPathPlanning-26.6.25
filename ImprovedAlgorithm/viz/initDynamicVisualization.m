function viz = initDynamicVisualization(islandMask, coveredGlobal, x, y, uavTrailNow, usvTrailNow, coverageNow, seaCoverageNow, islandCoverageNow, repeatNow, connectedAnyCountNow, connFlagsNow, params)
    viz.fig = figure('Color', 'w', 'Position', [60, 60, 1450, 720], 'Name', '动态可视化：航迹/覆盖率/重复搜索率');
    tl = tiledlayout(viz.fig, 1, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

    viz.axMap = nexttile(tl, 1);
    rgb = buildCoverageRGB(islandMask, coveredGlobal);
    viz.hImg = image(viz.axMap, [x(1), x(end)], [y(1), y(end)], rgb);
    set(viz.axMap, 'YDir', 'normal');
    hold(viz.axMap, 'on');
    axis(viz.axMap, 'equal');
    xlim(viz.axMap, [0, params.mapLenKm]);
    ylim(viz.axMap, [0, params.mapLenKm]);
    grid(viz.axMap, 'on'); box(viz.axMap, 'on');
    xlabel(viz.axMap, 'X/km'); ylabel(viz.axMap, 'Y/km');

    viz.uavColor = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    viz.usvColor = [0.00 0.40 0.95; 0.00 0.75 0.85; 0.25 0.25 0.25];

    nUAV = size(uavTrailNow, 2);
    nUSV = size(usvTrailNow, 2);
    viz.hUAVLines = gobjects(nUAV, 1);
    viz.hUAVMarkers = gobjects(nUAV, 1);
    viz.hUSVLines = gobjects(nUSV, 1);
    viz.hUSVMarkers = gobjects(nUSV, 1);
    viz.hCommCircles = gobjects(nUAV, 1);

    for i = 1:nUAV
        xi = squeeze(uavTrailNow(:, i, 1)); yi = squeeze(uavTrailNow(:, i, 2));
        viz.hUAVLines(i) = plot(viz.axMap, xi, yi, '-', 'Color', viz.uavColor(i, :), 'LineWidth', 1.6);
        faceColor = viz.uavColor(i, :);
        if connFlagsNow(i)
            faceColor = params.connectedUAVColor;
        end
        % 通信圆以无人机为圆心，半径为无人机短距通信范围。
        viz.hCommCircles(i) = rectangle(viz.axMap, 'Position', [xi(end)-params.commRangeKm, yi(end)-params.commRangeKm, 2*params.commRangeKm, 2*params.commRangeKm], ...
            'Curvature', [1, 1], 'EdgeColor', viz.uavColor(i, :), 'LineStyle', ':', 'LineWidth', 1.0);
        viz.hUAVMarkers(i) = plot(viz.axMap, xi(end), yi(end), 'o', 'MarkerSize', 8, ...
            'MarkerFaceColor', faceColor, 'MarkerEdgeColor', faceColor, 'LineWidth', 1.0);
    end

    for j = 1:nUSV
        xj = squeeze(usvTrailNow(:, j, 1)); yj = squeeze(usvTrailNow(:, j, 2));
        viz.hUSVLines(j) = plot(viz.axMap, xj, yj, '--', 'Color', viz.usvColor(j, :), 'LineWidth', 1.6);
        viz.hUSVMarkers(j) = plot(viz.axMap, xj(end), yj(end), '^', 'MarkerSize', 8, ...
            'MarkerFaceColor', viz.usvColor(j, :), 'MarkerEdgeColor', viz.usvColor(j, :), 'LineWidth', 1.0);
    end

    title(viz.axMap, sprintf('动态搜索航迹 | 当前接入无人艇网络的无人机数: %d', connectedAnyCountNow), 'FontSize', 12);

    viz.axCurve = nexttile(tl, 2);
    hold(viz.axCurve, 'on'); grid(viz.axCurve, 'on'); box(viz.axCurve, 'on');
    xlabel(viz.axCurve, '时间/s'); ylabel(viz.axCurve, '比例/%');
    xlim(viz.axCurve, [0, params.maxTime]); ylim(viz.axCurve, [0, 100]);
    viz.hCovAll = plot(viz.axCurve, 0, 100*coverageNow, 'k-', 'LineWidth', 2.2);
    viz.hCovSea = plot(viz.axCurve, 0, 100*seaCoverageNow, '--', 'Color', [0.00 0.45 0.80], 'LineWidth', 1.6);
    viz.hCovIsland = plot(viz.axCurve, 0, 100*islandCoverageNow, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6);
    viz.hRepeat = plot(viz.axCurve, 0, 100*repeatNow, ':', 'Color', [0.50 0.00 0.50], 'LineWidth', 1.8);
    viz.hTarget = plot(viz.axCurve, [0, params.maxTime], 100*params.targetCoverage*[1,1], '-.', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
    legend(viz.axCurve, {'全地图覆盖率', '海面覆盖率', '岛屿覆盖率', '重复搜索率', '90%终止阈值'}, 'Location', 'southeast', 'FontSize', 10);
    viz.hCurveTitle = title(viz.axCurve, '覆盖率与重复搜索率动态变化', 'FontSize', 12);

    viz.hStatusText = annotation(viz.fig, 'textbox', [0.42 0.92 0.22 0.06], 'String', '步数 0 | 时间 0 s', ...
        'FitBoxToText', 'on', 'BackgroundColor', 'w', 'EdgeColor', [0.7 0.7 0.7]);

    viz.videoWriter = [];
    if params.saveAnimationVideo && exist('VideoWriter', 'class') == 8
        try
            viz.videoWriter = VideoWriter(params.animationVideoName, 'MPEG-4');
        catch
            viz.videoWriter = VideoWriter(strrep(params.animationVideoName, '.mp4', '.avi'));
        end
        viz.videoWriter.FrameRate = params.animationFrameRate;
        open(viz.videoWriter);
        frame = getframe(viz.fig);
        writeVideo(viz.videoWriter, frame);
    end
    drawnow;
end
