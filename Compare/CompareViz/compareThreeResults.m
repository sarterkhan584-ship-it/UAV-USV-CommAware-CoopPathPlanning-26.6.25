function comparison = compareThreeResults(resultsOld, resultsMax, resultsImproved, mapData)
% compareThreeResults  三算法对比结构体构建
%  resultsOld: 传统算法
%  resultsMax: 最大熵算法
%  resultsImproved: CARS改进算法

    comparison.old = resultsOld;
    comparison.max = resultsMax;
    comparison.improved = resultsImproved;
    comparison.mapData = mapData;

    % --- 覆盖率 ---
    comparison.finalCovOld = resultsOld.finalCoverage;
    comparison.finalCovMax = resultsMax.finalCoverage;
    comparison.finalCovImproved = resultsImproved.finalCoverage;
    comparison.finalSeaOld = resultsOld.finalSeaCoverage;
    comparison.finalSeaMax = resultsMax.finalSeaCoverage;
    comparison.finalSeaImproved = resultsImproved.finalSeaCoverage;
    comparison.finalIslandOld = resultsOld.finalIslandCoverage;
    comparison.finalIslandMax = resultsMax.finalIslandCoverage;
    comparison.finalIslandImproved = resultsImproved.finalIslandCoverage;

    % --- 时间效率 ---
    comparison.stopTimeOld = resultsOld.stopTime;
    comparison.stopTimeMax = resultsMax.stopTime;
    comparison.stopTimeImproved = resultsImproved.stopTime;
    comparison.stopStepOld = resultsOld.stopStep;
    comparison.stopStepMax = resultsMax.stopStep;
    comparison.stopStepImproved = resultsImproved.stopStep;

    % --- 通信指标 (通过 commMetrics) ---
    fn = {'Old','Max','Improved'};
    resultsSet = {resultsOld, resultsMax, resultsImproved};
    for idx = 1:3
        r = resultsSet{idx};
        pre = fn{idx};
        if isfield(r, 'commMetrics') && ~isempty(fieldnames(r.commMetrics))
            cm = r.commMetrics;
            comparison.(['eta_B_' pre]) = cm.eta_B;
            comparison.(['eta_L_' pre]) = cm.eta_L;
            comparison.(['rho_LoS_' pre]) = cm.rho_LoS;
            comparison.(['gamma_bar_' pre]) = cm.gamma_bar_dB;
            comparison.(['R_bar_' pre]) = cm.R_bar_kbps;
            comparison.(['Q_bar_' pre]) = cm.Q_bar;
            comparison.(['tau_out_' pre]) = cm.tau_out_max;
            comparison.(['lambda2_B_' pre]) = cm.lambda2_bar_B;
            comparison.(['lambda2_L_' pre]) = cm.lambda2_bar_L;
        end
    end

    % --- 重复率 ---
    comparison.repeatRateOld = resultsOld.finalRepeatRate;
    comparison.repeatRateMax = resultsMax.finalRepeatRate;
    comparison.repeatRateImproved = resultsImproved.finalRepeatRate;

    % --- 通信接入 ---
    comparison.avgConnOld = resultsOld.avgConnectedUAVPerTime;
    comparison.avgConnMax = resultsMax.avgConnectedUAVPerTime;
    comparison.avgConnImproved = resultsImproved.avgConnectedUAVPerTime;
    comparison.uavCommRatioOld = resultsOld.uavCommTimeRatio;
    comparison.uavCommRatioMax = resultsMax.uavCommTimeRatio;
    comparison.uavCommRatioImproved = resultsImproved.uavCommTimeRatio;
end
