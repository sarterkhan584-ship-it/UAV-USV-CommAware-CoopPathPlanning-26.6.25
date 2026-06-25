function state = initializeImprovedState(state, islandMask, params)
% initializeImprovedState  通信自适应最大熵算法状态初始化

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
    state.smoothedEta = 1.0;

    for i = 1:state.nUAV
        [state, state.localUAV{i}, stat] = applyEntropyObservation( ...
            state.uavPos(i, :), state.uavPos(i, :), state, state.localUAV{i}, islandMask, params, 'uav');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
    end
    for j = 1:state.nUSV
        [state, state.localUSV{j}, stat] = applyEntropyObservation( ...
            state.usvPos(j, :), state.usvPos(j, :), state, state.localUSV{j}, islandMask, params, 'usv');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
    end

    [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
end
