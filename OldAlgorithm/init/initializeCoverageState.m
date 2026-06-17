function state = initializeCoverageState(state, islandMask, params)
% initializeCoverageState 初始化全局覆盖图、本地认知图与初始覆盖统计

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

    for i = 1:state.nUAV
        [state.coveredGlobal, state.localUAV{i}, stat] = applyStripObservation( ...
            state.uavPos(i, :), state.uavPos(i, :), state.coveredGlobal, state.localUAV{i}, islandMask, params, 'uav');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
    end

    for j = 1:state.nUSV
        [state.coveredGlobal, state.localUSV{j}, stat] = applyStripObservation( ...
            state.usvPos(j, :), state.usvPos(j, :), state.coveredGlobal, state.localUSV{j}, islandMask, params, 'usv');
        state.newCountCum = state.newCountCum + stat.newCount;
        state.repeatCountCum = state.repeatCountCum + stat.repeatCount;
    end

    [state.localUAV, state.localUSV] = fuseByUSVRelay(state.localUAV, state.localUSV, state.uavPos, state.usvPos, params);
end
