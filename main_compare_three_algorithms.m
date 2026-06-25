function comparison = main_compare_three_algorithms()
% main_compare_three_algorithms
%  递进式三算法对比：
%   1. 传统算法（拓扑引导贪心搜索） —— 基线
%   2. 最大熵算法（仅熵驱动，无信息素） —— 覆盖↑但通信↓
%   3. CARS改进算法（通信感知角色切换） —— 覆盖↑且通信↑
%
%  输出目录：Compare/CompareResults/

    clc;
    close all;

    rootDir = fileparts(mfilename('fullpath'));
    compareDir = fullfile(rootDir, 'Compare');
    addpath(genpath(compareDir));

    oldRoot = fullfile(rootDir, 'OldAlgorithm');
    maxRoot = fullfile(rootDir, 'MaxEntropyOnly');
    impRoot = fullfile(rootDir, 'ImprovedAlgorithm');
    outDir = fullfile(rootDir, 'Compare', 'CompareResults');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    cfg.outputDir = outDir;
    cfg.compareOutputDir = outDir;
    cfg.oldOutputDir = fullfile(outDir, 'OldAlgorithm');
    cfg.newOutputDir = fullfile(outDir, 'MaxEntropyOnly');
    cfg.impOutputDir = fullfile(outDir, 'ImprovedAlgorithm');
    cfg.enableAnimation = false;
    cfg.skipIndividualPlots = true;
    cfg.stopAtTarget = false;
    cfg.maxSteps = 600;
    cfg.targetCoverage = 0.90;
    cfg.snapshotSteps = [200, 400, 600];

    % ====== 运行传统算法 ======
    fprintf('\n==========================================\n');
    fprintf('  [1/3] 运行传统算法（拓扑引导贪心搜索）\n');
    fprintf('==========================================\n');
    addpath(genpath(oldRoot));
    oldParams = getDefaultParams();
    oldParams = applyOverrides(oldParams, cfg);
    oldParams.outputDir = cfg.oldOutputDir;
    [oldResults, oldParams, oldMapStats, oldMapData] = runOldAlgorithm(oldParams);
    rmpath(genpath(oldRoot));
    clearAlgorithmFunctions();
    rehash;

    % ====== 运行最大熵算法 ======
    fprintf('\n==========================================\n');
    fprintf('  [2/3] 运行最大熵算法（仅熵场驱动）\n');
    fprintf('==========================================\n');
    addpath(genpath(maxRoot));
    maxParams = getMaxEntropyParams();
    maxParams = applyOverrides(maxParams, cfg);
    maxParams.outputDir = cfg.newOutputDir;
    [maxResults, maxParams, maxMapStats, maxMapData] = runMaxEntropyAlgorithm(maxParams);
    rmpath(genpath(maxRoot));
    clearAlgorithmFunctions();
    rehash;

    % ====== 运行 CARS 改进算法 ======
    fprintf('\n==========================================\n');
    fprintf('  [3/3] 运行CARS改进算法（通信感知角色切换）\n');
    fprintf('==========================================\n');
    addpath(genpath(impRoot));
    impParams = getImprovedParams();
    impParams = applyOverrides(impParams, cfg);
    impParams.outputDir = cfg.impOutputDir;
    [impResults, impParams, impMapStats, impMapData] = runImprovedAlgorithm(impParams);
    rmpath(genpath(impRoot));
    clearAlgorithmFunctions();
    rehash;

    % ====== 生成三算法对比可视化 ======
    fprintf('\n==========================================\n');
    fprintf('  生成三算法对比可视化\n');
    fprintf('==========================================\n');

    comparison = compareThreeResults(oldResults, maxResults, impResults, oldMapData);
    comparison.oldMapStats = oldMapStats;
    comparison.maxMapStats = maxMapStats;
    comparison.impMapStats = impMapStats;

    try
        plotThreeCoverage(comparison, cfg);
        plotThreeMetricBars(comparison, cfg);
        plotThreeCommDashboard(comparison, cfg);
        plotThreeCommCurves(comparison, cfg);
    catch ME
        fprintf('  绘图警告: %s\n', ME.message);
    end
    printThreeCompareSummary(comparison, cfg);

    save(fullfile(cfg.compareOutputDir, 'three_compare_results.mat'), ...
        'comparison', 'oldResults', 'maxResults', 'impResults', ...
        'oldParams', 'maxParams', 'impParams', 'oldMapData', 'maxMapData', 'impMapData');
    fprintf('\n三算法对比结果已保存至：%s\n', cfg.compareOutputDir);
end

function params = applyOverrides(params, cfg)
    params.enableAnimation = cfg.enableAnimation;
    params.skipIndividualPlots = cfg.skipIndividualPlots;
    if ~isempty(cfg.maxSteps)
        params.maxSteps = cfg.maxSteps;
        params.maxTime = cfg.maxSteps * params.dt;
    end
    if ~isempty(cfg.targetCoverage)
        params.targetCoverage = cfg.targetCoverage;
    end
    params.stopAtTarget = cfg.stopAtTarget;
end

function clearAlgorithmFunctions()
    clear getDefaultParams getMaxEntropyParams getImprovedParams
    clear initializeMapAndThreats initializePlatforms initializeCoverageState
    clear initializeMaxEntropyState initializeImprovedState
    clear initializeHistoryAndVisualization runSearchSimulation
    clear runMaxEntropySimulation runImprovedSimulation
    clear packageSimulationResults
    clear selectBestAction selectActionCARS evaluateCandidate
    clear evaluateExplorer evaluateRelay evaluateUSVEnhanced
    clear applyStripObservation applyEntropyObservation
    clear applyEntropyPheromoneObservation updatePheromoneMaps buildFrontierMap
    clear getStripMask buildIslandThreatField buildTerrainThreatField pathCrossIsland
    clear sampleUSVThreatInfo computeConnectivityHealth assignRoles
    clear buildUAVRelayGraph fuseByUSVRelay getUAVConnectivity getCoverageStats
    clear computeCommunicationMetrics countConnectedUAV
    clear plotSearchMap plotCoverageCurve printSimulationResults plotAllResults
    clear initDynamicVisualization updateDynamicVisualization finalizeDynamicVisualization
    clear buildCoverageRGB saveFigureCompat
end
