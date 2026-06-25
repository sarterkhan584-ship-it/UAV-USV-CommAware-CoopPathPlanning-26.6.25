function plotCoverageCurve(coverageHist, seaCoverageHist, islandCoverageHist, repeatRateHist, params)
    t = (0:numel(coverageHist)-1) * params.dt;

    fig = figure('Color', 'w', 'Position', [110, 90, 920, 620]);
    plot(t, 100 * coverageHist, 'k-', 'LineWidth', 2.2); hold on;
    plot(t, 100 * seaCoverageHist, '--', 'Color', [0.00 0.45 0.80], 'LineWidth', 1.6);
    plot(t, 100 * islandCoverageHist, '--', 'Color', [0.85 0.33 0.10], 'LineWidth', 1.6);
    plot(t, 100 * repeatRateHist, ':', 'Color', [0.50 0.00 0.50], 'LineWidth', 1.8);
    plot([t(1), t(end)], 100 * params.targetCoverage * [1, 1], '-.', 'Color', [0.35 0.35 0.35], 'LineWidth', 1.2);
    grid on; box on;
    xlabel('时间/s', 'FontSize', 12);
    ylabel('比例/%', 'FontSize', 12);
    title('全地图覆盖率与重复搜索率曲线', 'FontSize', 13);
    legend({'全地图覆盖率', '海面覆盖率', '岛屿覆盖率', '重复搜索率', '90%终止阈值'}, ...
        'Location', 'southeast', 'FontSize', 10);
    saveFigureCompat(fig, 'coverage_curve_v5.png');
end
