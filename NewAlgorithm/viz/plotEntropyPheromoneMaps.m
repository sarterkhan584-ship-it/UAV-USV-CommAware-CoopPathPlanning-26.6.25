function plotEntropyPheromoneMaps(state, islandMask, x, y, params)
% plotEntropyPheromoneMaps 绘制最大熵-信息素联合搜索的末态地图。

    fig = figure('Color', 'w', 'Position', [120, 80, 1200, 360]);

    subplot(1,3,1);
    imagesc([x(1), x(end)], [y(1), y(end)], state.entropyMap);
    set(gca, 'YDir', 'normal'); axis equal tight; box on; grid on; colorbar;
    title('末态信息熵场'); xlabel('X/km'); ylabel('Y/km');

    subplot(1,3,2);
    imagesc([x(1), x(end)], [y(1), y(end)], state.attractionPheromone);
    set(gca, 'YDir', 'normal'); axis equal tight; box on; grid on; colorbar;
    title('吸引信息素'); xlabel('X/km'); ylabel('Y/km');

    subplot(1,3,3);
    rep = state.repulsionPheromone;
    rep(islandMask & ~state.coveredGlobal) = NaN;
    imagesc([x(1), x(end)], [y(1), y(end)], rep);
    set(gca, 'YDir', 'normal'); axis equal tight; box on; grid on; colorbar;
    title('排斥信息素'); xlabel('X/km'); ylabel('Y/km');

    saveFigureCompat(fig, 'entropy_pheromone_maps.png');
end
