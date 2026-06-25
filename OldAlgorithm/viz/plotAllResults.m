function plotAllResults(results, params, mapData, outDir)
% plotAllResults  生成增强版算法全部可视化图表
%  独立运行时调用，为单次仿真生成完整的论文风格图表集

    if nargin < 4
        outDir = params.outputDir;
    end

    islandMask = mapData.islandMask;
    seaMask = mapData.seaMask;
    xGrid = mapData.xGrid;
    yGrid = mapData.yGrid;

    % 图01：最终覆盖航迹图（含通信状态标记）
    plotSearchMap(islandMask, results.coveredGlobal, xGrid, yGrid, results.uavTrail, results.usvTrail, params);
    movefileIfExists('search_tracks_full_map_v5.png', fullfile(outDir, 'figure_01_search_tracks.png'));
    movefileIfExists('search_tracks_full_map_v5.fig', fullfile(outDir, 'figure_01_search_tracks.fig'));

    % 图02：覆盖率曲线（全图/海面/岛屿 + 重复率）
    plotCoverageCurve(results.coverageHist, results.seaCoverageHist, ...
        results.islandCoverageHist, results.repeatRateHist, params);
    movefileIfExists('coverage_curve_v5.png', fullfile(outDir, 'figure_02_coverage_curve.png'));
    movefileIfExists('coverage_curve_v5.fig', fullfile(outDir, 'figure_02_coverage_curve.fig'));

    % 图03：通信指标综合仪表盘（6子图）
    plotCommunicationDashboard(results, params, outDir);

    % 图04：通信SINR与数据率时间曲线
    plotCommQualityCurves(results, params, outDir);

    % 图05：各UAV通信接入时间线（甘特图风格）
    plotUAVConnectivityTimeline(results, params, outDir);

    % 图06：代数连通度时间曲线
    plotLambda2Curves(results, params, outDir);

    % 图07：覆盖快照（400/800/1200步）
    plotCoverageSnapshots(results, mapData, params, outDir);

    % 图08：地形DEM可视化 + 三维地形图
    if isfield(params, 'terrainHeightMap') && ~isempty(params.terrainHeightMap)
        plotTerrainMap(results, mapData, params, outDir);
        plotTerrain3D(results, mapData, params, outDir);
    end

    % 图09：重复探测次数分布（N=0,1,2,3,...,9+的网格数直方图）
    plotRepeatVisitHistogram(results, params, outDir);

    % 图10：算法终态熵-信息素场（仅新算法）
    if isfield(results, 'entropyMap') && ~isempty(results.entropyMap)
        plotEntropyPheromoneMaps(results, islandMask, xGrid, yGrid, params);
        movefileIfExists('entropy_pheromone_maps.png', fullfile(outDir, 'figure_10_entropy_pheromone.png'));
        movefileIfExists('entropy_pheromone_maps.fig', fullfile(outDir, 'figure_10_entropy_pheromone.fig'));
    end

    close all;
end

% ========================================================================
function movefileIfExists(src, dst)
    if exist(src, 'file')
        [d, ~, ~] = fileparts(dst);
        if ~exist(d, 'dir'), mkdir(d); end
        movefile(src, dst);
    end
end

