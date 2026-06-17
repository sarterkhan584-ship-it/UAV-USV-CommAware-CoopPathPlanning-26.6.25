function state = updatePheromoneMaps(state, islandMask, observedStepMask, params)
% updatePheromoneMaps 更新吸引信息素和排斥信息素。
% 吸引信息素在未覆盖区域维持高值；排斥信息素在已探测区域沉积并挥发扩散。

    uncovered = ~state.coveredGlobal;
    attr = state.attractionPheromone;
    rep = state.repulsionPheromone;

    attr = (1 - params.attractEvap) * attr + params.attractDeposit * double(uncovered);
    rep = (1 - params.repulseEvap) * rep + params.repulseDeposit * double(observedStepMask);

    if params.pheromoneDiffuse > 0
        kernel = [0 1 0; 1 0 1; 0 1 0] / 4;
        attr = (1 - params.pheromoneDiffuse) * attr + params.pheromoneDiffuse * conv2(attr, kernel, 'same');
        rep = (1 - params.pheromoneDiffuse) * rep + params.pheromoneDiffuse * conv2(rep, kernel, 'same');
    end

    attr(islandMask & state.coveredGlobal) = 0.25 * attr(islandMask & state.coveredGlobal);
    attr = max(0, min(attr, 5));
    rep = max(0, min(rep, 20));

    state.attractionPheromone = attr;
    state.repulsionPheromone = rep;
end
