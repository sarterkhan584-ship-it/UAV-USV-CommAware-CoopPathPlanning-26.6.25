function [results, state, history] = packageSimulationResults(state, history, stopInfo, params)
%  截断历史并封装结果结构体，含通信质量指标（含8项新增指标）。

    validIdx = 1:(stopInfo.stopStep + 1);
    state.uavTrail = state.uavTrail(validIdx, :, :);
    state.usvTrail = state.usvTrail(validIdx, :, :);

    history.coverageHist = history.coverageHist(validIdx);
    history.seaCoverageHist = history.seaCoverageHist(validIdx);
    history.islandCoverageHist = history.islandCoverageHist(validIdx);
    history.repeatRateHist = history.repeatRateHist(validIdx);
    history.connectedUAVHist = history.connectedUAVHist(validIdx);
    history.connectedAnyCountHist = history.connectedAnyCountHist(validIdx);
    history.uavConnectedHist = history.uavConnectedHist(validIdx, :);
    if isfield(history, 'losRatioHist')
        history.losRatioHist = history.losRatioHist(validIdx);
    end
    if isfield(history, 'meanLinkQualityHist')
        history.meanLinkQualityHist = history.meanLinkQualityHist(validIdx);
    end
    if isfield(history, 'blockedRatioHist')
        history.blockedRatioHist = history.blockedRatioHist(validIdx);
    end
    if isfield(history, 'entropyMeanHist')
        history.entropyMeanHist = history.entropyMeanHist(validIdx);
    end
    if isfield(history, 'sinrHist')
        history.sinrHist = history.sinrHist(validIdx);
    end
    if isfield(history, 'dataRateHist')
        history.dataRateHist = history.dataRateHist(validIdx);
    end
    if isfield(history, 'uavServiceBHist')
        history.uavServiceBHist = history.uavServiceBHist(validIdx, :);
    end
    if isfield(history, 'uavServiceLHist')
        history.uavServiceLHist = history.uavServiceLHist(validIdx, :);
    end
    if isfield(history, 'lambda2_B_Hist')
        history.lambda2_B_Hist = history.lambda2_B_Hist(validIdx);
    end
    if isfield(history, 'lambda2_L_Hist')
        history.lambda2_L_Hist = history.lambda2_L_Hist(validIdx);
    end

    if stopInfo.stopStep > 0
        uavCommTimeRatio = sum(history.uavConnectedHist(1:end-1, :), 1) / stopInfo.stopStep;
        avgConnectedUAVPerTime = mean(history.connectedAnyCountHist(1:end-1));
    else
        uavCommTimeRatio = double(history.uavConnectedHist(1, :));
        avgConnectedUAVPerTime = history.connectedAnyCountHist(1);
    end

    if isfield(history, 'uavServiceBHist') && isfield(history, 'uavServiceLHist')
        commMetrics = computeCommunicationMetrics(state.uavPos, state.usvPos, params, ...
            history.uavServiceBHist(1:end-1, :), history.uavServiceLHist(1:end-1, :));
    else
        commMetrics = struct();
    end

    results.coveredGlobal = state.coveredGlobal;
    results.uavTrail = state.uavTrail;
    results.usvTrail = state.usvTrail;
    results.coverageHist = history.coverageHist;
    results.seaCoverageHist = history.seaCoverageHist;
    results.islandCoverageHist = history.islandCoverageHist;
    results.repeatRateHist = history.repeatRateHist;
    results.connectedUAVHist = history.connectedUAVHist;
    results.connectedAnyCountHist = history.connectedAnyCountHist;
    results.uavConnectedHist = history.uavConnectedHist;
    results.uavCommTimeRatio = uavCommTimeRatio;
    results.avgConnectedUAVPerTime = avgConnectedUAVPerTime;

    results.entropyMap = state.entropyMap;
    results.visitCountGlobal = state.visitCountGlobal;
    results.attractionPheromone = state.attractionPheromone;
    results.repulsionPheromone = state.repulsionPheromone;
    results.entropyMeanHist = history.entropyMeanHist;

    if isfield(history, 'losRatioHist')
        results.losRatioHist = history.losRatioHist;
        results.meanLosRatio = mean(history.losRatioHist);
    end
    if isfield(history, 'meanLinkQualityHist')
        results.meanLinkQualityHist = history.meanLinkQualityHist;
        results.meanLinkQuality = mean(history.meanLinkQualityHist);
    end
    if isfield(history, 'blockedRatioHist')
        results.blockedRatioHist = history.blockedRatioHist;
        results.meanBlockedRatio = mean(history.blockedRatioHist);
    end
    if isfield(history, 'sinrHist')
        results.sinrHist = history.sinrHist;
        results.meanSINR_dB = mean(history.sinrHist);
    end
    if isfield(history, 'dataRateHist')
        results.dataRateHist = history.dataRateHist;
        results.meanDataRate_kbps = mean(history.dataRateHist);
    end
    if isfield(history, 'lambda2_B_Hist')
        results.lambda2_B_Hist = history.lambda2_B_Hist;
        results.meanLambda2_B = mean(history.lambda2_B_Hist);
    end
    if isfield(history, 'lambda2_L_Hist')
        results.lambda2_L_Hist = history.lambda2_L_Hist;
        results.meanLambda2_L = mean(history.lambda2_L_Hist);
    end
    if ~isempty(fieldnames(commMetrics))
        results.commMetrics = commMetrics;
    end

    results.newCountCum = state.newCountCum;
    results.repeatCountCum = state.repeatCountCum;
    results.finalCoverage = history.coverageHist(end);
    results.finalSeaCoverage = history.seaCoverageHist(end);
    results.finalIslandCoverage = history.islandCoverageHist(end);
    results.finalRepeatRate = history.repeatRateHist(end);
    results.stopStep = stopInfo.stopStep;
    results.stopTime = stopInfo.stopStep * params.dt;
    results.stopReason = stopInfo.stopReason;
end
