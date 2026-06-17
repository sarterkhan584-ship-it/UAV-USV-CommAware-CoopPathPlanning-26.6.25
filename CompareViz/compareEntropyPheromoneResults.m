function comparison = compareEntropyPheromoneResults(oldResults, newResults, params, mapData, cfg)
% compareEntropyPheromoneResults 生成类似 Drones 论文风格的多指标对比图。

    outDir = cfg.compareOutputDir;
    islandMask = mapData.islandMask;
    xGrid = mapData.xGrid;
    yGrid = mapData.yGrid;

    oldReplay = replaySearchMetrics(oldResults, islandMask, params, cfg.snapshotSteps);
    newReplay = replaySearchMetrics(newResults, islandMask, params, cfg.snapshotSteps);

    comparison.oldReplay = oldReplay;
    comparison.newReplay = newReplay;
    comparison.threshold.oldStep = findFirstReach(oldResults.coverageHist, cfg.coverageThreshold);
    comparison.threshold.newStep = findFirstReach(newResults.coverageHist, cfg.coverageThreshold);
    comparison.threshold.oldTimeMin = stepToMinute(comparison.threshold.oldStep, params);
    comparison.threshold.newTimeMin = stepToMinute(comparison.threshold.newStep, params);

    plotEntropyConvergence(params, outDir);
    plotCoverageRateChange(oldResults, newResults, params, outDir);
    replayComparisonAnimation(oldResults, newResults, params, mapData, cfg);
    plotCoverageSnapshots(oldReplay, newReplay, oldResults, newResults, islandMask, xGrid, yGrid, params, cfg, outDir);
    plotThresholdDuration(oldResults, newResults, params, cfg, outDir);
    plotRepeatRateChange(oldResults, newResults, params, cfg, outDir);
    plotRepeatedGridCounts(oldReplay.visitCount, newReplay.visitCount, cfg, outDir);
end

function idx = findFirstReach(series, threshold)
    idx = find(series >= threshold, 1, 'first');
    if isempty(idx)
        idx = NaN;
    else
        idx = idx - 1;
    end
end

function tMin = stepToMinute(step, params)
    if isnan(step)
        tMin = NaN;
    else
        tMin = step * params.dt / 60;
    end
end

function plotEntropyConvergence(params, outDir)
    Nk = 0:10;
    h = exp(-params.entropyAlpha * Nk);
    fig = figure('Color','w','Position',[120 120 660 470]);
    plot(Nk, h, '-s', 'LineWidth', 1.8, 'MarkerSize', 7, 'MarkerFaceColor', 'w');
    grid on; box on;
    xlabel('重复探测次数 N_k', 'FontSize', 12);
    ylabel('信息熵 h_{i,j}', 'FontSize', 12);
    title('熵收敛曲线', 'FontSize', 13);
    ylim([0 1.02]); xlim([0 max(Nk)]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_01_entropy_convergence.png'));
end

function plotCoverageRateChange(oldResults, newResults, params, outDir)
    oldCov = oldResults.coverageHist(:);
    newCov = newResults.coverageHist(:);
    n = min(numel(oldCov), numel(newCov));
    t = (0:n-1) * params.dt / 60;
    fig = figure('Color','w','Position',[120 120 720 520]);
    plot(t, 100*newCov(1:n), '-d', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(n), 'MarkerSize', 6); hold on;
    plot(t, 100*oldCov(1:n), '-o', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(n), 'MarkerSize', 6);
    grid on; box on;
    xlabel('时间/min', 'FontSize', 12);
    ylabel('覆盖率/%', 'FontSize', 12);
    title('覆盖率变化曲线', 'FontSize', 13);
    legend({'最大熵-信息素算法', '原算法'}, 'Location', 'northwest');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_02_coverage_rate_change.png'));
end

function plotCoverageSnapshots(oldReplay, newReplay, oldResults, newResults, islandMask, xGrid, yGrid, params, cfg, outDir)
    steps = cfg.snapshotSteps;
    for r = 1:numel(steps)
        step = steps(r);
        oldCov = oldReplay.snapshots{r};
        newCov = newReplay.snapshots{r};

        figOld = figure('Color','w','Position',[100 80 820 720]);
        drawSnapshot(oldCov, islandMask, xGrid, yGrid, oldResults, step, params);
        title(sprintf('原算法环境覆盖图，步长 K = %d', step), 'FontSize', 13);
        saveFigureLocal(figOld, fullfile(outDir, sprintf('figure_03_%04d_old_environment_coverage.png', step)));

        figNew = figure('Color','w','Position',[120 100 820 720]);
        drawSnapshot(newCov, islandMask, xGrid, yGrid, newResults, step, params);
        title(sprintf('最大熵-信息素算法环境覆盖图，步长 K = %d', step), 'FontSize', 13);
        saveFigureLocal(figNew, fullfile(outDir, sprintf('figure_03_%04d_entropy_pheromone_environment_coverage.png', step)));
    end
end

function drawSnapshot(covered, islandMask, xGrid, yGrid, results, step, params)
    seaCovered = covered & ~islandMask;
    islandCovered = covered & islandMask;
    rgb = zeros([size(covered), 3]);
    rgb(:,:,1) = 0.78 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~covered & islandMask) + 0.55 * islandCovered;
    rgb(:,:,2) = 0.90 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~covered & islandMask) + 0.55 * islandCovered;
    rgb(:,:,3) = 1.00 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~covered & islandMask) + 0.55 * islandCovered;
    image([xGrid(1) xGrid(end)], [yGrid(1) yGrid(end)], rgb);
    set(gca, 'YDir', 'normal'); axis equal tight; box on; grid on; hold on;
    xlim([0 params.mapLenKm]); ylim([0 params.mapLenKm]);
    xlabel('X/km'); ylabel('Y/km');

    nTrail = min(step + 1, size(results.uavTrail, 1));
    uavColor = lines(size(results.uavTrail, 2));
    usvColor = [0 0.45 0.95; 0 0.75 0.85; 0.25 0.25 0.25];
    for i = 1:size(results.uavTrail, 2)
        xi = squeeze(results.uavTrail(1:nTrail, i, 1));
        yi = squeeze(results.uavTrail(1:nTrail, i, 2));
        plot(xi, yi, '-', 'LineWidth', 1.1, 'Color', uavColor(i,:));
    end
    if isfield(results, 'usvTrail')
        for j = 1:size(results.usvTrail, 2)
            xj = squeeze(results.usvTrail(1:nTrail, j, 1));
            yj = squeeze(results.usvTrail(1:nTrail, j, 2));
            plot(xj, yj, '--', 'LineWidth', 1.1, 'Color', usvColor(1+mod(j-1,size(usvColor,1)),:));
        end
    end