% ========================================================================
function plotTerrain3D(results, mapData, params, outDir)
% plotTerrain3D  地形三维曲面图 + UAV航迹叠加

    fig = figure('Color', 'w', 'Position', [80, 60, 1000, 800]);

    [X, Y] = meshgrid(mapData.xGrid, mapData.yGrid);
    Z = params.terrainHeightMap * 1000;  % km -> m

    % 三维曲面
    surf(X, Y, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.85);
    colormap(gca, 'turbo');
    hold on;

    % 绘制海平面
    zLevel = 0;
    patch([0 params.mapLenKm params.mapLenKm 0], [0 0 params.mapLenKm params.mapLenKm], ...
        zLevel * ones(1,4), 'b', 'FaceAlpha', 0.15, 'EdgeColor', 'none');

    % 绘制UAV航迹
    uavColor = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    for i = 1:size(results.uavTrail, 2)
        trail = squeeze(results.uavTrail(:, i, :));
        nTrail = min(size(trail,1), 500);  % 每500步抽稀显示
        stride = max(1, floor(size(trail,1) / nTrail));
        idx = 1:stride:size(trail,1);
        zTrail = ones(size(trail(idx,1))) * (params.uavCruiseAltitudeKm * 1000);  % UAV在巡航高度
        plot3(trail(idx,1), trail(idx,2), zTrail, '-', 'Color', uavColor(i,:), 'LineWidth', 1.5);
        plot3(trail(end,1), trail(end,2), params.uavCruiseAltitudeKm*1000, ...
            'o', 'MarkerSize', 8, 'MarkerFaceColor', uavColor(i,:), 'MarkerEdgeColor', 'k');
    end

    % USV在水面高度
    usvColor = [0.00 0.40 0.95; 0.00 0.75 0.85; 0.25 0.25 0.25];
    for j = 1:size(results.usvTrail, 2)
        trail = squeeze(results.usvTrail(:, j, :));
        zUSV = zeros(size(trail(:,1)));  % USV at sea level
        plot3(trail(:,1), trail(:,2), zUSV, '--', 'Color', usvColor(j,:), 'LineWidth', 1.5);
    end

    xlabel('X (km)'); ylabel('Y (km)'); zlabel('高程 (m)');
    title(sprintf('地形三维图 | 最大高程=%.0f m | 平均高程=%.0f m', ...
        params.terrainStats.maxElevationKm*1000, params.terrainStats.meanElevationKm*1000), 'FontSize', 13);
    view(45, 35);  % 视角
    grid on; box on;
    colorbar;
    c = colorbar; c.Label.String = '高程 (m)';

    saveFigureLocal(fig, fullfile(outDir, 'figure_11_terrain_3d.png'));
end

% ========================================================================
function plotCommunicationDashboard(results, params, outDir)
% plotCommunicationDashboard 6子图通信仪表盘，一图览尽全部通信指标

    fig = figure('Color', 'w', 'Position', [60, 40, 1600, 900]);
    cm = results.commMetrics;

    % (1) 基本通信服务率 eta_B —— 单柱
    subplot(2, 3, 1);
    bar([cm.eta_B, cm.eta_L]);
    set(gca, 'XTickLabel', {'\eta_B (基本)', '\eta_L (LoS)'});
    ylabel('服务率'); ylim([0, 1.05]);
    title(sprintf('通信服务率 | \\eta_B=%.3f, \\eta_L=%.3f', cm.eta_B, cm.eta_L));
    grid on;

    % (2) 物理层指标 SINR + 数据率
    subplot(2, 3, 2);
    yyaxis left;
    bar(1, cm.gamma_bar_dB, 'FaceColor', [0.2 0.6 0.8]);
    ylabel('SINR (dB)'); ylim([0, max(40, cm.gamma_bar_dB*1.3)]);
    yyaxis right;
    bar(2, cm.R_bar_kbps, 'FaceColor', [0.9 0.4 0.2]);
    ylabel('数据率 (kbps)');
    set(gca, 'XTick', [1 2], 'XTickLabel', {'\gamma (SINR)', 'R (速率)'});
    title(sprintf('物理层 | \\gamma=%.1f dB, R=%.0f kbps', cm.gamma_bar_dB, cm.R_bar_kbps));
    grid on;

    % (3) LoS链路比 vs 遮挡比
    subplot(2, 3, 3);
    bar([cm.rho_LoS, cm.blockedRatio]);
    set(gca, 'XTickLabel', {'\rho_{LoS}', '遮挡比'});
    ylabel('比例'); ylim([0, 1.05]);
    title(sprintf('链路构成 | LoS=%.3f, Blocked=%.3f', cm.rho_LoS, cm.blockedRatio));
    grid on;

    % (4) 图连通性 lambda2
    subplot(2, 3, 4);
    bar([cm.lambda2_bar_B, cm.lambda2_bar_L]);
    set(gca, 'XTickLabel', {'\lambda_2^B', '\lambda_2^L'});
    ylabel('代数连通度');
    title(sprintf('网络鲁棒性 | \\lambda_2^B=%.4f, \\lambda_2^L=%.4f', cm.lambda2_bar_B, cm.lambda2_bar_L));
    grid on;

    % (5) 各UAV断连时长
    subplot(2, 3, 5);
    bar(cm.tau_out_per_UAV);
    hold on; yline(params.tau_max_steps, 'r--', 'LineWidth', 1.5);
    xlabel('UAV编号'); ylabel('连续断连步数');
    title(sprintf('断连行为 | max=%d steps (阈值=%d)', cm.tau_out_max, params.tau_max_steps));
    legend({'断连时长', '约束阈值'}, 'Location', 'best');
    grid on;

    % (6) 通信连接率 per-UAV
    subplot(2, 3, 6);
    if isfield(results, 'uavCommTimeRatio')
        bar(100 * results.uavCommTimeRatio);
    else
        bar(ones(1, size(results.uavTrail, 2)));
    end
    xlabel('UAV编号'); ylabel('通信接入占比 (%)');
    ylim([0, 105]);
    title('各UAV通信接入时间占比');
    grid on;

    sgtitle(['通信指标综合仪表盘 —— ' results.algorithmName], 'FontSize', 14, 'FontWeight', 'bold');
    saveFigureLocal(fig, fullfile(outDir, 'figure_03_comm_dashboard.png'));
