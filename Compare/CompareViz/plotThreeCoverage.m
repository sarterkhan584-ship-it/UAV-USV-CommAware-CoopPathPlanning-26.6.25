function plotThreeCoverage(comparison, cfg)
% plotThreeCoverage  三算法覆盖率曲线对比
%  传统算法(blue) vs 最大熵算法(red) vs CARS算法(green)

    oldCov  = comparison.old.coverageHist;
    maxCov  = comparison.max.coverageHist;
    impCov  = comparison.improved.coverageHist;
    oldIsl  = comparison.old.islandCoverageHist;
    maxIsl  = comparison.max.islandCoverageHist;
    impIsl  = comparison.improved.islandCoverageHist;

    maxLen = min([numel(oldCov), numel(maxCov), numel(impCov)]);
    t = (0:maxLen-1) * 10;

    fig = figure('Position', [100, 100, 1400, 550]);

    subplot(1, 3, 1);
    plot(t, oldCov(1:maxLen)*100, 'b-', 'LineWidth', 1.8); hold on;
    plot(t, maxCov(1:maxLen)*100, 'r-', 'LineWidth', 1.8);
    plot(t, impCov(1:maxLen)*100, 'g-', 'LineWidth', 2.0);
    yline(cfg.targetCoverage*100, 'k--', 'LineWidth', 1);
    xlabel('time (s)'); ylabel('coverage (%)');
    title('Total Coverage Comparison');
    legend({'Traditional', 'MaxEntropy', 'CARS', 'Target'}, 'Location', 'southeast');
    grid on;

    subplot(1, 3, 2);
    plot(t, oldIsl(1:maxLen)*100, 'b-', 'LineWidth', 1.8); hold on;
    plot(t, maxIsl(1:maxLen)*100, 'r-', 'LineWidth', 1.8);
    plot(t, impIsl(1:maxLen)*100, 'g-', 'LineWidth', 2.0);
    xlabel('time (s)'); ylabel('coverage (%)');
    title('Island Coverage Comparison');
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'southeast');
    grid on;

    subplot(1, 3, 3);
    scatter(comparison.repeatRateOld, comparison.finalCovOld, 120, 'b', 'filled'); hold on;
    scatter(comparison.repeatRateMax, comparison.finalCovMax, 120, 'r', 'filled');
    scatter(comparison.repeatRateImproved, comparison.finalCovImproved, 120, 'g', 'filled');
    xlabel('Repeat Rate'); ylabel('Final Coverage');
    title('Efficiency: Coverage vs Repeat Rate');
    legend({'Traditional', 'MaxEntropy', 'CARS'}, 'Location', 'best');
    grid on;

    sgtitle('Three-Algorithm Coverage: Traditional vs MaxEntropy vs CARS');
    saveFigureLocal(fig, fullfile(cfg.outputDir, 'three_compare_coverage.png'));
    fprintf('  Three-algorithm coverage chart saved\n');
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
