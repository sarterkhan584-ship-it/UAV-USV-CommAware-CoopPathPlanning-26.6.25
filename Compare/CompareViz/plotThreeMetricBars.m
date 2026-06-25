function plotThreeMetricBars(comparison, cfg)
% plotThreeMetricBars  Three-algorithm communication metric bar chart

    if ~isfield(comparison, 'eta_B_Old')
        fprintf('  No comm metrics data, skipping bar chart\n');
        return;
    end

    metricNames = {'\eta_B', '\eta_L', '\rho_{LoS}', '\lambda_2^B', 'Q_{bar}'};
    oldVals = [comparison.eta_B_Old, comparison.eta_L_Old, ...
               comparison.rho_LoS_Old, comparison.lambda2_B_Old, ...
               comparison.Q_bar_Old];
    maxVals = [comparison.eta_B_Max, comparison.eta_L_Max, ...
               comparison.rho_LoS_Max, comparison.lambda2_B_Max, ...
               comparison.Q_bar_Max];
    impVals = [comparison.eta_B_Improved, comparison.eta_L_Improved, ...
               comparison.rho_LoS_Improved, comparison.lambda2_B_Improved, ...
               comparison.Q_bar_Improved];

    fig = figure('Position', [100, 100, 1000, 550]);
    barData = [oldVals(:), maxVals(:), impVals(:)];
    b = bar(barData);
    b(1).FaceColor = [0.2 0.6 0.8];
    b(2).FaceColor = [0.9 0.3 0.3];
    b(3).FaceColor = [0.2 0.8 0.3];
    set(gca, 'XTickLabel', metricNames);
    ylabel('Value');
    title('Communication Quality: Three-Algorithm Comparison');
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'northwest');
    grid on;

    saveFigureLocal(fig, fullfile(cfg.outputDir, 'three_compare_metrics.png'));
    fprintf('  Three-algorithm metrics chart saved\n');
end

function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
    [p, n, ~] = fileparts(fileName);
    figName = fullfile(p, [n '.fig']);
    savefig(fig, figName);
end
