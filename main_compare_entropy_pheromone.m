function comparison = main_compare_entropy_pheromone()
% main_compare_entropy_pheromone
% 运行原算法与"最大熵-信息素联合覆盖搜索算法"（增强版通信建模），并生成对比。
%
% 输出目录：Compare/CompareResults/

    clc;
    close all;

    rootDir = fileparts(mfilename('fullpath'));
    compareDir = fullfile(rootDir, 'Compare');
    addpath(genpath(compareDir));

    oldRoot = fullfile(rootDir, 'OldAlgorithm');
    newRoot = fullfile(rootDir, 'NewAlgorithm');
    outDir = fullfile(rootDir, 'Compare', 'CompareResults');

    % 加载对比配置
    cfg = getCompareConfigLegacy(outDir);

    fprintf('\n========== 运行增强版老算法（拓扑法）==========\n');
    addpath(genpath(oldRoot));
    oldParams = getDefaultParams();
    oldParams = applyOverrides(oldParams, cfg);
    oldParams.outputDir = cfg.oldOutputDir;
    [oldResults, oldParams, oldMapStats, oldMapData] = runOldAlgorithm(oldParams);
    rmpath(genpath(oldRoot));
    clearAlgorithmFunctions();
    rehash;

    fprintf('\n========== 运行增强版新算法（最大熵-信息素法）==========\n');
    addpath(genpath(newRoot));
    newParams = getDefaultParams();
    newParams = applyOverrides(newParams, cfg);
    newParams.outputDir = cfg.newOutputDir;
    [newResults, newParams, newMapStats, newMapData] = runNewAlgorithm(newParams);
    rmpath(genpath(newRoot));
    clearAlgorithmFunctions();
    rehash;

    fprintf('\n========== 生成对比可视化 ==========\n');
    comparison = compareResults(oldResults, newResults, oldMapData);
    comparison.oldMapStats = oldMapStats;
    comparison.newMapStats = newMapStats;
    comparison.oldMapData = oldMapData;
    comparison.newMapData = newMapData;

    % 生成对比图
    try
        plotCompareCoverage(comparison, cfg);
        plotCompareMetricBars(comparison, cfg);
        plotCompareTrails(oldMapData, oldResults, newResults, cfg);
        plotCompareMetricsDashboard(comparison, cfg);
        plotCompareCommCurves(comparison, cfg);
    catch ME
        fprintf('  绘图警告: %s\n', ME.message);
    end
    printCompareSummary(comparison);

    save(fullfile(cfg.compareOutputDir, 'comparison_results.mat'), ...
        'comparison', 'oldResults', 'newResults', 'oldParams', 'newParams', 'oldMapData', 'newMapData');
    fprintf('对比结果已保存至：%s\n', cfg.compareOutputDir);
end

function cfg = getCompareConfigLegacy(outDir)
    cfg.compareOutputDir = outDir;
    cfg.outputDir = outDir;
    cfg.oldOutputDir = fullfile(outDir, 'OldAlgorithm');
    cfg.newOutputDir = fullfile(outDir, 'NewAlgorithm');
    cfg.enableAnimation = false;
    cfg.skipIndividualPlots = true;
    cfg.stopAtTarget = false;
    cfg.maxSteps = 600;
    cfg.targetCoverage = 0.90;
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
    clear getDefaultParams initializeMapAndThreats initializePlatforms initializeCoverageState
    clear initializeHistoryAndVisualization runSearchSimulation packageSimulationResults
    clear selectBestAction evaluateCandidate applyStripObservation applyEntropyPheromoneObservation
    clear getStripMask buildIslandThreatField buildTerrainThreatField pathCrossIsland sampleUSVThreatInfo
    clear buildUAVRelayGraph fuseByUSVRelay getUAVConnectivity getCoverageStats computeCommunicationMetrics
    clear updatePheromoneMaps buildFrontierMap plotSearchMap plotCoverageCurve
end
