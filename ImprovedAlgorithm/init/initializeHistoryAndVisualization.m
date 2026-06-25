function [history, viz] = initializeHistoryAndVisualization(state, islandMask, seaMask, xGrid, yGrid, params)
%  初始化统计历史，含通信质量指标（含8项新增指标）。

    history.coverageHist = zeros(params.maxSteps + 1, 1);
    history.seaCoverageHist = zeros(params.maxSteps + 1, 1);
    history.islandCoverageHist = zeros(params.maxSteps + 1, 1);
    history.repeatRateHist = zeros(params.maxSteps + 1, 1);
    history.connectedUAVHist = zeros(params.maxSteps + 1, 1);
    history.connectedAnyCountHist = zeros(params.maxSteps + 1, 1);
    history.uavConnectedHist = false(params.maxSteps + 1, state.nUAV);
    history.losRatioHist = zeros(params.maxSteps + 1, 1);
    history.meanLinkQualityHist = zeros(params.maxSteps + 1, 1);
    history.blockedRatioHist = zeros(params.maxSteps + 1, 1);
    % 新增指标历史
    history.sinrHist = zeros(params.maxSteps + 1, 1);
    history.dataRateHist = zeros(params.maxSteps + 1, 1);
    history.uavServiceBHist = false(params.maxSteps + 1, state.nUAV);
    history.uavServiceLHist = false(params.maxSteps + 1, state.nUAV);
    history.lambda2_B_Hist = zeros(params.maxSteps + 1, 1);
    history.lambda2_L_Hist = zeros(params.maxSteps + 1, 1);
    history.entropyMeanHist = zeros(params.maxSteps + 1, 1);
    % CARS 独有历史
    history.healthHist = zeros(params.maxSteps + 1, 1);
    history.etaBHist = zeros(params.maxSteps + 1, 1);
    history.lambda2Hist = zeros(params.maxSteps + 1, 1);
    history.rolesHist = zeros(params.maxSteps, state.nUAV);

    [history.coverageHist(1), history.seaCoverageHist(1), history.islandCoverageHist(1)] = ...
        getCoverageStats(state.coveredGlobal, seaMask, islandMask);
    history.repeatRateHist(1) = state.repeatCountCum / max(1, state.newCountCum + state.repeatCountCum);

    [connFlags0, connPerUSV0, metrics0] = getUAVConnectivity(state.uavPos, state.usvPos, params);
    history.uavConnectedHist(1, :) = connFlags0;
    history.connectedAnyCountHist(1) = sum(connFlags0);
    history.connectedUAVHist(1) = mean(connPerUSV0);
    history.losRatioHist(1) = metrics0.losRatio;
    history.meanLinkQualityHist(1) = metrics0.meanLinkQuality;
    history.blockedRatioHist(1) = metrics0.blockedRatio;
    history.sinrHist(1) = metrics0.meanSINR_dB;
    history.dataRateHist(1) = metrics0.meanDataRate_kbps;
    history.uavServiceBHist(1, :) = metrics0.uavServiceB;
    history.uavServiceLHist(1, :) = metrics0.uavServiceL;
    history.lambda2_B_Hist(1) = metrics0.lambda2_B;
    history.lambda2_L_Hist(1) = metrics0.lambda2_L;
    history.entropyMeanHist(1) = mean(state.entropyMap(:));
    % CARS 独有初始化
    history.healthHist(1, 1) = 1.0;  % 初始连通过高
    history.etaBHist(1, 1) = mean(metrics0.uavServiceB);
    history.lambda2Hist(1, 1) = metrics0.lambda2_B;
    history.rolesHist(1, :) = ones(1, state.nUAV);

    if params.enableAnimation
        viz = initDynamicVisualization(islandMask, state.coveredGlobal, xGrid, yGrid, state.uavTrail(1, :, :), state.usvTrail(1, :, :), ...
            history.coverageHist(1), history.seaCoverageHist(1), history.islandCoverageHist(1), history.repeatRateHist(1), ...
            history.connectedAnyCountHist(1), connFlags0, params);
    else
        viz = [];
    end
end
