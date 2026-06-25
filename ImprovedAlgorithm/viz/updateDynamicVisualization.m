function viz = updateDynamicVisualization(viz, islandMask, coveredGlobal, x, y, uavTrailNow, usvTrailNow, coverageHistNow, seaCoverageHistNow, islandCoverageHistNow, repeatRateHistNow, connectedAnyCountNow, connFlagsNow, stepNow, params)
    rgb = buildCoverageRGB(islandMask, coveredGlobal);
    set(viz.hImg, 'CData', rgb);

    nUAV = size(uavTrailNow, 2);
    nUSV = size(usvTrailNow, 2);
    for i = 1:nUAV
        xi = squeeze(uavTrailNow(:, i, 1)); yi = squeeze(uavTrailNow(:, i, 2));
        set(viz.hUAVLines(i), 'XData', xi, 'YData', yi);
        faceColor = viz.uavColor(i, :);
        if connFlagsNow(i)
            faceColor = params.connectedUAVColor;
        end
        set(viz.hCommCircles(i), 'Position', [xi(end)-params.commRangeKm, yi(end)-params.commRangeKm, 2*params.commRangeKm, 2*params.commRangeKm]);
        set(viz.hUAVMarkers(i), 'XData', xi(end), 'YData', yi(end), 'MarkerFaceColor', faceColor, 'MarkerEdgeColor', faceColor);
    end
    for j = 1:nUSV
        xj = squeeze(usvTrailNow(:, j, 1)); yj = squeeze(usvTrailNow(:, j, 2));
        set(viz.hUSVLines(j), 'XData', xj, 'YData', yj);
        set(viz.hUSVMarkers(j), 'XData', xj(end), 'YData', yj(end));
    end

    tNow = (0:numel(coverageHistNow)-1) * params.dt;
    set(viz.hCovAll, 'XData', tNow, 'YData', 100*coverageHistNow);
    set(viz.hCovSea, 'XData', tNow, 'YData', 100*seaCoverageHistNow);
    set(viz.hCovIsland, 'XData', tNow, 'YData', 100*islandCoverageHistNow);
    set(viz.hRepeat, 'XData', tNow, 'YData', 100*repeatRateHistNow);

    title(viz.axMap, sprintf('动态搜索航迹 | 当前接入无人艇网络的无人机数: %d', connectedAnyCountNow), 'FontSize', 12);
    set(viz.hStatusText, 'String', sprintf('步数 %d | 时间 %.0f s | 全图覆盖率 %.2f%% | 重复搜索率 %.2f%%', ...
        stepNow, stepNow*params.dt, 100*coverageHistNow(end), 100*repeatRateHistNow(end)));

    drawnow;
    if params.animationPause > 0
        pause(params.animationPause);
    end

    if ~isempty(viz.videoWriter)
        frame = getframe(viz.fig);
        writeVideo(viz.videoWriter, frame);
    end
end
