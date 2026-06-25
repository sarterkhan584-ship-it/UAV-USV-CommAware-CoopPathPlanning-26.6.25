function [results, params, mapStats, mapData] = runImprovedAlgorithm(params)
% runImprovedAlgorithm  CARS（Connectivity-Aware Role-Switching）改进算法
%
%  核心创新：
%   1. 连通健康度指数 H(t)：综合 λ₂ + η_B + N_conn
%   2. 角色自适应切换：EXPLORER ↔ RELAY
%   3. 通信自适应权重：relay/spread/entropy/coverage 权重随 H(t) 动态变化
%   4. USV 瓶颈桥接：主动移动到断连分量之间充当桥接
%
%  相比最大熵算法：利用通信增强反馈提升覆盖效率
%
%  用法：
%    [results, params, mapStats, mapData] = runImprovedAlgorithm();
%    [results, params, mapStats, mapData] = runImprovedAlgorithm(params);

    if nargin < 1 || isempty(params)
        rootDir = fileparts(mfilename('fullpath'));
        addpath(genpath(rootDir));
        params = getImprovedParams();
    end

    rootDir = fileparts(mfilename('fullpath'));
    addpath(genpath(rootDir));

    if ~isfield(params, 'outputDir') || isempty(params.outputDir)
        params.outputDir = fullfile(rootDir, 'results_improved');
    end
    if ~exist(params.outputDir, 'dir')
        mkdir(params.outputDir);
    end

    oldPwd = pwd;
    cleanupObj = onCleanup(@() cd(oldPwd)); %#ok<NASGU>
    cd(params.outputDir);

    [islandMask, seaMask, xGrid, yGrid, mapStats, params] = initializeMapAndThreats(params);
    state = initializePlatforms(params);
    state = initializeImprovedState(state, islandMask, params);
    [history, viz] = initializeHistoryAndVisualization(state, islandMask, seaMask, xGrid, yGrid, params);
    [state, history, stopInfo, viz] = runImprovedSimulation(state, history, islandMask, seaMask, xGrid, yGrid, params, viz);

    if params.enableAnimation
        finalizeDynamicVisualization(viz);
    end

    [results, state, history] = packageSimulationResults(state, history, stopInfo, params);
    results.algorithmName = 'CARS改进算法';

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

    save('improved_algorithm_result.mat', 'results', 'params', 'mapStats', 'mapData');
end
