function printSimulationResults(results, history, state)
% printSimulationResults 打印终端结果摘要（含8项通信指标）

    fprintf('\n========== 仿真结果 ==========' ); fprintf('\n');
    fprintf('算法名称               : %s\n', results.algorithmName);
    fprintf('停止原因               : %s\n', results.stopReason);
    fprintf('总仿真时长             : %.0f s (%.0f 步)\n', results.stopTime, results.stopStep);
    fprintf('\n--- 覆盖率 ---\n');
    fprintf('全地图最终覆盖率       : %.2f %%\n', 100 * results.finalCoverage);
    fprintf('海面最终覆盖率         : %.2f %%\n', 100 * results.finalSeaCoverage);
    fprintf('岛屿最终覆盖率         : %.2f %%\n', 100 * results.finalIslandCoverage);
    fprintf('最终重复搜索率         : %.2f %%\n', 100 * results.finalRepeatRate);

    fprintf('\n--- 通信指标 ---\n');
    fprintf('平均接入UAV数/时刻     : %.2f 架\n', results.avgConnectedUAVPerTime);
    for i = 1:state.nUAV
        fprintf('UAV%d 通信时长占比      : %.2f %%\n', i, 100 * results.uavCommTimeRatio(i));
    end
    if isfield(results, 'commMetrics') && ~isempty(fieldnames(results.commMetrics))
        cm = results.commMetrics;
        fprintf('基本通信服务率 eta_B  : %.3f\n', cm.eta_B);
        fprintf('LoS通信服务率 eta_L   : %.3f (核心指标)\n', cm.eta_L);
        fprintf('平均LoS链路比 rho_LoS : %.3f\n', cm.rho_LoS);
        fprintf('平均SINR              : %.1f dB\n', cm.gamma_bar_dB);
        fprintf('平均数据率            : %.1f kbps\n', cm.R_bar_kbps);
        fprintf('路径质量 Q_bar        : %.3f\n', cm.Q_bar);
        fprintf('最大连续断连时长      : %.0f 步 (%.0f s)\n', cm.tau_out_max, cm.tau_out_max * 10);
        fprintf('G^B平均代数连通度     : %.4f\n', cm.lambda2_bar_B);
        fprintf('G^L平均代数连通度     : %.4f\n', cm.lambda2_bar_L);
    end
    if isfield(results, 'meanSINR_dB')
        fprintf('全过程平均SINR         : %.1f dB\n', results.meanSINR_dB);
    end
    if isfield(results, 'meanDataRate_kbps')
        fprintf('全过程平均数据率       : %.1f kbps\n', results.meanDataRate_kbps);
    end
    if isfield(results, 'meanLambda2_B')
        fprintf('全过程平均lambda2_B    : %.4f\n', results.meanLambda2_B);
    end
    if isfield(results, 'meanLambda2_L')
        fprintf('全过程平均lambda2_L    : %.4f\n', results.meanLambda2_L);
    end
    fprintf('================================\n');
end
