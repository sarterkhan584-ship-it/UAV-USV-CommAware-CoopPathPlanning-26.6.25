function plotCompareMetricsDashboard(comparison, cfg)
% plotCompareMetricsDashboard  6-panel comparison dashboard for all 8 comm metrics
% 独立性: pure MATLAB, no custom dependencies

    if ~isfield(comparison, 'eta_B_Old')
        fprintf('  No comm metrics data, skipping dashboard\n');
        return;
    end

    fig = figure('Color', 'w', 'Position', [40, 40, 1600, 900]);

    % (1) Service rates eta_B & eta_L
    subplot(2, 3, 1);
    barData = [comparison.eta_B_Old comparison.eta_B_New; ...
               comparison.eta_L_Old comparison.eta_L_New];
    b = bar(barData);
    b(1).FaceColor = [0.2 0.6 0.8]; b(2).FaceColor = [0.9 0.3 0.3];
    set(gca, 'XTickLabel', {'\eta_B (basic)', '\eta_L (LoS)'});
    ylabel('Service rate'); ylim([0, 1.05]);
    title('Communication service rates');
    legend({'Old', 'New'}, 'Location', 'northwest'); grid on;

    % (2) SINR & Data rate
    subplot(2, 3, 2);
    yyaxis left;
    bar([1 2], [comparison.gamma_bar_Old comparison.gamma_bar_New], ...
        'FaceColor', [0.2 0.6 0.8]);
    ylabel('SINR (dB)');
    yyaxis right;
    bar([3 4], [comparison.R_bar_Old comparison.R_bar_New], ...
        'FaceColor', [0.9 0.4 0.2]);
    ylabel('Data rate (kbps)');
    set(gca, 'XTick', [1 2 3 4], 'XTickLabel', {'\gamma Old','\gamma New','R Old','R New'});
    title('Physical layer quality'); grid on;

    % (3) LoS ratio comparison
    subplot(2, 3, 3);
    bar([comparison.rho_LoS_Old comparison.rho_LoS_New; ...
         comparison.meanLosOld comparison.meanLosNew]);
    set(gca, 'XTickLabel', {'\rho_{LoS}', 'mean LoS hist'});
    ylabel('Ratio'); ylim([0, 1.05]);
    title('LoS link ratios');
    legend({'Old', 'New'}, 'Location', 'northwest'); grid on;

    % (4) Algebraic connectivity
    subplot(2, 3, 4);
    bar([comparison.lambda2_B_Old comparison.lambda2_B_New; ...
         comparison.lambda2_L_Old comparison.lambda2_L_New]);
    set(gca, 'XTickLabel', {'\lambda_2^B', '\lambda_2^L'});
    ylabel('Algebraic connectivity');
    title('Network robustness');
    legend({'Old', 'New'}, 'Location', 'northwest'); grid on;

    % (5) Max disconnection duration
    subplot(2, 3, 5);
    bar([comparison.tau_out_Old comparison.tau_out_New]);
    set(gca, 'XTickLabel', {'Old', 'New'});
    ylabel('Max disconnection (steps)');
    title(sprintf('Worst-case disconnection | Old=%d New=%d', ...
        comparison.tau_out_Old, comparison.tau_out_New));
    grid on;

    % (6) Coverage vs comm trade-off
    subplot(2, 3, 6);
    scatter(comparison.eta_B_Old, comparison.finalCovOld, 100, 'b', 'filled'); hold on;
    scatter(comparison.eta_B_New, comparison.finalCovNew, 100, 'r', 'filled');
    xlabel('\eta_B (basic service rate)'); ylabel('Final coverage');
    title('Coverage-Communication Pareto');
    legend({'Old', 'New'}, 'Location', 'best'); grid on;

    sgtitle('Communication Metrics Comparison Dashboard', 'FontSize', 14, 'FontWeight', 'bold');
    saveFigureLocal(fig, fullfile(cfg.outputDir, 'compare_comm_dashboard.png'));
    fprintf('  Comm dashboard saved\n');
end

function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
end
