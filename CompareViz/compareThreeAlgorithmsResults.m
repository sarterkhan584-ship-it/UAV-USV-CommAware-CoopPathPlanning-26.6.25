function comparison = compareThreeAlgorithmsResults( ...
        oldResults, newResults, terrainResults, params, mapData, cfg)
% compareThreeAlgorithmsResults 生成三算法多指标对比图。
% 对比维度：覆盖率、重复率、通信质量、环境覆盖快照。
% 所有图中文标注，输出至 CompareResults。

    outDir = cfg.compareOutputDir;
    islandMask = mapData.islandMask;
    xGrid = mapData.xGrid;
    yGrid = mapData.yGrid;

    % 回放数据结构（用于快照）
    oldReplay = replaySearchMetrics(oldResults, islandMask, params, cfg.snapshotSteps);
    newReplay = replaySearchMetrics(newResults, islandMask, params, cfg.snapshotSteps);
    terrainReplay = replaySearchMetrics(terrainResults, islandMask, params, cfg.snapshotSteps);

    comparison.oldReplay = oldReplay;
    comparison.newReplay = newReplay;
    comparison.terrainReplay = terrainReplay;

    % 达到覆盖阈值时间
    comparison.threshold.oldStep = findFirstReach(oldResults.coverageHist, cfg.coverageThreshold);
    comparison.threshold.newStep = findFirstReach(newResults.coverageHist, cfg.coverageThreshold);
    comparison.threshold.terrainStep = findFirstReach(terrainResults.coverageHist, cfg.coverageThreshold);
    comparison.threshold.oldTimeMin = stepToMinute(comparison.threshold.oldStep, params);
    comparison.threshold.newTimeMin = stepToMinute(comparison.threshold.newStep, params);
    comparison.threshold.terrainTimeMin = stepToMinute(comparison.threshold.terrainStep, params);

    % ---------- 生成所有对比图 ----------
    plotCoverageRateChange3(terrainResults, newResults, oldResults, params, outDir);
    plotRepeatRateChange3(terrainResults, newResults, oldResults, params, cfg, outDir);
    plotCommunicationQuality(terrainResults, newResults, oldResults, params, outDir);
    plotLosRatioComparison(terrainResults, newResults, oldResults, params, outDir);
    plotBlockedRatioComparison(terrainResults, newResults, oldResults, params, outDir);
    plotCoverageSnapshots3(oldReplay, newReplay, terrainReplay, oldResults, newResults, terrainResults, islandMask, xGrid, yGrid, params, cfg, outDir);
    plotThresholdDuration3(terrainResults, newResults, oldResults, params, cfg, outDir);
    plotRepeatedGridCounts3(terrainReplay.visitCount, newReplay.visitCount, oldReplay.visitCount, outDir);

    % 动态回放
    replayThreeComparisonAnimation(terrainResults, newResults, oldResults, params, mapData, cfg);

    % 打印报告
    printComparisonReport(terrainResults, newResults, oldResults, params, cfg, outDir);
end

% ==================== 辅助函数 ====================

function idx = findFirstReach(series, threshold)
    idx = find(series >= threshold, 1, 'first');
    if isempty(idx), idx = NaN; else idx = idx - 1; end
end

function tMin = stepToMinute(step, params)
    if isnan(step), tMin = NaN; else tMin = step * params.dt / 60; end
end

function idx = markerIdx(n)
    step = max(1, floor(n / 12));
    idx = 1:step:n;
end

