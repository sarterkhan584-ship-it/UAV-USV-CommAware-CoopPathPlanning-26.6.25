function params = getDefaultParams()
    params.mapLenKm = 10.0;
    params.dx = 0.05;                  % 50 m = 0.05 km
    params.N = round(params.mapLenKm / params.dx);
    params.mapSeed = 1;

    params.dt = 10;
    params.maxTime = 6000;
    params.maxSteps = 600;
    params.targetCoverage = 0.90;

    params.enableAnimation = true;
    params.skipIndividualPlots = false;
    params.stopAtTarget = true;
    params.outputDir = '';
    params.animationPause = 0.01;
    params.saveAnimationVideo = true;
    params.animationVideoName = 'dynamic_search_visualization_v5.mp4';
    params.animationFrameRate = 12;
    params.connectedUAVColor = [1.00, 0.90, 0.10];

    params.vUAV = 20 / 1000;
    params.vUSV = 10 / 1000;
    params.turnCandidatesUAV = deg2rad([-45, -30, -15, 0, 15, 30, 45]);
    params.turnCandidatesUSV = deg2rad([-45, -30, -15, 0, 15, 30, 45]);

    params.sensorStripWidthUAVKm = 0.30;
    params.sensorStripWidthUSVKm = 0.15;
    params.commRangeKm = 3.50;
    params.commUpdateEvery = 3;

    params.spreadRefUAV = 0.80;
    params.spreadRefUSV = 0.60;

    params.islandStageThreshold = 0.80;

    % ---------- USV 岛屿人工势场参数 ----------
    params.usvThreatInfluenceKm = 0.45;
    params.usvHardClearanceKm = 0.03;
    params.usvThreatWeight = 0.90;
    params.usvAPFAlignWeight = 0.25;
    params.usvThreatEpsKm = 0.01;

    % ---------- 物理层信道参数 ----------
    params.f_c_GHz = 2.4;
    params.lambda_m = 0.125;           % c / f_c
    params.P_t_mW = 500;               % 发射功率 500 mW
    params.B_MHz = 1;                  % 带宽 1 MHz
    params.k_B = 1.38e-23;             % 玻尔兹曼常数
    params.T0_K = 290;                 % 标准温度
    params.NF_dB = 10;                 % 接收机噪声系数
    % 有效噪声功率谱密度: N0 = k*T*10^(NF/10) = 4e-21 * 10 = 4e-20 W/Hz
    params.G_t_dBi = 0;                % 发射天线增益
    params.G_r_dBi = 0;                % 接收天线增益
    params.d0_m = 5;                   % 参考距离
    params.alpha_L = 2.0;              % LoS路径损耗指数
    params.alpha_N = 3.5;              % NLoS路径损耗指数
    params.L_NLoS_extra_dB = 15;       % NLoS额外穿透损耗
    params.kappa_terrain_dB_per_m = 0.5;

    % ---------- 通信判定阈值 ----------
    params.gamma_th_dB = 10;
    params.R_min_kbps = 100;
    params.D_max_km = 3.5;
    params.commTerrainClearanceKm = 0.030;

    % ---------- 通信硬约束参数 ----------
    params.eta_B_min = 0.85;
    params.tau_max_steps = 30;
    params.hardConstraintEnabled = true;
    params.constraintRelaxFactor = 0.5;

    % ---------- 路径质量权重 ----------
    params.w_gamma_path = 0.4;
    params.w_R_path = 0.3;
    params.w_L_path = 0.3;

    % ---------- 地形DEM参数 ----------
    params.terrainSeedOffset = 200;
    params.terrainMaxElevationKm = 0.42;
    params.terrainPeakCount = 24;
    params.terrainPeakSigmaMinKm = 0.18;
    params.terrainPeakSigmaMaxKm = 0.52;
    params.terrainRidgeLengthKm = 2.8;
    params.terrainRidgeWidthKm = 0.65;
    params.terrainCoastTaperKm = 0.45;
    params.terrainSmoothRadiusCells = 3;
    params.uavCruiseAltitudeKm = 0.62;
    params.uavTerrainClearanceKm = 0.18;

    % ---------- UAV 地形人工势场参数 ----------
    params.terrainAPFWeightUAV = 15;
    params.terrainInfluenceKm = 0.5;
    params.minTerrainClearanceKm = 0.10;
end
