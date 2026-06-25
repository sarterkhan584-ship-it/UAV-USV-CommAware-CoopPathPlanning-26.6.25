function [state, history, stopInfo, viz] = runImprovedSimulation(state, history, islandMask, seaMask, xGrid, yGrid, params, viz)
% runImprovedSimulation  通信自适应最大熵算法主循环
%  无角色切换，仅 relay/spread 权重随 eta_B 平滑调制。

    stopInfo.stopStep = params.maxSteps;
    stopInfo.stopReason = 'reach max steps';

    for k = 1:params.maxSteps

        % ==== Step 1: 通信健康度评估 ====
        [~, ~, metrics] = getUAVConnectivity(state.uavPos, state.usvPos, params);
        eta_B_now = mean(metrics.uavServiceB);

        if k == 1
            state.smoothedEta = eta_B_now;
        else
            state.smoothedEta = params.etaSmoothing * eta_B_now + (1 - params.etaSmoothing) * state.smoothedEta;
        end

        % 保存历史
        history.etaBHist(k + 1, 1) = eta_B_now;
        history.healthHist(k + 1, 1) = state.smoothedEta;
        if k == 1
            history.etaBHist(1, 1) = eta_B_now;
            history.healthHist(1, 1) = state.smoothedEta;
        end

        % ==== Step 2: UAV 决策 ====
        currIslandCoverage = history.islandCoverageHist(k);
        nextUAVPos = state.uavPos;
        nextUAVPsi = state.uavPsi;
        for i = 1:state.nUAV
            otherUAV = state.uavPos(setdiff(1:state.nUAV, i), :);
            [nextUAVPos(i, :), nextUAVPsi(i)] = selectActionCARS( ...
                state.uavPos(i, :), state.uavPsi(i), state.localUAV{i}, state.usvPos, otherUAV, islandMask, ...
                state, params, 'uav', i, currIslandCoverage);
        end

        % ==== Step 3: USV 决策 ====
        nextUSVPos = state.usvPos;
        nextUSVPsi = state.usvPsi;
        for j = 1:state.nUSV
            otherUSV = state.usvPos(setdiff(1:state.nUSV, j), :);
            [nextUSVPos(j, :), nextUSVPsi(j)] = selectActionCARS( ...
                state.usvPos(j, :), state.usvPsi(j), state.localUSV{j}, state.uavPos, otherUSV, islandMask, ...
                state, params, 'usv', j, currIslandCoverage);
        end

        % ==== Step 4: 执行动作 ====
        prevUAVPos = state.uavPos;
        prevUSVPos = state.usvPos;
        state.uavPos = nextUAVPos;
        state.uavPsi = nextUAVPsi;
        state.usvPos = nextUSVPos;
        state.usvPsi = nextUSVPsi;
        state.uavTrail(k + 1, :, :) = state.uavPos;
        state.usvTrail(k + 1, :, :) = state.usvPos;

        % ==== Step 5: 条带覆盖与熵场更新 ====
        for i = 1:state.nUAV
            [state, state.localUAV{i}, stat] = applyEntropyObservation( ...
                prevUAVPos(i, :), state.uavPos(i, :), state, state.localUAV{i}, islandMask, params, 'uav');
            state.newCountCum = state.newCountCum + stat.newCount;
            state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        end
        for j = 1:state.nUSV
            [state, state.localUSV{j}, stat] = applyEntropyObservation( ...
                prevUSVPos(j, :), state.usvPos(j, :), state, state.localUSV{j}, islandMask, params, 'usv');
            state.newCountCum = state.newCountCum + stat.newCount;
            state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        end

        % ==== Step 6: 信息融合 ====
        if mod(k, params.commUpdateEvery) == 0
            [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
        end

        % ==== Step 7: 统计记录 ====
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
            stopInfo.stopReason = 'coverage threshold reached';
            return;
        end
    end
end
