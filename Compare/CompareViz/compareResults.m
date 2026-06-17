function comparison = compareResults(resultsOld, resultsNew, mapData)
% compareResults  对比两个算法的运行结果，生成对比结构体

    comparison.old = resultsOld;
    comparison.new = resultsNew;
    comparison.mapData = mapData;

    % 覆盖率对比
    comparison.finalCovOld = resultsOld.finalCoverage;
    comparison.finalCovNew = resultsNew.finalCoverage;
    comparison.finalSeaOld = resultsOld.finalSeaCoverage;
    comparison.finalSeaNew = resultsNew.finalSeaCoverage;
    comparison.finalIslandOld = resultsOld.finalIslandCoverage;
    comparison.finalIslandNew = resultsNew.finalIslandCoverage;

    % 时间效率对比
    comparison.stopTimeOld = resultsOld.stopTime;
    comparison.stopTimeNew = resultsNew.stopTime;
    comparison.stopStepOld = resultsOld.stopStep;
    comparison.stopStepNew = resultsNew.stopStep;

    % 通信指标对比
    if isfield(resultsOld, 'commMetrics') && ~isempty(fieldnames(resultsOld.commMetrics))
        cmOld = resultsOld.commMetrics;
        cmNew = resultsNew.commMetrics;

        comparison.eta_B_Old = cmOld.eta_B;
        comparison.eta_B_New = cmNew.eta_B;
        comparison.eta_L_Old = cmOld.eta_L;
        comparison.eta_L_New = cmNew.eta_L;
        comparison.rho_LoS_Old = cmOld.rho_LoS;
        comparison.rho_LoS_New = cmNew.rho_LoS;
        comparison.gamma_bar_Old = cmOld.gamma_bar_dB;
        comparison.gamma_bar_New = cmNew.gamma_bar_dB;
        comparison.R_bar_Old = cmOld.R_bar_kbps;
        comparison.R_bar_New = cmNew.R_bar_kbps;
        comparison.Q_bar_Old = cmOld.Q_bar;
        comparison.Q_bar_New = cmNew.Q_bar;
        comparison.tau_out_Old = cmOld.tau_out_max;
        comparison.tau_out_New = cmNew.tau_out_max;
        comparison.lambda2_B_Old = cmOld.lambda2_bar_B;
        comparison.lambda2_B_New = cmNew.lambda2_bar_B;
        comparison.lambda2_L_Old = cmOld.lambda2_bar_L;
        comparison.lambda2_L_New = cmNew.lambda2_bar_L;
    end

    % 重复率对比
    comparison.repeatRateOld = resultsOld.finalRepeatRate;
    comparison.repeatRateNew = resultsNew.finalRepeatRate;

    % 通信接入对比
    comparison.avgConnOld = resultsOld.avgConnectedUAVPerTime;
    comparison.avgConnNew = resultsNew.avgConnectedUAVPerTime;
    comparison.uavCommRatioOld = resultsOld.uavCommTimeRatio;
    comparison.uavCommRatioNew = resultsNew.uavCommTimeRatio;

    % LoS历史均值
    if isfield(resultsOld, 'losRatioHist')
        comparison.meanLosOld = mean(resultsOld.losRatioHist);
        comparison.meanLosNew = mean(resultsNew.losRatioHist);
    else
        comparison.meanLosOld = 0;
        comparison.meanLosNew = 0;
    end
end
