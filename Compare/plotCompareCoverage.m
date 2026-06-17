function plotCompareCoverage(comparison, cfg)
% plotCompareCoverage  绘制两个算法的覆盖率曲线对比
% 独立性：不依赖任何自定义函数，纯基础MATLAB

    oldCov = comparison.old.coverageHist;
    newCov = comparison.new.coverageHist;
    oldIsland = comparison.old.islandCoverageHist;
    newIsland = comparison.new.islandCoverageHist;

    maxLen = min(numel(oldCov), numel(newCov));
    t = (0:maxLen-1) * 10;

    fig = figure('Position', [100, 100, 1200, 500]);

    subplot(1, 2, 1);
    plot(t, oldCov(1:maxLen)*100, 'b-', 'LineWidth', 1.5); hold on;
    plot(t, newCov(1:maxLen)*100, 'r-', 'LineWidth', 1.5);
    yline(cfg.targetCoverage*100, 'k--', 'LineWidth', 1);
    xlabel('时间 (s)'); ylabel('覆盖率 (%)');
    title('总覆盖率对比');
    legend({'老算法', '新算法', '目标'}, 'Location', 'southeast');
    grid on;

    subplot(1, 2, 2);
    plot(t, oldIsland(1:maxLen)*100, 'b-', 'LineWidth', 1.5); hold on;
    plot(t, newIsland(1:maxLen)*100, 'r-', 'LineWidth', 1.5);
    xlabel('时间 (s)'); ylabel('覆盖率 (%)');
    title('岛屿覆盖率对比');
    legend({'老算法', '新算法'}, 'Location', 'southeast');
    grid on;

    sgtitle('搜索覆盖率对比（增强版通信建模）');
    drawnow;

    saveas(fig, fullfile(cfg.outputDir, 'compare_coverage.png'));
    fprintf('  覆盖率对比图已保存\n');
end
