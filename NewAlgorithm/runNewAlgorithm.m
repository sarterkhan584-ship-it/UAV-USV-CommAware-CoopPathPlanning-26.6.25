function [results, params, mapStats, mapData] = runNewAlgorithm(params)
% runNewAlgorithm  最大熵-信息素联合覆盖搜索算法。
% 主要新增：熵场、吸引/排斥信息素、重复探测惩罚、动态权重、前沿牵引和边界软势场。

    if nargin < 1 || isempty(params)
        rootDir = fileparts(mfilename('fullpath'));
        addpath(genpath(rootDir));
        params = getDefaultParams();
    end

    rootDir = fileparts(mfilename('fullpath'));
    addpath(genpath(rootDir));

    if ~isfield(params, 'outputDir') || isempty(params.outputDir)
        params.outputDir = fullfile(rootDir, 'results_entropy_pheromone');
    end
    if ~exist(params.outputDir, 'dir')
        mkdir(params.outputDir);
    end

    oldPwd = pwd;
    cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
    cd(params.outputDir);

    [islandMask, seaMask, xGrid, yGrid, mapStats, params] = initializeMapAndThreats(params);
    state = initializePlatforms(params);
    state = initializeCoverageState(state, islandMask, params);
    [history, viz] = initializeHistoryAndVisualization(state, islandMask, seaMask, xGrid, yGrid, params);
    [state, history, stopInfo, viz] = runSearchSimulation(state, history, islandMask, seaMask, xGrid, yGrid, params, viz);

    if params.enableAnimation
        finalizeDynamicVisualization(viz);
    end

    [results, state, history] = packageSimulationResults(state, history, stopInfo, params);
    results.algorithmName = '最大熵-信息素算法';
    results.entropyMap = state.entropyMap;
    results.visitCountGlobal = state.visitCountGlobal;
    results.attractionPheromone = state.attractionPheromone;
    results.repulsionPheromone = state.repulsionPheromone;
    results.entropyMeanHist = history.entropyMeanHist;

    mapData.islandMask = islandMask;
    mapData.seaMask = seaMask;
    mapData.xGrid = xGrid;
    mapData.yGrid = yGrid;

    if ~isfield(params, 'skipIndividualPlots') || ~params.skipIndividualPlots
        plotAllResults(results, params, mapData, params.outputDir);
        if exist('plotEntropyPheromoneMaps', 'file') == 2
            plotEntropyPheromoneMaps(state, islandMask, xGrid, yGrid, params);
        end
        printSimulationResults(results, history, state);
    end

    save('new_entropy_pheromone_result.mat', 'results', 'params', 'mapStats', 'mapData');
end
