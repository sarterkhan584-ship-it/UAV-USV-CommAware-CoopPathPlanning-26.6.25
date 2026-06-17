function [state, history, stopInfo, viz] = runSearchSimulation(state, history, islandMask, seaMask, xGrid, yGrid, params, viz)
%  执行逐步搜索主循环，记录通信质量指标（含8项新增指标）。

    stopInfo.stopStep = params.maxSteps;
    stopInfo.stopReason = '达到最大步数';

    for k = 1:params.maxSteps

        currIslandCoverage = history.islandCoverageHist(k);

        % ---------- UAV 一步决策（含岛屿优先阶段任务） ----------
        nextUAVPos = state.uavPos;
        nextUAVPsi = state.uavPsi;
        for i = 1:state.nUAV
            otherUAV = state.uavPos(setdiff(1:state.nUAV, i), :);
            [nextUAVPos(i, :), nextUAVPsi(i)] = selectBestAction( ...
                state.uavPos(i, :), state.uavPsi(i), state.localUAV{i}, state.usvPos, otherUAV, islandMask, ...
                params, 'uav', i, currIslandCoverage);
        end

        % ---------- USV 一步决策（加入人工势场避障） ----------
        nextUSVPos = state.usvPos;
        nextUSVPsi = state.usvPsi;
        for j = 1:state.nUSV
            otherUSV = state.usvPos(setdiff(1:state.nUSV, j), :);
            [nextUSVPos(j, :), nextUSVPsi(j)] = selectBestAction( ...
                state.usvPos(j, :), state.usvPsi(j), state.localUSV{j}, state.uavPos, otherUSV, islandMask, ...
                params, 'usv', j, currIslandCoverage);
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

        % ---------- 条带覆盖更新 ----------
        for i = 1:state.nUAV
            [state.coveredGlobal, state.localUAV{i}, stat] = applyStripObservation( ...
                prevUAVPos(i, :), state.uavPos(i, :), state.coveredGlobal, state.localUAV{i}, islandMask, params, 'uav');
            state.newCountCum = state.newCountCum + stat.newCount;
            state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        end

        for j = 1:state.nUSV
            [state.coveredGlobal, state.localUSV{j}, stat] = applyStripObservation( ...
                prevUSVPos(j, :), state.usvPos(j, :), state.coveredGlobal, state.localUSV{j}, islandMask, params, 'usv');
            state.newCountCum = state.newCountCum + stat.newCount;
            state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        end

        % ---------- 周期性信息融合 ----------
        if mod(k, params.commUpdateEvery) == 0
            [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
        end

        % ---------- 统计 ----------
        [history.coverageHist(k + 1), history.seaCoverageHist(k + 1), history.islandCoverageHist(k + 1)] = ...
            getCoverageStats(state.coveredGlobal, seaMask, islandMask);
        history.repeatRateHist(k + 1) = state.repeatCountCum / max(1, state.newCountCum + state.repeatCountCum);

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
