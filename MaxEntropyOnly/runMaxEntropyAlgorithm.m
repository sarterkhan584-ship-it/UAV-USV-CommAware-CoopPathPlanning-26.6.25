function [results, params, mapStats, mapData] = runMaxEntropyAlgorithm(params)
% runMaxEntropyAlgorithm  最大熵 UAV-USV 跨域协同覆盖搜索算法（无信息素/前沿机制）
%
%  与 OldAlgorithm 的区别：引入熵场驱动探索，但通信权重固定不变。
%  与 NewAlgorithm 的区别：移除了吸引/排斥信息素和前沿检测机制。
%
%  用法：
%    [results, params, mapStats, mapData] = runMaxEntropyAlgorithm();
%    [results, params, mapStats, mapData] = runMaxEntropyAlgorithm(params);

    if nargin < 1 || isempty(params)
        rootDir = fileparts(mfilename('fullpath'));
        addpath(genpath(rootDir));
        params = getMaxEntropyParams();
    end

    rootDir = fileparts(mfilename('fullpath'));
    addpath(genpath(rootDir));

    if ~isfield(params, 'outputDir') || isempty(params.outputDir)
        params.outputDir = fullfile(rootDir, 'results_maxentropy');
    end
    if ~exist(params.outputDir, 'dir')
        mkdir(params.outputDir);
    end

    oldPwd = pwd;
    cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
    cd(params.outputDir);

    [islandMask, seaMask, xGrid, yGrid, mapStats, params] = initializeMapAndThreats(params);
    state = initializePlatforms(params);
    state = initializeMaxEntropyState(state, islandMask, params);
    [history, viz] = initializeHistoryAndVisualization(state, islandMask, seaMask, xGrid, yGrid, params);
    [state, history, stopInfo, viz] = runMaxEntropySimulation(state, history, islandMask, seaMask, xGrid, yGrid, params, viz);

    if params.enableAnimation
        finalizeDynamicVisualization(viz);
    end

    [results, state, history] = packageSimulationResults(state, history, stopInfo, params);
    results.algorithmName = '最大熵算法';

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

    save('maxentropy_algorithm_result.mat', 'results', 'params', 'mapStats', 'mapData');
end
