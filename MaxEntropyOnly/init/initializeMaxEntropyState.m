function state = initializeMaxEntropyState(state, islandMask, params)
% initializeMaxEntropyState  初始化最大熵算法所需的状态量（无信息素/前沿）。

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
    state.entropyMap = ones(params.N, params.N);   % 最大熵机制的核心

    % 执行初始条带观测
    observedStepMask = false(params.N, params.N);
    for i = 1:state.nUAV
        [state, state.localUAV{i}, stat, obsMask] = applyEntropyObservation( ...
            state.uavPos(i, :), state.uavPos(i, :), state, state.localUAV{i}, islandMask, params, 'uav');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        observedStepMask = observedStepMask | obsMask;
    end
    for j = 1:state.nUSV
        [state, state.localUSV{j}, stat, obsMask] = applyEntropyObservation( ...
            state.usvPos(j, :), state.usvPos(j, :), state, state.localUSV{j}, islandMask, params, 'usv');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
        observedStepMask = observedStepMask | obsMask;
    end

    % 初始信息融合
    [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
end
