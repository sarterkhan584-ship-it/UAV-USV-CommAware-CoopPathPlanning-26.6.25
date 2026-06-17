function plotCompareMetricBars(comparison, cfg)
% plotCompareMetricBars  绘制通信指标柱状图对比
% 独立性：不依赖任何自定义函数

    if ~isfield(comparison, 'eta_B_Old')
        fprintf('  无通信指标数据，跳过柱状图\n');
        return;
    end

    metricNames = {'eta_B', 'eta_L', 'rho_{LoS}', 'Q_{bar}', '\lambda_2^B'};
    oldVals = [comparison.eta_B_Old, comparison.eta_L_Old, ...
               comparison.rho_LoS_Old, comparison.Q_bar_Old, ...
               comparison.lambda2_B_Old];
    newVals = [comparison.eta_B_New, comparison.eta_L_New, ...
               comparison.rho_LoS_New, comparison.Q_bar_New, ...
               comparison.lambda2_B_New];

    fig = figure('Position', [100, 100, 800, 500]);
    barData = [oldVals(:), newVals(:)];
    b = bar(barData);
    b(1).FaceColor = [0.2 0.6 0.8];
    b(2).FaceColor = [0.9 0.3 0.3];
    set(gca, 'XTickLabel', metricNames);
    ylabel('指标值');
    title('通信质量指标对比（老算法 vs. 新算法）');
    legend({'老算法（拓扑法）', '新算法（熵-信息素法）'}, 'Location', 'northwest');
    grid on;
    drawnow;

    saveas(fig, fullfile(cfg.outputDir, 'compare_metrics.png'));
    fprintf('  通信指标对比图已保存\n');
end