% ==================== 覆盖率变化图 ====================
function plotCoverageRateChange3(terrainResults, newResults, oldResults, params, outDir)
    tCov = terrainResults.coverageHist(:);
    nCov = newResults.coverageHist(:);
    oCov = oldResults.coverageHist(:);
    n = min([numel(tCov), numel(nCov), numel(oCov)]);
    tSteps = (0:n-1) * params.dt / 60;
    fig = figure('Color','w','Position',[120 120 800 560]);
    plot(tSteps, 100*tCov(1:n), '-s', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(n), 'MarkerSize', 6); hold on;
    plot(tSteps, 100*nCov(1:n), '-d', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(n), 'MarkerSize', 6);
    plot(tSteps, 100*oCov(1:n), '-o', 'LineWidth', 1.4, 'MarkerIndices', markerIdx(n), 'MarkerSize', 6);
    grid on; box on;
    xlabel('时间/min', 'FontSize', 12);
    ylabel('覆盖率/%', 'FontSize', 12);
    title('三算法覆盖率变化曲线', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法', '原算法'}, 'Location', 'southeast');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_02_coverage_rate_change.png'));
end

% ==================== 重复率对比图 ====================
function plotRepeatRateChange3(terrainResults, newResults, oldResults, params, cfg, outDir)
    tR = terrainResults.repeatRateHist(:);
    nR = newResults.repeatRateHist(:);
    oR = oldResults.repeatRateHist(:);
    n = min([numel(tR), numel(nR), numel(oR)]);
    tSteps = (0:n-1) * params.dt / 60;
    fig = figure('Color','w','Position',[120 120 800 560]);
    plot(tSteps, 100*tR(1:n), '-s', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(n)); hold on;
    plot(tSteps, 100*nR(1:n), '-d', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(n));
    plot(tSteps, 100*oR(1:n), '-o', 'LineWidth', 1.4, 'MarkerIndices', markerIdx(n));
    for q = 1:numel(cfg.repeatThresholds)
        yline(100*cfg.repeatThresholds(q), '--', 'Color', [0.50 0.50 0.50], 'LineWidth', 1.0);
    end
    grid on; box on;
    xlabel('时间/min', 'FontSize', 12);
    ylabel('重复覆盖率/%', 'FontSize', 12);
    title('重复覆盖率对比曲线', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法', '原算法'}, 'Location', 'northwest');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_05_repetitive_detection_rate.png'));
end