end

% ========================================================================
function plotCommQualityCurves(results, params, outDir)
% plotCommQualityCurves  SINR和数据率随时间变化曲线

    fig = figure('Color', 'w', 'Position', [100, 80, 1000, 450]);

    n = min(numel(results.sinrHist), numel(results.dataRateHist));
    t = (0:n-1) * params.dt;

    yyaxis left;
    plot(t, results.sinrHist(1:n), 'b-', 'LineWidth', 1.5);
    ylabel('SINR (dB)'); grid on;
    yyaxis right;
    plot(t, results.dataRateHist(1:n), 'r-', 'LineWidth', 1.5);
    ylabel('数据率 (kbps)');
    xlabel('时间 (s)');
    title('通信物理层指标时间曲线 (\gamma & R)');
    legend({'SINR', '数据率'}, 'Location', 'best');
    grid on;

    saveFigureLocal(fig, fullfile(outDir, 'figure_04_comm_quality_curves.png'));
end

% ========================================================================
function plotUAVConnectivityTimeline(results, params, outDir)
% plotUAVConnectivityTimeline  甘特图风格展示每架UAV的通信接入历史

    fig = figure('Color', 'w', 'Position', [100, 80, 1000, 450]);

    nUAV = size(results.uavConnectedHist, 2);
    nSteps = size(results.uavConnectedHist, 1);
    t = (0:nSteps-1) * params.dt;

    tSteps = min(nSteps, 400);
    for i = 1:nUAV
        conn = double(results.uavConnectedHist(1:tSteps, i));
        for k = 1:tSteps
            if conn(k)
                rectangle('Position', [t(k), nUAV - i + 0.5, params.dt, 0.5], ...
                    'FaceColor', [0.2 0.7 0.2], 'EdgeColor', 'none');
            else
                rectangle('Position', [t(k), nUAV - i + 0.5, params.dt, 0.5], ...
                    'FaceColor', [0.9 0.2 0.2], 'EdgeColor', 'none');
            end
        end
    end

    xlabel('时间 (s)'); ylabel('UAV编号');
    set(gca, 'YTick', 1:nUAV, 'YTickLabel', arrayfun(@(x) sprintf('UAV%d', x), 1:nUAV, 'UniformOutput', false));
    ylim([1, nUAV + 0.5]);
    xlim([t(1), t(tSteps)]);
    title('UAV通信接入甘特图 (绿色=在线, 红色=断连)');
    grid on;

    saveFigureLocal(fig, fullfile(outDir, 'figure_05_uav_connectivity_timeline.png'));
end

% ========================================================================
function plotLambda2Curves(results, params, outDir)
% plotLambda2Curves  G^B和G^L的代数连通度时间曲线

    if ~isfield(results, 'lambda2_B_Hist')
        return;
    end

    fig = figure('Color', 'w', 'Position', [100, 80, 900, 400]);
    n = numel(results.lambda2_B_Hist);
    t = (0:n-1) * params.dt;

    plot(t, results.lambda2_B_Hist(1:n), 'b-', 'LineWidth', 1.5); hold on;
    if isfield(results, 'lambda2_L_Hist')
        plot(t, results.lambda2_L_Hist(1:n), 'r--', 'LineWidth', 1.5);
    end
    xlabel('时间 (s)'); ylabel('代数连通度 \lambda_2');
    title('图代数连通度时间曲线');
    legend({'G^B (基本)', 'G^L (LoS)'}, 'Location', 'best');
    grid on;

    saveFigureLocal(fig, fullfile(outDir, 'figure_06_lambda2_curves.png'));
end

