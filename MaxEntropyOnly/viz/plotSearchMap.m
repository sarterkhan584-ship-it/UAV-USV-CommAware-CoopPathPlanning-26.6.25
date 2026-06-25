function plotSearchMap(islandMask, coveredGlobal, x, y, uavTrail, usvTrail, params)
    seaCovered = coveredGlobal & ~islandMask;
    islandCovered = coveredGlobal & islandMask;

    rgb = zeros([size(islandMask), 3]);
    rgb(:, :, 1) = 0.78 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
    rgb(:, :, 2) = 0.90 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
    rgb(:, :, 3) = 1.00 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;

    fig = figure('Color', 'w', 'Position', [80, 50, 980, 860]);
    image([x(1), x(end)], [y(1), y(end)], rgb);
    set(gca, 'YDir', 'normal');
    hold on;
    axis equal tight;
    box on;
    grid on;

    uavColor = [0.85 0.10 0.10; 0.65 0.00 0.75; 0.00 0.55 0.20; 0.80 0.35 0.00];
    usvColor = [0.00 0.40 0.95; 0.00 0.75 0.85; 0.25 0.25 0.25];

    nUAV = size(uavTrail, 2);
    nUSV = size(usvTrail, 2);

    h = zeros(nUAV + nUSV, 1);
    for i = 1:nUAV
        xi = squeeze(uavTrail(:, i, 1));
        yi = squeeze(uavTrail(:, i, 2));
        h(i) = plot(xi, yi, '-', 'Color', uavColor(i, :), 'LineWidth', 1.6);
        plot(xi(1), yi(1), 'o', 'Color', uavColor(i, :), 'MarkerFaceColor', uavColor(i, :), 'MarkerSize', 7);
    end

    for j = 1:nUSV
        xj = squeeze(usvTrail(:, j, 1));
        yj = squeeze(usvTrail(:, j, 2));
        h(nUAV + j) = plot(xj, yj, '--', 'Color', usvColor(j, :), 'LineWidth', 1.6);
        plot(xj(1), yj(1), '^', 'Color', usvColor(j, :), 'MarkerFaceColor', usvColor(j, :), 'MarkerSize', 7);
    end

    xlabel('X/km', 'FontSize', 12);
    ylabel('Y/km', 'FontSize', 12);
    title({'无人机-无人艇跨域协同搜索航迹（10 km × 10 km）', ...
           '无人艇已加入基于人工势场的岛屿威胁避障与评价函数惩罚项'}, 'FontSize', 13);
    legend(h, {'无人机1','无人机2','无人机3','无人机4','无人艇1','无人艇2','无人艇3'}, 'Location', 'eastoutside', 'FontSize', 10);
    xlim([0, params.mapLenKm]);
    ylim([0, params.mapLenKm]);

    saveFigureCompat(fig, 'search_tracks_full_map_v5.png');
end
