function state = initializePlatforms(params)
% initializePlatforms 初始化 UAV/USV 的位置、航向与轨迹缓存

    state.uavPos = [1.0, 0.0; 2.0, 0.0; 1.5, 0.0; 1.3, 0.0];
    state.usvPos = [2.0, 0.5; 2.2, 0.5; 2.5, 0.5];

    state.nUAV = size(state.uavPos, 1);
    state.nUSV = size(state.usvPos, 1);

    state.uavPsi = pi/2 * ones(state.nUAV, 1);
    state.usvPsi = pi/2 * ones(state.nUSV, 1);

    state.uavTrail = zeros(params.maxSteps + 1, state.nUAV, 2);
    state.usvTrail = zeros(params.maxSteps + 1, state.nUSV, 2);
    state.uavTrail(1, :, :) = state.uavPos;
    state.usvTrail(1, :, :) = state.usvPos;
end