end

function plotThresholdDuration(oldResults, newResults, params, cfg, outDir)
    oldCov = oldResults.coverageHist(:);
    newCov = newResults.coverageHist(:);
    n = min(numel(oldCov), numel(newCov));
    t = (0:n-1) * params.dt / 60;
    fig = figure('Color','w','Position',[120 120 720 520]);
    plot(t, 100*newCov(1:n), '-d', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(n)); hold on;
    plot(t, 100*oldCov(1:n), '-o', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(n));
    yline(100*cfg.coverageThreshold, '--', 'LineWidth', 1.6, 'Color', [0.45 0.45 0.45]);
    oldStep = findFirstReach(oldCov, cfg.coverageThreshold);
    newStep = findFirstReach(newCov, cfg.coverageThreshold);
    if ~isnan(newStep)
        xline(newStep*params.dt/60, 'r--', 'LineWidth', 1.2);
    end
    if ~isnan(oldStep)
        xline(oldStep*params.dt/60, 'r:', 'LineWidth', 1.4);
    end
    grid on; box on;
    xlabel('时间/min', 'FontSize', 12);
    ylabel('覆盖率/%', 'FontSize', 12);
    title('达到覆盖阈值时间对比', 'FontSize', 13);
    legend({'最大熵-信息素算法', '原算法', sprintf('%.0f%%覆盖阈值', 100*cfg.coverageThreshold)}, 'Location', 'northwest');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_04_threshold_duration.png'));
end

function plotRepeatRateChange(oldResults, newResults, params, cfg, outDir)
    oldR = oldResults.repeatRateHist(:);
    newR = newResults.repeatRateHist(:);
    n = min(numel(oldR), numel(newR));
    t = (0:n-1) * params.dt / 60;
    fig = figure('Color','w','Position',[120 120 720 520]);
    plot(t, 100*newR(1:n), '-d', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(n)); hold on;
    plot(t, 100*oldR(1:n), '-o', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(n));
    for q = 1:numel(cfg.repeatThresholds)
        yline(100*cfg.repeatThresholds(q), '--', 'Color', [0.50 0.50 0.50], 'LineWidth', 1.2);
    end
    grid on; box on;
    xlabel('时间/min', 'FontSize', 12);
    ylabel('重复覆盖率/%', 'FontSize', 12);
    title('重复覆盖率对比曲线', 'FontSize', 13);
    legend({'最大熵-信息素算法', '原算法'}, 'Location', 'northwest');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_05_repetitive_detection_rate.png'));
end

function plotRepeatedGridCounts(oldVisit, newVisit, cfg, outDir)
    x = 1:cfg.maxRepeatDetection;
    yOld = zeros(size(x));
    yNew = zeros(size(x));
    for i = 1:numel(x)
        yOld(i) = nnz(oldVisit >= x(i));
        yNew(i) = nnz(newVisit >= x(i));
    end
    fig = figure('Color','w','Position',[120 120 720 520]);
    plot(x, yNew, '-d', 'LineWidth', 1.8, 'MarkerSize', 6); hold on;
    plot(x, yOld, '-o', 'LineWidth', 1.6, 'MarkerSize', 6);
    grid on; box on;
    xlabel('重复探测次数', 'FontSize', 12);
    ylabel('重复探测网格数量', 'FontSize', 12);
    title('重复探测网格数量对比', 'FontSize', 13);
    legend({'最大熵-信息素算法', '原算法'}, 'Location', 'northeast');
    xlim([x(1), x(end)]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_06_repeated_grid_counts.png'));
end

function idx = markerIdx(n)
    step = max(1, floor(n / 12));
    idx = 1:step:n;
end

function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
end
