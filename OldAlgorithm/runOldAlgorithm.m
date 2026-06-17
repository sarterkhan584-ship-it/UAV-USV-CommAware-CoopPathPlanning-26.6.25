function [results, params, mapStats, mapData] = runOldAlgorithm(params)
% runOldAlgorithm  原始 UAV-USV 跨域协同覆盖搜索算法。
% 用法：
%   [results, params, mapStats, mapData] = runOldAlgorithm();
%   [results, params, mapStats, mapData] = runOldAlgorithm(params);

    if nargin < 1 || isempty(params)
        rootDir = fileparts(mfilename('fullpath'));
        addpath(genpath(rootDir));
        params = getDefaultParams();
    end

    rootDir = fileparts(mfilename('fullpath'));
    addpath(genpath(rootDir));

    if ~isfield(params, 'outputDir') || isempty(params.outputDir)
        params.outputDir = fullfile(rootDir, 'results_old');
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
    results.algorithmName = '原算法';

    mapData.islandMask = islandMask;
    mapData.seaMask = seaMask;
    mapData.xGrid = xGrid;
    mapData.yGrid = yGrid;

    if ~isfield(params, 'skipIndividualPlots') || ~params.skipIndividualPlots
        plotAllResults(results, params, mapData, params.outputDir);
        plotSearchMap(islandMask, state.coveredGlobal, xGrid, yGrid, state.uavTrail, state.usvTrail, params);
        plotCoverageCurve(history.coverageHist, history.seaCoverageHist, history.islandCoverageHist, history.repeatRateHist, params);
        printSimulationResults(results, history, state);
    end

    save('old_algorithm_result.mat', 'results', 'params', 'mapStats', 'mapData');
end
