function cfg = getCompareConfig(rootDir)
% getCompareConfig 三算法对比试验配置（OldAlgorithm / NewAlgorithm / TerrainCommAlgorithm）

    cfg.rootDir = rootDir;
    cfg.compareOutputDir = fullfile(rootDir, 'CompareResults');
    cfg.oldOutputDir = fullfile(cfg.compareOutputDir, 'OldAlgorithm');
    cfg.newOutputDir = fullfile(cfg.compareOutputDir, 'EntropyPheromone');
    cfg.terrainOutputDir = fullfile(cfg.compareOutputDir, 'TerrainComm');
    if ~exist(cfg.compareOutputDir, 'dir'), mkdir(cfg.compareOutputDir); end
    if ~exist(cfg.oldOutputDir, 'dir'), mkdir(cfg.oldOutputDir); end
    if ~exist(cfg.newOutputDir, 'dir'), mkdir(cfg.newOutputDir); end
    if ~exist(cfg.terrainOutputDir, 'dir'), mkdir(cfg.terrainOutputDir); end

    cfg.snapshotSteps = [400, 800, 1200];
    cfg.coverageThreshold = 0.90;
    cfg.repeatThresholds = [0.45, 0.60, 0.85];
    cfg.maxRepeatDetection = 18;

    cfg.paramsOverride.maxSteps = max(cfg.snapshotSteps);
    cfg.paramsOverride.maxTime = [];
    cfg.paramsOverride.enableAnimation = true;
    cfg.paramsOverride.saveAnimationVideo = true;
    cfg.paramsOverride.skipIndividualPlots = true;
    cfg.paramsOverride.stopAtTarget = true;
    cfg.paramsOverride.targetCoverage = cfg.coverageThreshold;

    % 对比动态可视化设置
    cfg.enableComparisonAnimation = true;
    cfg.comparisonAnimationStride = 5;
    cfg.comparisonAnimationPause = 0.001;
    cfg.saveComparisonAnimationVideo = true;
    cfg.comparisonMapVideoName = fullfile(cfg.compareOutputDir, '动态航迹对比.mp4');
    cfg.comparisonCurveVideoName = fullfile(cfg.compareOutputDir, '覆盖率动态对比.mp4');
end