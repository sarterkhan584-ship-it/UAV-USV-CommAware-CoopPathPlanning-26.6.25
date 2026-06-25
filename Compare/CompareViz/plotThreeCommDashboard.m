function plotThreeCommDashboard(comparison, cfg)
% plotThreeCommDashboard  Three-algorithm communication dashboard (6 panels)

    if ~isfield(comparison, 'eta_B_Old')
        fprintf('  No comm metrics data, skipping dashboard\n');
        return;
    end

    fig = figure('Color', 'w', 'Position', [40, 40, 1800, 900]);

    % (1) Service rates
    subplot(2, 3, 1);
    barData = [comparison.eta_B_Old comparison.eta_B_Max comparison.eta_B_Improved; ...
               comparison.eta_L_Old comparison.eta_L_Max comparison.eta_L_Improved];
    b = bar(barData);
    b(1).FaceColor = [0.2 0.6 0.8]; b(2).FaceColor = [0.9 0.3 0.3]; b(3).FaceColor = [0.2 0.8 0.3];
    set(gca, 'XTickLabel', {'\eta_B (basic)', '\eta_L (LoS)'});
    ylabel('Service Rate'); ylim([0, 1.05]);
    title('Communication Service Rates');
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'northwest'); grid on;

    % (2) SINR & Data Rate
    subplot(2, 3, 2);
    yyaxis left;
    bar([1 2 3], [comparison.gamma_bar_Old comparison.gamma_bar_Max comparison.gamma_bar_Improved]);
    ylabel('SINR (dB)');
    yyaxis right;
    bar([4 5 6], [comparison.R_bar_Old comparison.R_bar_Max comparison.R_bar_Improved]);
    ylabel('Rate (kbps)');
    set(gca, 'XTick', [1 2 3 4 5 6], 'XTickLabel', {'\gamma_{Old}','\gamma_{Max}','\gamma_{CARS}','R_{Old}','R_{Max}','R_{CARS}'});
    title('Physical Layer Quality'); grid on;

    % (3) LoS ratio
    subplot(2, 3, 3);
    bar([comparison.rho_LoS_Old comparison.rho_LoS_Max comparison.rho_LoS_Improved]);
    set(gca, 'XTickLabel', {'Traditional', 'MaxEntropy', 'CARS'});
    ylabel('\rho_{LoS}'); ylim([0, 1.05]);
    title('LoS Link Ratio'); grid on;

    % (4) Algebraic connectivity
    subplot(2, 3, 4);
    bar([comparison.lambda2_B_Old comparison.lambda2_B_Max comparison.lambda2_B_Improved; ...
         comparison.lambda2_L_Old comparison.lambda2_L_Max comparison.lambda2_L_Improved]);
    set(gca, 'XTickLabel', {'\lambda_2^B', '\lambda_2^L'});
    ylabel('Algebraic Connectivity');
    title('Network Robustness'); grid on;
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'northwest');

    % (5) Max disconnection
    subplot(2, 3, 5);
    bar([comparison.tau_out_Old comparison.tau_out_Max comparison.tau_out_Improved]);
    set(gca, 'XTickLabel', {'Traditional', 'MaxEntropy', 'CARS'});
    ylabel('Max Disconnection (steps)');
    title(sprintf('Worst Disconnection: O=%d M=%d I=%d', ...
        comparison.tau_out_Old, comparison.tau_out_Max, comparison.tau_out_Improved));
    grid on;

    % (6) Coverage-Comm Pareto
    subplot(2, 3, 6);
    scatter(comparison.eta_B_Old, comparison.finalCovOld, 140, 'b', 'filled'); hold on;
    scatter(comparison.eta_B_Max, comparison.finalCovMax, 140, 'r', 'filled');
    scatter(comparison.eta_B_Improved, comparison.finalCovImproved, 140, 'g', 'filled');
    xlabel('\eta_B (Basic Service Rate)'); ylabel('Final Coverage');
    title('Coverage-Communication Pareto');
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'best'); grid on;

    sgtitle('Three-Algorithm Communication Dashboard', 'FontSize', 14, 'FontWeight', 'bold');
    saveFigureLocal(fig, fullfile(cfg.outputDir, 'three_compare_dashboard.png'));
    fprintf('  Three-algorithm dashboard saved\n');
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
