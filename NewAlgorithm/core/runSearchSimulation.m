function [state, history, stopInfo, viz] = runSearchSimulation(state, history, islandMask, seaMask, xGrid, yGrid, params, viz)
%  执行最大熵-信息素联合覆盖搜索主循环，记录通信质量指标（含8项新增指标）。

    stopInfo.stopStep = params.maxSteps;
    stopInfo.stopReason = '达到最大步数';

    for k = 1:params.maxSteps

        currIslandCoverage = history.islandCoverageHist(k);
        state.frontierMap = buildFrontierMap(state.coveredGlobal, islandMask, params);

        % ---------- UAV 一步决策 ----------
        nextUAVPos = state.uavPos;
        nextUAVPsi = state.uavPsi;
        for i = 1:state.nUAV
            otherUAV = state.uavPos(setdiff(1:state.nUAV, i), :);
            [nextUAVPos(i, :), nextUAVPsi(i)] = selectBestAction( ...
                state.uavPos(i, :), state.uavPsi(i), state.localUAV{i}, state.usvPos, otherUAV, islandMask, ...
                state, params, 'uav', i, currIslandCoverage);
        end

        % ---------- USV 一步决策 ----------
        nextUSVPos = state.usvPos;
        nextUSVPsi = state.usvPsi;
        for j = 1:state.nUSV
            otherUSV = state.usvPos(setdiff(1:state.nUSV, j), :);
            [nextUSVPos(j, :), nextUSVPsi(j)] = selectBestAction( ...
                state.usvPos(j, :), state.usvPsi(j), state.localUSV{j}, state.uavPos, otherUSV, islandMask, ...
                state, params, 'usv', j, currIslandCoverage);
        end

        % ---------- 执行动作并记录航迹 ----------
        prevUAVPos = state.uavPos;
        prevUSVPos = state.usvPos;

        state.uavPos = nextUAVPos;
        state.uavPsi = nextUAVPsi;
        state.usvPos = nextUSVPos;
        state.usvPsi = nextUSVPsi;

        state.uavTrail(k + 1, :, :) = state.uavPos;
        state.usvTrail(k + 1, :, :) = state.usvPos;

        % ---------- 条带覆盖、熵场、探测次数更新 ----------
        observedStepMask = false(params.N, params.N);
        for i = 1:state.nUAV
            [state, state.localUAV{i}, stat, obsMask] = applyEntropyPheromoneObservation( ...
                prevUAVPos(i, :), state.uavPos(i, :), state, state.localUAV{i}, islandMask, params, 'uav');
            state.newCountCum = state.newCountCum + stat.newCount;
            state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
            observedStepMask = observedStepMask | obsMask;
        end

        for j = 1:state.nUSV
            [state, state.localUSV{j}, stat, obsMask] = applyEntropyPheromoneObservation( ...
                prevUSVPos(j, :), state.usvPos(j, :), state, state.localUSV{j}, islandMask, params, 'usv');
            state.newCountCum = state.newCountCum + stat.newCount;
            state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
            observedStepMask = observedStepMask | obsMask;
        end

        state = updatePheromoneMaps(state, islandMask, observedStepMask, params);

        % ---------- 周期性信息融合 ----------
        if mod(k, params.commUpdateEvery) == 0
            [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
        end

        % ---------- 统计 ----------
        [history.coverageHist(k + 1), history.seaCoverageHist(k + 1), history.islandCoverageHist(k + 1)] = ...
            getCoverageStats(state.coveredGlobal, seaMask, islandMask);
        history.repeatRateHist(k + 1) = state.repeatCountCum / max(1, state.newCountCum + state.repeatCountCum);
        history.entropyMeanHist(k + 1) = mean(state.entropyMap(:));

        [connFlagsNow, connPerUSVNow, metrics] = getUAVConnectivity(state.uavPos, state.usvPos, params);
        history.uavConnectedHist(k + 1, :) = connFlagsNow;
        history.connectedAnyCountHist(k + 1) = sum(connFlagsNow);
        history.connectedUAVHist(k + 1) = mean(connPerUSVNow);
        history.losRatioHist(k + 1) = metrics.losRatio;
        history.meanLinkQualityHist(k + 1) = metrics.meanLinkQuality;
        history.blockedRatioHist(k + 1) = metrics.blockedRatio;
        % 新增指标记录
        history.sinrHist(k + 1) = metrics.meanSINR_dB;
        history.dataRateHist(k + 1) = metrics.meanDataRate_kbps;
        history.uavServiceBHist(k + 1, :) = metrics.uavServiceB;
        history.uavServiceLHist(k + 1, :) = metrics.uavServiceL;
        history.lambda2_B_Hist(k + 1) = metrics.lambda2_B;
        history.lambda2_L_Hist(k + 1) = metrics.lambda2_L;

        if params.enableAnimation
            viz = updateDynamicVisualization(viz, islandMask, state.coveredGlobal, xGrid, yGrid, ...
                state.uavTrail(1:k+1, :, :), state.usvTrail(1:k+1, :, :), ...
                history.coverageHist(1:k+1), history.seaCoverageHist(1:k+1), history.islandCoverageHist(1:k+1), history.repeatRateHist(1:k+1), ...
                history.connectedAnyCountHist(k + 1), connFlagsNow, k, params);
        end

        if (~isfield(params, 'stopAtTarget') || params.stopAtTarget) && history.coverageHist(k + 1) >= params.targetCoverage
            stopInfo.stopStep = k;
            stopInfo.stopReason = '全图覆盖率达到阈值';
            return;
        end
    end
end
