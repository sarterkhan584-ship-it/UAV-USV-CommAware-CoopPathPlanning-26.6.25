function state = initializeCoverageState(state, islandMask, params)
% initializeCoverageState 初始化最大熵-信息素联合搜索所需的状态量。

    state.coveredGlobal = false(params.N, params.N);
    state.localUAV = cell(1, state.nUAV);
    state.localUSV = cell(1, state.nUSV);
    for i = 1:state.nUAV
        state.localUAV{i} = false(params.N, params.N);
    end
    for j = 1:state.nUSV
        state.localUSV{j} = false(params.N, params.N);
    end

    state.newCountCum = 0;
    state.repeatCountCum = 0;
    state.visitCountGlobal = zeros(params.N, params.N);
    state.entropyMap = ones(params.N, params.N);
    state.attractionPheromone = ones(params.N, params.N);
    state.repulsionPheromone = zeros(params.N, params.N);
    state.frontierMap = false(params.N, params.N);

    observedStepMask = false(params.N, params.N);

    for i = 1:state.nUAV
        [state, state.localUAV{i}, stat, obsMask] = applyEntropyPheromoneObservation( ...
            state.uavPos(i, :), state.uavPos(i, :), state, state.localUAV{i}, islandMask, params, 'uav');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        observedStepMask = observedStepMask | obsMask;
    end

    for j = 1:state.nUSV
        [state, state.localUSV{j}, stat, obsMask] = applyEntropyPheromoneObservation( ...
            state.usvPos(j, :), state.usvPos(j, :), state, state.localUSV{j}, islandMask, params, 'usv');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        observedStepMask = observedStepMask | obsMask;
    end

    state = updatePheromoneMaps(state, islandMask, observedStepMask, params);
    state.frontierMap = buildFrontierMap(state.coveredGlobal, islandMask, params);
    [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
end
