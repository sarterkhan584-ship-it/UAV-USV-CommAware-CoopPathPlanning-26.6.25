function plotCompareCommCurves(comparison, cfg)
% plotCompareCommCurves  Overlay communication metric curves for both algorithms
% 独立性: pure MATLAB

    if ~isfield(comparison.old, 'sinrHist')
        return;
    end

    oldS = comparison.old;
    newS = comparison.new;
    nO = min(numel(oldS.sinrHist), numel(oldS.coverageHist));
    nN = min(numel(newS.sinrHist), numel(newS.coverageHist));
    n = min(nO, nN);
    t = (0:n-1) * 10;

    fig = figure('Color', 'w', 'Position', [80, 60, 1400, 600]);

    % SINR
    subplot(2, 3, 1);
    plot(t, oldS.sinrHist(1:n), 'b-', 'LineWidth', 1.2); hold on;
    plot(t, newS.sinrHist(1:n), 'r--', 'LineWidth', 1.2);
    xlabel('time (s)'); ylabel('SINR (dB)'); title('Average SINR');
    legend({'Old', 'New'}, 'Location', 'best'); grid on;

    % Data rate
    subplot(2, 3, 2);
    plot(t, oldS.dataRateHist(1:n), 'b-', 'LineWidth', 1.2); hold on;
    plot(t, newS.dataRateHist(1:n), 'r--', 'LineWidth', 1.2);
    xlabel('time (s)'); ylabel('Rate (kbps)'); title('Average Data Rate');
    legend({'Old', 'New'}, 'Location', 'best'); grid on;

    % LoS ratio
    subplot(2, 3, 3);
    plot(t, oldS.losRatioHist(1:n), 'b-', 'LineWidth', 1.2); hold on;
    plot(t, newS.losRatioHist(1:n), 'r--', 'LineWidth', 1.2);
    xlabel('time (s)'); ylabel('LoS ratio'); title('LoS Link Ratio');
    legend({'Old', 'New'}, 'Location', 'best'); grid on;

    % Blocked ratio
    subplot(2, 3, 4);
    plot(t, oldS.blockedRatioHist(1:n), 'b-', 'LineWidth', 1.2); hold on;
    plot(t, newS.blockedRatioHist(1:n), 'r--', 'LineWidth', 1.2);
    xlabel('time (s)'); ylabel('Blocked ratio'); title('Blocked Link Ratio');
    legend({'Old', 'New'}, 'Location', 'best'); grid on;

    % lambda2_B
    if isfield(oldS, 'lambda2_B_Hist') && isfield(newS, 'lambda2_B_Hist')
        subplot(2, 3, 5);
        nL = min(numel(oldS.lambda2_B_Hist), numel(newS.lambda2_B_Hist));
        tL = (0:nL-1) * 10;
        plot(tL, oldS.lambda2_B_Hist(1:nL), 'b-', 'LineWidth', 1.2); hold on;
        plot(tL, newS.lambda2_B_Hist(1:nL), 'r--', 'LineWidth', 1.2);
        xlabel('time (s)'); ylabel('\lambda_2'); title('G^B Algebraic Connectivity');
        legend({'Old', 'New'}, 'Location', 'best'); grid on;
    end

    % Connected UAV count
    subplot(2, 3, 6);
    plot(t, oldS.connectedAnyCountHist(1:n), 'b-', 'LineWidth', 1.2); hold on;
    plot(t, newS.connectedAnyCountHist(1:n), 'r--', 'LineWidth', 1.2);
    xlabel('time (s)'); ylabel('Count'); title('Connected UAV Count');
    legend({'Old', 'New'}, 'Location', 'best'); grid on;

    sgtitle('Communication Metrics Time Curves Comparison', 'FontSize', 13, 'FontWeight', 'bold');
    saveFigureLocal(fig, fullfile(cfg.outputDir, 'compare_comm_curves.png'));
    fprintf('  Comm curves saved\n');
end

function saveFigureLocal(fig, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(fig, fileName, 'Resolution', 300);
    else
        saveas(fig, fileName);
    end
end