% ========================================================================
function plotCoverageSnapshots(results, mapData, params, outDir)
% plotCoverageSnapshots  在指定时刻绘制覆盖状态快照（含航迹）

    islandMask = mapData.islandMask;
    xGrid = mapData.xGrid;
    yGrid = mapData.yGrid;

    snapshotSteps = [200, 400, 600];  % 对应 2000s, 4000s, 6000s
    totalSteps = size(results.uavTrail, 1) - 1;
    % 过滤超过实际运行步数的快照
    snapshotSteps(snapshotSteps > totalSteps) = [];

    if isempty(snapshotSteps)
        return;
    end

    nCols = min(3, numel(snapshotSteps));
    nRows = ceil(numel(snapshotSteps) / nCols);

    fig = figure('Color', 'w', 'Position', [40, 60, 550*nCols, 480*nRows]);

    uavColor = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    usvColor = [0.00 0.40 0.95; 0.00 0.75 0.85; 0.25 0.25 0.25];

    for s = 1:numel(snapshotSteps)
        step = snapshotSteps(s);
        covered = getCoverageAtStep(results, islandMask, params, step);

        subplot(nRows, nCols, s);
        rgb = buildCoverageRGBLocal(islandMask, covered);
        image([xGrid(1), xGrid(end)], [yGrid(1), yGrid(end)], rgb);
        set(gca, 'YDir', 'normal'); hold on;
        axis equal tight; box on; grid on;
        xlim([0, params.mapLenKm]); ylim([0, params.mapLenKm]);

        for i = 1:size(results.uavTrail, 2)
            trail = squeeze(results.uavTrail(1:step+1, i, :));
            plot(trail(:,1), trail(:,2), '-', 'Color', uavColor(i,:), 'LineWidth', 1.0);
            plot(trail(end,1), trail(end,2), 'o', 'MarkerSize', 5, ...
                'MarkerFaceColor', uavColor(i,:), 'MarkerEdgeColor', uavColor(i,:));
        end
        for j = 1:size(results.usvTrail, 2)
            trail = squeeze(results.usvTrail(1:step+1, j, :));
            plot(trail(:,1), trail(:,2), '--', 'Color', usvColor(j,:), 'LineWidth', 1.0);
        end

        covAt = results.coverageHist(min(step+1, numel(results.coverageHist)));
        title(sprintf('K=%d (%.0fs)  覆盖率 %.1f%%', step, step*params.dt, 100*covAt), 'FontSize', 11);
    end

    sgtitle(['覆盖进程快照 —— ' results.algorithmName], 'FontSize', 13, 'FontWeight', 'bold');
    saveFigureLocal(fig, fullfile(outDir, 'figure_07_coverage_snapshots.png'));
end

% ========================================================================
function covered = getCoverageAtStep(results, islandMask, params, targetStep)
    covered = false(params.N, params.N);
    for k = 1:min(targetStep, size(results.uavTrail, 1)-1)
        for i = 1:size(results.uavTrail, 2)
            p0 = squeeze(results.uavTrail(k, i, :))';
            p1 = squeeze(results.uavTrail(k+1, i, :))';
            covered = applyObs(covered, p0, p1, islandMask, params, 'uav');
        end
        for j = 1:size(results.usvTrail, 2)
            p0 = squeeze(results.usvTrail(k, j, :))';
            p1 = squeeze(results.usvTrail(k+1, j, :))';
            covered = applyObs(covered, p0, p1, islandMask, params, 'usv');
        end
    end
end

function covered = applyObs(covered, p0, p1, islandMask, params, pType)
    if strcmpi(pType, 'uav')
        w = params.sensorStripWidthUAVKm;
    else
        w = params.sensorStripWidthUSVKm;
    end
    halfW = w/2;
    xMin = max(0, min(p0(1), p1(1))-halfW);
    xMax = min(params.mapLenKm, max(p0(1), p1(1))+halfW);
    yMin = max(0, min(p0(2), p1(2))-halfW);
    yMax = min(params.mapLenKm, max(p0(2), p1(2))+halfW);
    c1 = max(1, floor(xMin/params.dx)+1);
    c2 = min(params.N, floor(xMax/params.dx)+1);
    r1 = max(1, floor(yMin/params.dx)+1);
    r2 = min(params.N, floor(yMax/params.dx)+1);
    if r1 > r2 || c1 > c2, return; end
    [Xc, Yc] = meshgrid((c1:c2)-0.5, (r1:r2)-0.5);
    Xc = Xc * params.dx; Yc = Yc * params.dx;
    AB = p1 - p0;
    denom = AB(1)^2 + AB(2)^2;
    if denom < 1e-12
        dist = hypot(Xc - p0(1), Yc - p0(2));
    else
        t = ((Xc-p0(1)).*AB(1) + (Yc-p0(2)).*AB(2)) / denom;
        t = min(max(t, 0), 1);
        dist = hypot(Xc - (p0(1)+t*AB(1)), Yc - (p0(2)+t*AB(2)));
    end
    valid = dist <= halfW;
    if strcmpi(pType, 'usv')
        valid = valid & ~islandMask(r1:r2, c1:c2);
    end
    local = covered(r1:r2, c1:c2);
    local(valid) = true;
    covered(r1:r2, c1:c2) = local;
