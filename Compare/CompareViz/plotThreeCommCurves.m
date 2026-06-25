function plotThreeCommCurves(comparison, cfg)
% plotThreeCommCurves  Three-algorithm communication time-series overlay

    o = comparison.old;
    m = comparison.max;
    i = comparison.improved;

    maxLen = min([numel(o.sinrHist), numel(m.sinrHist), numel(i.sinrHist)]);
    if maxLen < 2, return; end
    t = (0:maxLen-1) * 10;

    fig = figure('Color', 'w', 'Position', [40, 40, 1600, 900]);

    % SINR
    subplot(2, 3, 1);
    plot(t, o.sinrHist(1:maxLen), 'b-', 'LineWidth', 1.5); hold on;
    plot(t, m.sinrHist(1:maxLen), 'r-', 'LineWidth', 1.5);
    plot(t, i.sinrHist(1:maxLen), 'g-', 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('SINR (dB)'); title('Mean SINR');
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'best'); grid on;

    % Data rate
    subplot(2, 3, 2);
    plot(t, o.dataRateHist(1:maxLen), 'b-', 'LineWidth', 1.5); hold on;
    plot(t, m.dataRateHist(1:maxLen), 'r-', 'LineWidth', 1.5);
    plot(t, i.dataRateHist(1:maxLen), 'g-', 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('Rate (kbps)'); title('Mean Data Rate'); grid on;

    % LoS ratio
    subplot(2, 3, 3);
    if isfield(o, 'losRatioHist')
        plot(t, o.losRatioHist(1:maxLen), 'b-', 'LineWidth', 1.5); hold on;
        plot(t, m.losRatioHist(1:maxLen), 'r-', 'LineWidth', 1.5);
        plot(t, i.losRatioHist(1:maxLen), 'g-', 'LineWidth', 1.8);
        xlabel('Time (s)'); ylabel('LoS Ratio'); title('LoS Link Ratio'); grid on;
    end

    % Algebraic connectivity
    subplot(2, 3, 4);
    lam2_o = o.lambda2_B_Hist; lam2_m = m.lambda2_B_Hist; lam2_i = i.lambda2_B_Hist;
    maxL = min([numel(lam2_o), numel(lam2_m), numel(lam2_i)]);
    plot((0:maxL-1)*10, lam2_o(1:maxL), 'b-', 'LineWidth', 1.5); hold on;
    plot((0:maxL-1)*10, lam2_m(1:maxL), 'r-', 'LineWidth', 1.5);
    plot((0:maxL-1)*10, lam2_i(1:maxL), 'g-', 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('\lambda_2^B'); title('Algebraic Connectivity'); grid on;

    % Connected UAV count
    subplot(2, 3, 5);
    plot(t, o.connectedAnyCountHist(1:maxLen), 'b-', 'LineWidth', 1.5); hold on;
    plot(t, m.connectedAnyCountHist(1:maxLen), 'r-', 'LineWidth', 1.5);
    plot(t, i.connectedAnyCountHist(1:maxLen), 'g-', 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('Connected UAVs'); title('Connected UAV Count'); grid on;

    % Repeat rate
    subplot(2, 3, 6);
    plot(t, o.repeatRateHist(1:maxLen)*100, 'b-', 'LineWidth', 1.5); hold on;
    plot(t, m.repeatRateHist(1:maxLen)*100, 'r-', 'LineWidth', 1.5);
    plot(t, i.repeatRateHist(1:maxLen)*100, 'g-', 'LineWidth', 1.8);
    xlabel('Time (s)'); ylabel('Repeat Rate (%)'); title('Repeat Search Rate'); grid on;

    sgtitle('Three-Algorithm Communication Time Series', 'FontSize', 14, 'FontWeight', 'bold');
    saveFigureLocal(fig, fullfile(cfg.outputDir, 'three_compare_comm_curves.png'));
    fprintf('  Three-algorithm comm curves saved\n');
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
