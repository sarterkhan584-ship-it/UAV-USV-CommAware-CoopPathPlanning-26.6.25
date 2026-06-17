function cfg = getCompareConfig()
% getCompareConfig  对比实验配置

    rootDir = fileparts(mfilename('fullpath'));
    cfg.outputDir = fullfile(rootDir, 'CompareResults');
    cfg.snapshotSteps = [400, 800, 1200];
    cfg.targetCoverage = 0.90;
    cfg.repeatThresholds = [0.45, 0.60, 0.85];
    cfg.maxRepeats = 18;
    % cfg.enableAnimation = false;
    cfg.enableAnimation = true;
    cfg.skipIndividualPlots = true;
    % cfg.stopAtTarget = false;
    cfg.stopAtTarget = true;
    cfg.maxSteps = 1200;
    cfg.comparisonStride = 5;
    cfg.comparisonPause = 0.001;
    % cfg.enableCompareVideo = false;
    cfg.enableCompareVideo = true;
    cfg.mapSeed = 1;
end
