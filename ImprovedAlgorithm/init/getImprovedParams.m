function params = getImprovedParams()
% getImprovedParams  通信增强最大熵算法参数
% 关键改进：USV纯中继化 + 每秒融合 + 更大通信范围
    params.mapLenKm = 10.0; params.dx = 0.05;
    params.N = round(params.mapLenKm / params.dx); params.mapSeed = 1;
    params.dt = 10; params.maxTime = 6000;
    params.maxSteps = 600; params.targetCoverage = 0.90;
    params.enableAnimation = true; params.skipIndividualPlots = false;
    params.stopAtTarget = true; params.outputDir = '';
    params.saveAnimationVideo = true;
    params.animationVideoName = 'improved_search.mp4';
    params.animationPause = 0.01; params.animationFrameRate = 12;
    params.connectedUAVColor = [1.00, 0.90, 0.10];
    params.vUAV = 20/1000; params.vUSV = 10/1000;
    params.turnCandidatesUAV = deg2rad([-45,-30,-15,0,15,30,45]);
    params.turnCandidatesUSV = deg2rad([-45,-30,-15,0,15,30,45]);
    params.sensorStripWidthUAVKm = 0.30;
    params.sensorStripWidthUSVKm = 0.15;
    params.commRangeKm = 5.00;       % 扩大通信范围
    params.commUpdateEvery = 1;       % 每步融合（关键改进）
    params.spreadRefUAV = 0.80; params.spreadRefUSV = 0.60;
    params.islandStageThreshold = 0.80;
    % USV APF
    params.usvThreatInfluenceKm = 0.45; params.usvHardClearanceKm = 0.03;
    params.usvThreatWeight = 0.90; params.usvAPFAlignWeight = 0.25;
    params.usvThreatEpsKm = 0.01;
    % 物理层
    params.f_c_GHz = 2.4; params.lambda_m = 0.125; params.P_t_mW = 500;
    params.B_MHz = 1; params.k_B = 1.38e-23; params.T0_K = 290;
    params.NF_dB = 10; params.G_t_dBi = 0; params.G_r_dBi = 0;
    params.d0_m = 5; params.alpha_L = 2.0; params.alpha_N = 3.5;
    params.L_NLoS_extra_dB = 15; params.kappa_terrain_dB_per_m = 0.5;
    params.gamma_th_dB = 10; params.R_min_kbps = 100;
    params.D_max_km = 5.0; params.commTerrainClearanceKm = 0.030;
    params.eta_B_min = 0.85; params.tau_max_steps = 30;
    params.hardConstraintEnabled = true; params.constraintRelaxFactor = 0.5;
    params.w_gamma_path = 0.4; params.w_R_path = 0.3; params.w_L_path = 0.3;
    % 地形
    params.terrainSeedOffset = 200; params.terrainMaxElevationKm = 0.42;
    params.terrainPeakCount = 24; params.terrainPeakSigmaMinKm = 0.18;
    params.terrainPeakSigmaMaxKm = 0.52; params.terrainRidgeLengthKm = 2.8;
    params.terrainRidgeWidthKm = 0.65; params.terrainCoastTaperKm = 0.45;
    params.terrainSmoothRadiusCells = 3;
    params.uavCruiseAltitudeKm = 0.62; params.uavTerrainClearanceKm = 0.18;
    params.terrainAPFWeightUAV = 15; params.terrainInfluenceKm = 0.5;
    params.minTerrainClearanceKm = 0.10;
    % 最大熵
    params.entropyAlpha = log(1.8);
    params.visitPenaltyPower = 1.25;
    params.lambdaCMin = 0.45;  params.lambdaCMax = 1.30;
    params.lambdaHMin = 0.10;  params.lambdaHMax = 1.20;
    params.lambdaRMin = 0.50;  params.lambdaRMax = 1.80;
    params.dynamicWeightPower = 1.6;
    params.boundaryPotentialWeightUAV = 3.5;
    params.boundaryPotentialWeightUSV = 1.5;
    params.boundaryEpsKm = 0.06;
    % 通信自适应 - relay/spread 权重依 eta_B 调制
    params.etaSmoothing = 0.2;
    params.commAdaptTarget = 0.75;
    params.relaySensitivity = 1.0;
    params.spreadSensitivity = 0.6;
    params.relayWeightUAV_base = 25;
    params.spreadWeightUAV_base = 20;
    params.smoothWeightUAV = 8;
    % USV 偏重中继
    params.usvCovWeight = 0.3;
    params.usvRelayWeight = 60;
    params.usvSpreadWeight = 15;
    params.usvSmoothWeight = 14;
end
