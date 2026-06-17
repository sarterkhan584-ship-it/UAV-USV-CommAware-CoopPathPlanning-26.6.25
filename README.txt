UAV—USV跨域协同搜索算法仿真

运行入口：
    main_compare_entropy_pheromone

目录结构：
    OldAlgorithm/      原算法，按 comm/core/init/utils/viz 分包保留。
    NewAlgorithm/      最大熵-信息素联合覆盖搜索算法，按同样分包组织。
    CompareViz/        统一对比可视化函数。
    CompareResults/    运行后自动生成，保存对比图和 .mat 结果。

新算法主要新增内容：
    1) entropyMap：信息熵场，按 h = h * exp(-alpha) 随探测次数衰减；
    2) attractionPheromone：吸引信息素，未覆盖区域持续沉积；
    3) repulsionPheromone：排斥信息素，已探测区域沉积以抑制重复覆盖；
    4) visitCountGlobal：全局探测次数矩阵，用于重复探测惩罚和统计；
    5) frontierMap：覆盖前沿牵引，帮助后期寻找零散未覆盖空洞；
    6) 动态权重：覆盖率升高后自动提高熵增益、排斥惩罚和前沿牵引权重。

对比可视化输出：
    figure_00_dynamic_tracks_comparison_final.png       两种算法动态航迹最终帧
    figure_00_dynamic_coverage_curve_final.png          两种算法覆盖率动态曲线最终帧
    figure_01_entropy_convergence.png                   熵收敛图
    figure_02_coverage_rate_change.png                  覆盖率变化图
    figure_03_0400_old_environment_coverage.png         原算法 K=400 覆盖图
    figure_03_0400_entropy_pheromone_environment_coverage.png  新算法 K=400 覆盖图
    figure_03_0800_old_environment_coverage.png         原算法 K=800 覆盖图
    figure_03_0800_entropy_pheromone_environment_coverage.png  新算法 K=800 覆盖图
    figure_03_1200_old_environment_coverage.png         原算法 K=1200 覆盖图
    figure_03_1200_entropy_pheromone_environment_coverage.png  新算法 K=1200 覆盖图
    figure_04_threshold_duration.png                    达到覆盖阈值时间对比图
    figure_05_repetitive_detection_rate.png             重复覆盖率对比曲线
    figure_06_repeated_grid_counts.png                  重复探测网格数量对比图

默认对比设置：
    最大步长：1200
    快照步长：400、800、1200
    覆盖阈值：90%
    对比动态回放：开启
    单算法独立动画：关闭
    动态视频保存：默认关闭，可在 CompareViz/getCompareConfig.m 中打开 saveComparisonAnimationVideo。

如需调整对比仿真步长、阈值或快照步长，请修改：
    CompareViz/getCompareConfig.m
