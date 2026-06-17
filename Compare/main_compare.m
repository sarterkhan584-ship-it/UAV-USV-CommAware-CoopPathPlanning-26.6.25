function main_compare()
% main_compare  对比运行增强版老算法与增强版新算法
%
%  两个算法共享相同的初始条件设定，
%  在相同的通信能力模型（SINR + 双层图 + 8项指标）下对比。
%  仅路径规划策略不同：
%    - OldAlgorithm: 阶段权重 + 拓扑引导
%    - NewAlgorithm: 最大熵-信息素 + 动态权重

    clear; clc; close all;

    rootDir = fileparts(mfilename('fullpath'));
    projectRoot = fileparts(rootDir);

    % 将 CompareViz 加入路径
    addpath(fullfile(rootDir, 'CompareViz'));

    % 加载对比配置
    cfg = getCompareConfig();

    % 确保输出目录存在
    if ~exist(cfg.outputDir, 'dir')
        mkdir(cfg.outputDir);
    end

    fprintf('========================================\n');
    fprintf('  跨域协同搜索算法对比实验\n');
    fprintf('  地形感知通信建模 (SINR + 双层图 + 8项指标)\n');
    fprintf('========================================\n\n');

    % 设置公共输出目录
    oldOutDir = fullfile(cfg.outputDir, 'OldAlgorithm');
    newOutDir = fullfile(cfg.outputDir, 'NewAlgorithm');

    % --- 运行增强版老算法 ---
    fprintf('>>> [1/2] 运行增强版老算法（拓扑法）...\n');
    oldEntry = fullfile(projectRoot, 'OldAlgorithm', 'runOldAlgorithm.m');
    if ~exist(oldEntry, 'file')
        error('找不到 OldAlgorithm/runOldAlgorithm.m');
    end
    oldRunner = fullfile(projectRoot, 'OldAlgorithm');
    oldPwd = pwd;
    cd(oldRunner);
    try
        oldParams = getDefaultParams();
        oldParams.enableAnimation = cfg.enableAnimation;
        oldParams.skipIndividualPlots = cfg.skipIndividualPlots;
        if ~isempty(cfg.maxSteps)
            oldParams.maxSteps = cfg.maxSteps;
            oldParams.maxTime = cfg.maxSteps * oldParams.dt;
        end
        if ~isempty(cfg.targetCoverage)
            oldParams.targetCoverage = cfg.targetCoverage;
        end
        oldParams.stopAtTarget = cfg.stopAtTarget;
        oldParams.outputDir = oldOutDir;
        oldParams.mapSeed = cfg.mapSeed;
        tic;
        [resultsOld, paramsOld, mapStatsOld, mapDataOld] = runOldAlgorithm(oldParams);
        toc;
        resultsOld.algorithmName = '老算法（拓扑引导）';
    catch ME
        cd(oldPwd);
        rethrow(ME);
    end
    cd(oldPwd);
    fprintf('  老算法完成。\n\n');

    % --- 运行增强版新算法 ---
    fprintf('>>> [2/2] 运行增强版新算法（最大熵-信息素法）...\n');
    newEntry = fullfile(projectRoot, 'NewAlgorithm', 'runNewAlgorithm.m');
    if ~exist(newEntry, 'file')
        error('找不到 NewAlgorithm/runNewAlgorithm.m');
    end
    newRunner = fullfile(projectRoot, 'NewAlgorithm');
    cd(newRunner);
    try
        newParams = getDefaultParams();
        newParams.enableAnimation = cfg.enableAnimation;
        newParams.skipIndividualPlots = cfg.skipIndividualPlots;
        if ~isempty(cfg.maxSteps)
            newParams.maxSteps = cfg.maxSteps;
            newParams.maxTime = cfg.maxSteps * newParams.dt;
        end
        if ~isempty(cfg.targetCoverage)
            newParams.targetCoverage = cfg.targetCoverage;
        end
        newParams.stopAtTarget = cfg.stopAtTarget;
        newParams.outputDir = newOutDir;
        newParams.mapSeed = cfg.mapSeed;
        tic;
        [resultsNew, paramsNew, mapStatsNew, mapDataNew] = runNewAlgorithm(newParams);
        toc;
        resultsNew.algorithmName = '新算法（最大熵-信息素）';
    catch ME
        cd(oldPwd);
        rethrow(ME);
    end
    cd(oldPwd);
    fprintf('  新算法完成。\n\n');

    % --- 对比分析与可视化 ---
    fprintf('>>> 生成对比分析...\n');

    comparison = compareResults(resultsOld, resultsNew, mapDataOld);

    % 生成对比图
    try
        plotCompareCoverage(comparison, cfg);
        plotCompareMetricBars(comparison, cfg);
        plotCompareTrails(mapDataOld, resultsOld, resultsNew, cfg);
    catch ME
        fprintf('  绘图时出现警告: %s\n', ME.message);
    end

    % 打印对比摘要
    printCompareSummary(comparison);

    % 保存对比结果
    save(fullfile(cfg.outputDir, 'comparison_results.mat'), ...
        'comparison', 'resultsOld', 'resultsNew', 'cfg');

    fprintf('\n对比分析完成。结果已保存至 %s\n', cfg.outputDir);
end