end

% ========================================================================
function plotTerrainMap(results, mapData, params, outDir)
% plotTerrainMap  地形高程图 + UAV航迹叠加

    fig = figure('Color', 'w', 'Position', [80, 60, 1200, 550]);

    subplot(1, 2, 1);
    imagesc(mapData.xGrid, mapData.yGrid, params.terrainHeightMap*1000);
    set(gca, 'YDir', 'normal'); axis equal tight; colorbar;
    hold on;
    uavColor = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    for i = 1:size(results.uavTrail, 2)
        trail = squeeze(results.uavTrail(:, i, :));
        plot(trail(:,1), trail(:,2), '-', 'Color', uavColor(i,:), 'LineWidth', 1.2);
    end
    xlabel('X (km)'); ylabel('Y (km)');
    title('DEM高程图 (m) + UAV航迹');
    colormap(gca, 'turbo');

    subplot(1, 2, 2);
    imagesc(mapData.xGrid, mapData.yGrid, params.terrainSlopeMap);
    set(gca, 'YDir', 'normal'); axis equal tight; colorbar;
    title('地形坡度图');
    colormap(gca, 'hot');

    sgtitle(sprintf('地形与航迹 | 最大高程=%.0fm | 平均高程=%.0fm', ...
        params.terrainStats.maxElevationKm*1000, params.terrainStats.meanElevationKm*1000), ...
        'FontSize', 12, 'FontWeight', 'bold');

    saveFigureLocal(fig, fullfile(outDir, 'figure_08_terrain_dem.png'));
end

% ========================================================================
function plotRepeatVisitHistogram(results, params, outDir)
% plotRepeatVisitHistogram  各重复探测次数对应的网格数量直方图

    if ~isfield(results, 'visitCountGlobal') || isempty(results.visitCountGlobal)
        return;
    end

    fig = figure('Color', 'w', 'Position', [100, 80, 700, 450]);
    maxV = 10;
    counts = zeros(maxV+1, 1);
    for v = 0:maxV-1
        counts(v+1) = nnz(results.visitCountGlobal == v);
    end
    counts(maxV+1) = nnz(results.visitCountGlobal >= maxV);

    bar(0:maxV, counts, 'FaceColor', [0.2 0.6 0.8]);
    set(gca, 'XTickLabel', [arrayfun(@num2str, 0:maxV-1, 'UniformOutput', false), {[num2str(maxV) '+']}]);
    xlabel('重复探测次数'); ylabel('网格数量');
    title(sprintf('重复探测分布 | 总网格=%d | 重复率=%.1f%%', ...
        params.N*params.N, 100*results.finalRepeatRate));
    grid on;

    saveFigureLocal(fig, fullfile(outDir, 'figure_09_repeat_histogram.png'));
end

% ========================================================================
function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
    [p, n, ~] = fileparts(fileName);
    figName = fullfile(p, [n '.fig']);
    savefig(fig, figName);
end

% ========================================================================
function rgb = buildCoverageRGBLocal(islandMask, covered)
    rgb = zeros([size(islandMask), 3]);
    for r = 1:size(islandMask,1)
        for c = 1:size(islandMask,2)
            if islandMask(r,c)
                if covered(r,c), rgb(r,c,:) = [0.55 0.55 0.55];
                else, rgb(r,c,:) = [0 0 0]; end
            else
                if covered(r,c), rgb(r,c,:) = [1 1 1];
                else, rgb(r,c,:) = [0.78 0.90 1.00]; end
            end
        end
    end
end