% ==================== 通信质量对比图（平均链路质量） ====================
function plotCommunicationQuality(terrainResults, newResults, oldResults, params, outDir)
%  三算法平均通信质量对比。3D地形版有遮挡损失，2D版质量仅距离衰减。
    fig = figure('Color','w','Position',[120 120 800 560]);
    hold on; grid on; box on;

    % 3D地形算法
    if isfield(terrainResults, 'meanLinkQualityHist')
        tQ = terrainResults.meanLinkQualityHist(:);
        nT = min(numel(tQ), params.maxSteps+1);
        tSteps = (0:nT-1) * params.dt / 60;
        plot(tSteps, tQ(1:nT), '-s', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(nT), 'MarkerSize', 6);
    end

    % 最大熵-信息素算法（2D距离衰减）
    if isfield(newResults, 'meanLinkQualityHist')
        nQ = newResults.meanLinkQualityHist(:);
        nN = min(numel(nQ), params.maxSteps+1);
        tStepsN = (0:nN-1) * params.dt / 60;
        plot(tStepsN, nQ(1:nN), '-d', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(nN), 'MarkerSize', 6);
    end

    % 原算法（2D距离衰减）
    if isfield(oldResults, 'meanLinkQualityHist')
        oQ = oldResults.meanLinkQualityHist(:);
        oN = min(numel(oQ), params.maxSteps+1);
        tStepsO = (0:oN-1) * params.dt / 60;
        plot(tStepsO, oQ(1:oN), '-o', 'LineWidth', 1.4, 'MarkerIndices', markerIdx(oN), 'MarkerSize', 6);
    end

    xlabel('时间/min', 'FontSize', 12);
    ylabel('平均通信质量', 'FontSize', 12);
    title('通信质量对比曲线', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法', '原算法'}, 'Location', 'southeast');
    ylim([0 1.05]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_00_communication_quality_comparison.png'));
end

% ==================== LoS视距率对比图 ====================
function plotLosRatioComparison(terrainResults, newResults, oldResults, params, outDir)
%  LoS视距率对比：3D地形有遮挡，2D版恒为100%。
    fig = figure('Color','w','Position',[120 120 800 560]);
    hold on; grid on; box on;

    % 3D地形算法
    if isfield(terrainResults, 'losRatioHist')
        tL = terrainResults.losRatioHist(:);
        nT = min(numel(tL), params.maxSteps+1);
        tSteps = (0:nT-1) * params.dt / 60;
        plot(tSteps, 100*tL(1:nT), '-s', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(nT), 'MarkerSize', 6);
    end

    % 最大熵-信息素算法：使用真实losRatioHist（2D恒为100%）
    if isfield(newResults, 'losRatioHist')
        nL = newResults.losRatioHist(:);
        nN = min(numel(nL), params.maxSteps+1);
        tStepsN = (0:nN-1) * params.dt / 60;
        plot(tStepsN, 100*nL(1:nN), '-d', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(nN), 'MarkerSize', 6);
    end

    % 原算法：使用真实losRatioHist（2D恒为100%）
    if isfield(oldResults, 'losRatioHist')
        oL = oldResults.losRatioHist(:);
        oN = min(numel(oL), params.maxSteps+1);
        tStepsO = (0:oN-1) * params.dt / 60;
        plot(tStepsO, 100*oL(1:oN), '-o', 'LineWidth', 1.4, 'MarkerIndices', markerIdx(oN), 'MarkerSize', 6);
    end

    xlabel('时间/min', 'FontSize', 12);
    ylabel('LoS视距率/%', 'FontSize', 12);
    title('LoS视距率对比曲线', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法(2D)', '原算法(2D)'}, 'Location', 'northeast');
    ylim([0 105]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_01_los_ratio_comparison.png'));
end

% ==================== 环境覆盖快照 ====================
function plotCoverageSnapshots3(oldReplay, newReplay, terrainReplay, ...
        oldResults, newResults, terrainResults, islandMask, xGrid, yGrid, params, cfg, outDir)
    steps = cfg.snapshotSteps;
    names = {'原算法', '最大熵-信息素算法', '3D地形通信算法'};
    replays = {oldReplay, newReplay, terrainReplay};
    allResults = {oldResults, newResults, terrainResults};
    tags = {'old', 'entropy_pheromone', 'terrain_comm'};

    for r = 1:numel(steps)
        step = steps(r);
        for a = 1:3
            cov = replays{a}.snapshots{r};
            fig = figure('Color','w','Position',[100 80 820 720]);
            drawSnapshot(cov, islandMask, xGrid, yGrid, allResults{a}, step, params);
            title(sprintf('%s 环境覆盖图  步长 K = %d', names{a}, step), 'FontSize', 13);
            saveFigureLocal(fig, fullfile(outDir, sprintf('figure_03_%04d_%s_environment_coverage.png', step, tags{a})));
        end
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

% ==================== 覆盖阈值到达时间 ====================
function plotThresholdDuration3(terrainResults, newResults, oldResults, params, cfg, outDir)
    tCov = terrainResults.coverageHist(:);
    nCov = newResults.coverageHist(:);
    oCov = oldResults.coverageHist(:);
    n = min([numel(tCov), numel(nCov), numel(oCov)]);
    tSteps = (0:n-1) * params.dt / 60;
    fig = figure('Color','w','Position',[120 120 800 560]);
    plot(tSteps, 100*tCov(1:n), '-s', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(n)); hold on;
    plot(tSteps, 100*nCov(1:n), '-d', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(n));
    plot(tSteps, 100*oCov(1:n), '-o', 'LineWidth', 1.4, 'MarkerIndices', markerIdx(n));
    yline(100*cfg.coverageThreshold, '--', 'LineWidth', 1.6, 'Color', [0.45 0.45 0.45]);
    tStep = findFirstReach(tCov, cfg.coverageThreshold);
    nStep = findFirstReach(nCov, cfg.coverageThreshold);
    oStep = findFirstReach(oCov, cfg.coverageThreshold);
    if ~isnan(tStep), xline(tStep*params.dt/60, 'r--', 'LineWidth', 1.2); end
    if ~isnan(nStep), xline(nStep*params.dt/60, 'r:', 'LineWidth', 1.2); end
    if ~isnan(oStep), xline(oStep*params.dt/60, 'r-.', 'LineWidth', 1.2); end
    grid on; box on;
    xlabel('时间/min', 'FontSize', 12);
    ylabel('覆盖率/%', 'FontSize', 12);
    title('达到覆盖阈值时间对比', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法', '原算法', sprintf('%.0f%%覆盖阈值', 100*cfg.coverageThreshold)}, 'Location', 'southeast');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_04_threshold_duration.png'));
end

% ==================== 重复探测网格数 ====================
function plotRepeatedGridCounts3(tVisit, nVisit, oVisit, outDir)
    x = 1:18;
    yT = zeros(size(x)); yN = zeros(size(x)); yO = zeros(size(x));
    for i = 1:numel(x)
        yT(i) = nnz(tVisit >= x(i));
        yN(i) = nnz(nVisit >= x(i));
        yO(i) = nnz(oVisit >= x(i));
    end
    fig = figure('Color','w','Position',[120 120 800 560]);
    plot(x, yT, '-s', 'LineWidth', 1.8, 'MarkerSize', 6); hold on;
    plot(x, yN, '-d', 'LineWidth', 1.6, 'MarkerSize', 6);
    plot(x, yO, '-o', 'LineWidth', 1.4, 'MarkerSize', 6);
    grid on; box on;
    xlabel('重复探测次数', 'FontSize', 12);
    ylabel('重复探测网格数量', 'FontSize', 12);
    title('重复探测网格数量对比', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法', '原算法'}, 'Location', 'northeast');
    xlim([x(1), x(end)]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_06_repeated_grid_counts.png'));
end

% ==================== 动态回放（三算法并排） ====================
function replayThreeComparisonAnimation(terrainResults, newResults, oldResults, params, mapData, cfg)
    if ~isfield(cfg, 'enableComparisonAnimation') || ~cfg.enableComparisonAnimation
        return;
    end

    islandMask = mapData.islandMask;
    xGrid = mapData.xGrid;
    yGrid = mapData.yGrid;
    maxStep = min([ ...
        size(terrainResults.uavTrail,1), size(newResults.uavTrail,1), size(oldResults.uavTrail,1), ...
        numel(terrainResults.coverageHist), numel(newResults.coverageHist), numel(oldResults.coverageHist)]) - 1;
    if maxStep < 1, return; end

    stride = getFieldOrDefault(cfg, 'comparisonAnimationStride', 5);
    pauseTime = getFieldOrDefault(cfg, 'comparisonAnimationPause', 0.001);

    tCovered = false(params.N, params.N);
    nCovered = false(params.N, params.N);
    oCovered = false(params.N, params.N);
    tCovered = observeInitial(tCovered, terrainResults, islandMask, params);
    nCovered = observeInitial(nCovered, newResults, islandMask, params);
    oCovered = observeInitial(oCovered, oldResults, islandMask, params);

    colors.uav = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    colors.usv = [0.00 0.40 0.95; 0.00 0.75 0.85; 0.25 0.25 0.25];
    colors.connected = params.connectedUAVColor;

    mapFig = figure('Color','w','Position',[20 40 1800 720], ...
        'Name', '三算法动态航迹对比');
    tl = tiledlayout(mapFig, 1, 3, 'Padding', 'compact', 'TileSpacing', 'compact');
    tViz = initMapPanel(nexttile(tl, 1), tCovered, islandMask, xGrid, yGrid, terrainResults, 0, params, colors, '3D地形通信算法');
    nViz = initMapPanel(nexttile(tl, 2), nCovered, islandMask, xGrid, yGrid, newResults, 0, params, colors, '最大熵-信息素算法');
    oViz = initMapPanel(nexttile(tl, 3), oCovered, islandMask, xGrid, yGrid, oldResults, 0, params, colors, '原算法');
    sgtitle(tl, '三算法无人机/无人艇动态航迹与通信状态对比', 'FontSize', 14, 'FontWeight', 'bold');

    curveFig = figure('Color','w','Position',[120 120 1000 620], 'Name', '三算法动态覆盖率曲线对比');
    curveAx = axes(curveFig); hold(curveAx, 'on'); grid(curveAx, 'on'); box(curveAx, 'on');
    xlabel(curveAx, '时间/s', 'FontSize', 12);
    ylabel(curveAx, '覆盖率/%', 'FontSize', 12);
    title(curveAx, '三算法覆盖率动态变化对比', 'FontSize', 14);
    xlim(curveAx, [0, maxStep * params.dt]); ylim(curveAx, [0, 100]);
    hT = plot(curveAx, 0, 100*terrainResults.coverageHist(1), '-', 'LineWidth', 2.0, 'Color', [0 0.6 0.3]);
    hN = plot(curveAx, 0, 100*newResults.coverageHist(1), '-', 'LineWidth', 1.8, 'Color', [0 0.45 0.74]);
    hO = plot(curveAx, 0, 100*oldResults.coverageHist(1), '-', 'LineWidth', 1.6, 'Color', [0.85 0.33 0.10]);
    plot(curveAx, [0, maxStep*params.dt], 100*cfg.coverageThreshold*[1 1], '--', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
    legend(curveAx, {'3D地形通信算法', '最大熵-信息素算法', '原算法', sprintf('%.0f%%覆盖阈值', 100*cfg.coverageThreshold)}, 'Location', 'southeast');

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
        tCovered = observeStep(tCovered, terrainResults, k, islandMask, params);
        nCovered = observeStep(nCovered, newResults, k, islandMask, params);
        oCovered = observeStep(oCovered, oldResults, k, islandMask, params);

        if mod(k, stride) == 0 || k == 1 || k == maxStep
            tViz = updateMapPanel(tViz, tCovered, islandMask, terrainResults, k, params, colors, '3D地形通信算法');
            nViz = updateMapPanel(nViz, nCovered, islandMask, newResults, k, params, colors, '最大熵-信息素算法');
            oViz = updateMapPanel(oViz, oCovered, islandMask, oldResults, k, params, colors, '原算法');
            tNow = (0:k) * params.dt;
            set(hT, 'XData', tNow, 'YData', 100*terrainResults.coverageHist(1:k+1));
            set(hN, 'XData', tNow, 'YData', 100*newResults.coverageHist(1:k+1));
            set(hO, 'XData', tNow, 'YData', 100*oldResults.coverageHist(1:k+1));
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

% ==================== 打印报告 ====================
function printComparisonReport(terrainResults, newResults, oldResults, params, cfg, outDir)
    fid = fopen(fullfile(outDir, 'comparison_report.txt'), 'w', 'n', 'UTF-8');
    fprintf(fid, '========================================================\n');
    fprintf(fid, '  三算法跨域协同搜索仿真对比报告\n');
    fprintf(fid, '========================================================\n\n');

    fprintf(fid, '--- 覆盖率指标 ---\n');
    fprintf(fid, '原算法         最终覆盖率: %.2f%%  达到90%%步数: %d\n', ...
        100*oldResults.finalCoverage, findFirstReach(oldResults.coverageHist, 0.90));
    fprintf(fid, '最大熵-信息素   最终覆盖率: %.2f%%  达到90%%步数: %d\n', ...
        100*newResults.finalCoverage, findFirstReach(newResults.coverageHist, 0.90));
    fprintf(fid, '3D地形通信     最终覆盖率: %.2f%%  达到90%%步数: %d\n', ...
        100*terrainResults.finalCoverage, findFirstReach(terrainResults.coverageHist, 0.90));
    fprintf(fid, '\n--- 重复率指标 ---\n');
    fprintf(fid, '原算法         最终重复率: %.2f%%\n', 100*oldResults.finalRepeatRate);
    fprintf(fid, '最大熵-信息素   最终重复率: %.2f%%\n', 100*newResults.finalRepeatRate);
    fprintf(fid, '3D地形通信     最终重复率: %.2f%%\n', 100*terrainResults.finalRepeatRate);
    fprintf(fid, '\n--- 通信质量指标 ---\n');
    if isfield(terrainResults, 'meanLosRatio')
        fprintf(fid, '3D地形通信     平均LoS率: %.4f  平均链路质量: %.4f\n', ...
            terrainResults.meanLosRatio, terrainResults.meanLinkQuality);
    end
    fprintf(fid, '最大熵-信息素   平均接入率: %.4f\n', mean(newResults.connectedUAVHist));
    fprintf(fid, '原算法         平均接入率: %.4f\n', mean(oldResults.connectedUAVHist));
    fprintf(fid, '\n========================================================\n');
    fclose(fid);
end

% ==================== 回放/快照辅助（从 compareEntropyPheromoneResults 移植） ====================
function replay = replaySearchMetrics(results, islandMask, params, snapshotSteps)
    replay.snapshots = cell(size(snapshotSteps));
    covered = false(params.N, params.N);
    steps = snapshotSteps;
    maxK = min(size(results.uavTrail,1)-1, max(steps));
    replay.visitCount = zeros(params.N, params.N);
    kSnapshot = 1;
    for k = 0:maxK
        covered = observeStepLocal(covered, results, k, islandMask, params);
        replay.visitCount(covered) = replay.visitCount(covered) + 1;
        while kSnapshot <= numel(steps) && k >= steps(kSnapshot)
            replay.snapshots{kSnapshot} = covered;
            kSnapshot = kSnapshot + 1;
        end
    end
end

function covered = observeInitial(covered, results, islandMask, params)
    for i = 1:size(results.uavTrail, 2)
        pos = squeeze(results.uavTrail(1, i, :))';
        covered = applyObsLocal(pos, pos, covered, islandMask, params, 'uav');
    end
    for j = 1:size(results.usvTrail, 2)
        pos = squeeze(results.usvTrail(1, j, :))';
        covered = applyObsLocal(pos, pos, covered, islandMask, params, 'usv');
    end
end

function covered = observeStep(covered, results, k, islandMask, params)
    for i = 1:size(results.uavTrail, 2)
        pos0 = squeeze(results.uavTrail(k, i, :))';
        pos1 = squeeze(results.uavTrail(k+1, i, :))';
        covered = applyObsLocal(pos0, pos1, covered, islandMask, params, 'uav');
    end
    for j = 1:size(results.usvTrail, 2)
        pos0 = squeeze(results.usvTrail(k, j, :))';
        pos1 = squeeze(results.usvTrail(k+1, j, :))';
        covered = applyObsLocal(pos0, pos1, covered, islandMask, params, 'usv');
    end
end

function covered = observeStepLocal(covered, results, k, islandMask, params)
    if k == 0
        covered = observeInitial(covered, results, islandMask, params);
        return;
    end
    covered = observeStep(covered, results, k, islandMask, params);
end

function covered = applyObsLocal(pos0, pos1, covered, islandMask, params, platformType)
    if strcmpi(platformType, 'uav'), widthKm = params.sensorStripWidthUAVKm;
    else, widthKm = params.sensorStripWidthUSVKm; end
    [r1, r2, c1, c2, stripMask] = getStripMaskLocal(pos0, pos1, widthKm, params);
    if isempty(stripMask), return; end
    islandLocal = islandMask(r1:r2, c1:c2);
    if strcmpi(platformType, 'uav'), validMask = stripMask;
    else, validMask = stripMask & (~islandLocal); end
    localCov = covered(r1:r2, c1:c2);
    localCov(validMask) = true;
    covered(r1:r2, c1:c2) = localCov;
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
    if c1 > c2 || r1 > r2, stripMask = false(0, 0); return; end
    cols = c1:c2; rows = r1:r2;
    xCells = (cols - 0.5) * params.dx;
    yCells = (rows - 0.5) * params.dx;
    [Xc, Yc] = meshgrid(xCells, yCells);
    AB = pos1 - pos0;
    denom = AB(1)^2 + AB(2)^2;
    if denom < 1e-12
        dist = hypot(Xc - pos0(1), Yc - pos0(2));
    else
        tVal = ((Xc - pos0(1)).*AB(1) + (Yc - pos0(2)).*AB(2)) / denom;
        tVal = min(max(tVal, 0), 1);
        projX = pos0(1) + tVal .* AB(1);
        projY = pos0(2) + tVal .* AB(2);
        dist = hypot(Xc - projX, Yc - projY);
    end
    stripMask = reshape(dist <= halfW, numel(rows), numel(cols));
end

function viz = initMapPanel(ax, covered, islandMask, xGrid, yGrid, results, step, params, colors, algName)
    axes(ax);
    viz.ax = ax;
    rgb = buildCoverageRGBLocal(islandMask, covered);
    viz.hImg = image([xGrid(1) xGrid(end)], [yGrid(1) yGrid(end)], rgb);
    set(gca, 'YDir', 'normal'); axis equal tight; box on; grid on; hold on;
    xlim([0 params.mapLenKm]); ylim([0 params.mapLenKm]);
    xlabel('X/km'); ylabel('Y/km');
    nUAV = size(results.uavTrail, 2);
    nUSV = size(results.usvTrail, 2);
    viz.hUAV = gobjects(1, nUAV*2);
    viz.hUSV = gobjects(1, nUSV*2);
    for i = 1:nUAV
        viz.hUAV(i) = plot(nan, nan, '-', 'LineWidth', 1.1, 'Color', colors.uav(min(i,end),:));
        viz.hUAV(nUAV+i) = plot(nan, nan, 'o', 'MarkerSize', 8, 'MarkerFaceColor', colors.uav(min(i,end),:), 'MarkerEdgeColor', 'k');
    end
    for j = 1:nUSV
        viz.hUSV(j) = plot(nan, nan, '--', 'LineWidth', 1.1, 'Color', colors.usv(min(j,end),:));
        viz.hUSV(nUSV+j) = plot(nan, nan, 's', 'MarkerSize', 9, 'MarkerFaceColor', colors.usv(min(j,end),:), 'MarkerEdgeColor', 'k');
    end
    viz.hComm = [];
    viz.step = step;
    ttl = title(sprintf('%s | 步长 %d', algName, step), 'FontSize', 11);
    viz.hTitle = ttl;
end

function viz = updateMapPanel(viz, covered, islandMask, results, step, params, colors, algName)
    rgb = buildCoverageRGBLocal(islandMask, covered);
    set(viz.hImg, 'CData', rgb);
    nUAV = size(results.uavTrail, 2);
    nUSV = size(results.usvTrail, 2);
    nTrail = min(step+1, size(results.uavTrail, 1));
    for i = 1:nUAV
        xi = squeeze(results.uavTrail(max(1,nTrail-25):nTrail, i, 1));
        yi = squeeze(results.uavTrail(max(1,nTrail-25):nTrail, i, 2));
        set(viz.hUAV(i), 'XData', xi, 'YData', yi);
        set(viz.hUAV(nUAV+i), 'XData', results.uavTrail(nTrail,i,1), 'YData', results.uavTrail(nTrail,i,2));
    end
    for j = 1:nUSV
        xj = squeeze(results.usvTrail(max(1,nTrail-25):nTrail, j, 1));
        yj = squeeze(results.usvTrail(max(1,nTrail-25):nTrail, j, 2));
        set(viz.hUSV(j), 'XData', xj, 'YData', yj);
        set(viz.hUSV(nUSV+j), 'XData', results.usvTrail(nTrail,j,1), 'YData', results.usvTrail(nTrail,j,2));
    end
    delete(viz.hComm(ishandle(viz.hComm)));
    viz.hComm = [];
    for i = 1:nUAV
        for q = i+1:nUAV
            d = norm(squeeze(results.uavTrail(nTrail,i,1:2) - results.uavTrail(nTrail,q,1:2)));
            if d <= params.commRangeKm
                h = plot(viz.ax, [results.uavTrail(nTrail,i,1), results.uavTrail(nTrail,q,1)], ...
                    [results.uavTrail(nTrail,i,2), results.uavTrail(nTrail,q,2)], ...
                    '-', 'Color', [0.0 0.7 0.0 0.4], 'LineWidth', 1.0);
                viz.hComm = [viz.hComm, h];
            end
        end
    end
    connCount = 0;
    if isfield(results, 'uavConnectedHist') && nTrail <= size(results.uavConnectedHist,1)
        connCount = sum(results.uavConnectedHist(nTrail, :));
    end
    cov = 100 * results.coverageHist(min(nTrail, numel(results.coverageHist)));
    rep = 100 * results.repeatRateHist(min(nTrail, numel(results.repeatRateHist)));
    titleStr = sprintf('%s | 步长 %d | 时间 %.0fs | 覆盖率 %.1f%% | 重复率 %.1f%% | 接入数 %d', ...
        algName, step, step*params.dt, cov, rep, connCount);
    set(viz.hTitle, 'String', titleStr);
    viz.step = step;
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
    if isfield(s, name) && ~isempty(s.(name)), val = s.(name); else, val = defaultVal; end
end


% ==================== 遮挡率对比图 ====================
function plotBlockedRatioComparison(terrainResults, newResults, oldResults, params, outDir)
%  遮挡率对比：仅3D地形算法存在地形遮挡，2D版恒为0。
    fig = figure('Color','w','Position',[120 120 800 560]);
    hold on; grid on; box on;

    % 3D地形算法
    if isfield(terrainResults, 'blockedRatioHist')
        tB = terrainResults.blockedRatioHist(:);
        nT = min(numel(tB), params.maxSteps+1);
        tSteps = (0:nT-1) * params.dt / 60;
        plot(tSteps, 100*tB(1:nT), '-s', 'LineWidth', 1.8, 'MarkerIndices', markerIdx(nT), 'MarkerSize', 6);
    end

    % 最大熵-信息素算法（2D无遮挡）
    if isfield(newResults, 'blockedRatioHist')
        nB = newResults.blockedRatioHist(:);
        nN = min(numel(nB), params.maxSteps+1);
        tStepsN = (0:nN-1) * params.dt / 60;
        plot(tStepsN, 100*nB(1:nN), '-d', 'LineWidth', 1.6, 'MarkerIndices', markerIdx(nN), 'MarkerSize', 6);
    end

    % 原算法（2D无遮挡）
    if isfield(oldResults, 'blockedRatioHist')
        oB = oldResults.blockedRatioHist(:);
        oN = min(numel(oB), params.maxSteps+1);
        tStepsO = (0:oN-1) * params.dt / 60;
        plot(tStepsO, 100*oB(1:oN), '-o', 'LineWidth', 1.4, 'MarkerIndices', markerIdx(oN), 'MarkerSize', 6);
    end

    xlabel('时间/min', 'FontSize', 12);
    ylabel('通信遮挡率/%', 'FontSize', 12);
    title('通信遮挡率对比曲线', 'FontSize', 14);
    legend({'3D地形通信算法', '最大熵-信息素算法(2D)', '原算法(2D)'}, 'Location', 'northeast');
    ylim([0 100]);
    saveFigureLocal(fig, fullfile(outDir, 'figure_01b_blocked_ratio_comparison.png'));
end
function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
end