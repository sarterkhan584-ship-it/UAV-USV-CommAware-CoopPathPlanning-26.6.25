function commMetrics = computeCommunicationMetrics(uavPos, usvPos, params, uavServiceBHist, uavServiceLHist)
% computeCommunicationMetrics  计算8项通信评价指标
%
%  在仿真结束后调用，统计全部仿真时段的通信质量。
%
%  输入:
%    uavPos, usvPos  - 最终时刻平台位置（用于最终快照统计）
%    params          - 参数结构体
%    uavServiceBHist - K x nUAV, 基本通信服务接入历史 (a_i^B)
%    uavServiceLHist - K x nUAV, LoS通信服务接入历史 (a_i^L)
%
%  输出:
%    commMetrics - 结构体，含8项指标

    [K, nUAV] = size(uavServiceBHist);
    if K == 0, K = 1; end

    % 1. 基本通信服务率 eta_B
    commMetrics.eta_B = mean(uavServiceBHist(:));

    % 2. LoS通信服务率 eta_L（核心指标）
    commMetrics.eta_L = mean(uavServiceLHist(:));

    % 3. 平均LoS链路比 rho_LoS — 从buildUAVRelayGraph获取
    [~, ~, ~, ~, metrics] = buildUAVRelayGraph(uavPos, usvPos, params);
    commMetrics.rho_LoS = metrics.losRatio;

    % 4. 平均SINR (dB)
    commMetrics.gamma_bar_dB = metrics.meanSINR_dB;

    % 5. 平均数据率 (kbps)
    commMetrics.R_bar_kbps = metrics.meanDataRate_kbps;

    % 6. 最优接入路径质量 — 简化版：取直接链路质量均值
    %    （完整版应对每UAV做Dijkstra，此处用均值近似）
    commMetrics.Q_bar = metrics.meanLinkQuality;

    % 7. 最大连续断连时长
    tau_out = zeros(1, nUAV);
    for i = 1:nUAV
        maxConsec = 0;
        current = 0;
        for k = 1:K
            if uavServiceBHist(k, i) == 0
                current = current + 1;
                maxConsec = max(maxConsec, current);
            else
                current = 0;
            end
        end
        tau_out(i) = current;  % 最后一次失联也可能在末尾
        tau_out(i) = max(tau_out(i), maxConsec);
    end
    commMetrics.tau_out_max = max(tau_out);
    commMetrics.tau_out_per_UAV = tau_out;

    % 8. 平均代数连通度
    commMetrics.lambda2_bar_B = metrics.lambda2_B;
    commMetrics.lambda2_bar_L = metrics.lambda2_L;

    % 补充：基本统计
    commMetrics.connectedCount = metrics.connectedCount;
    commMetrics.connectedRatio = metrics.connectedRatio;
    commMetrics.meanLinkQuality = metrics.meanLinkQuality;
    commMetrics.blockedRatio = metrics.blockedRatio;
end
