function plotCompareTrails(mapData, resultsOld, resultsNew, cfg)
% plotCompareTrails  并排绘制两个算法的最终航迹图
% 独立性：纯基础MATLAB（内嵌buildCoverageRGB逻辑）

    islandMask = mapData.islandMask;
    coveredOld = resultsOld.coveredGlobal;
    coveredNew = resultsNew.coveredGlobal;
    x = mapData.xGrid;
    y = mapData.yGrid;

    rgbOld = makeRgb(islandMask, coveredOld);
    rgbNew = makeRgb(islandMask, coveredNew);

    fig = figure('Position', [50, 50, 1400, 650]);

    subplot(1, 2, 1);
    image(x, y, rgbOld); hold on;
    set(gca, 'YDir', 'normal');
    for i = 1:size(resultsOld.uavTrail, 2)
        trail = squeeze(resultsOld.uavTrail(:, i, :));
        plot(trail(:,1), trail(:,2), 'LineWidth', 1.2);
        plot(trail(1,1), trail(1,2), 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'w');
    end
    axis equal tight;
    title(sprintf('老算法 (覆盖率: %.1f%%)', resultsOld.finalCoverage*100));

    subplot(1, 2, 2);
    image(x, y, rgbNew); hold on;
    set(gca, 'YDir', 'normal');
    for i = 1:size(resultsNew.uavTrail, 2)
        trail = squeeze(resultsNew.uavTrail(:, i, :));
        plot(trail(:,1), trail(:,2), 'LineWidth', 1.2);
        plot(trail(1,1), trail(1,2), 'o', 'MarkerSize', 6, 'MarkerFaceColor', 'w');
    end
    axis equal tight;
    title(sprintf('新算法 (覆盖率: %.1f%%)', resultsNew.finalCoverage*100));

    sgtitle('UAV航迹与最终覆盖对比');
    drawnow;

    saveas(fig, fullfile(cfg.outputDir, 'compare_trails.png'));
    fprintf('  航迹对比图已保存\n');
end

function rgb = makeRgb(islandMask, coveredGlobal)
    rgb = zeros([size(islandMask), 3]);
    for r = 1:size(islandMask,1)
        for c = 1:size(islandMask,2)
            if islandMask(r,c)
                if coveredGlobal(r,c)
                    rgb(r,c,:) = [0.55, 0.55, 0.55];
                else
                    rgb(r,c,:) = [0, 0, 0];
                end
            else
                if coveredGlobal(r,c)
                    rgb(r,c,:) = [1, 1, 1];
                else
                    rgb(r,c,:) = [0.78, 0.90, 1.00];
                end
            end
        end
    end
end
