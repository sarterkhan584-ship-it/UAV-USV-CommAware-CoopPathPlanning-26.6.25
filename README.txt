UAV-USV 跨域协同覆盖搜索 — 通信感知最大熵算法对比仿真
============================================================================

项目：UAV-USV 跨域协同覆盖搜索算法对比
      —— 传统拓扑引导 vs 最大熵 vs 通信增强最大熵 (CARS)

作者：NWPU
日期：2025年6月

============================================================================
1. 项目概述
============================================================================

本项目针对无人机（UAV）与无人艇（USV）跨域协同覆盖搜索问题，设计和对比了
三种递进式算法：

  传统算法 (OldAlgorithm)：    基于拓扑引导的贪心搜索 —— 基线方法
  最大熵算法 (MaxEntropyOnly)： 仅保留最大熵场驱动的搜索 —— 暴露通信退化问题
  CARS改进算法 (Improved)：    通信自适应最大熵搜索 —— 同时提升覆盖与通信

此外，还保留了原"最大熵-信息素联合算法"(NewAlgorithm)作为完整参考。

递进叙事：
  传统算法提供基线性能；
  最大熵算法通过熵驱动探索显著提升覆盖率，但由于UAV过度分散，通信质量退化；
  CARS改进算法通过通信自适应权重调制（relay/spread权重依eta_B平滑调整）
  和USV偏重中继优化，在保持覆盖优势的同时大幅提升通信质量，
  证明"增强通信优化→提升覆盖搜索能力"的因果链。

============================================================================
2. 快速开始
============================================================================

  >> main_compare_three_algorithms    % 一键运行三算法对比

单独运行：
  >> addpath(genpath('OldAlgorithm'));        runOldAlgorithm();
  >> addpath(genpath('MaxEntropyOnly'));      runMaxEntropyAlgorithm();
  >> addpath(genpath('NewAlgorithm'));        runNewAlgorithm();
  >> addpath(genpath('ImprovedAlgorithm'));   runImprovedAlgorithm();

要求：MATLAB R2020a 或更高版本。

============================================================================
3. 最终对比结果
============================================================================

三算法在相同场景下运行600步（6000秒），结果如下：

  | 指标                    | 传统算法   | 最大熵算法 | CARS改进算法 |
  |------------------------|-----------|-----------|------------|
  | 最终覆盖率              | 87.20%    | 91.08%    | 91.72%     |
  | 海洋覆盖率              | 85.49%    | 90.81%    | 92.17%     |
  | 岛屿覆盖率              | 89.78%    | 91.49%    | 91.03%     |
  | eta_B (基本服务率)      | 0.7396    | 0.5988    | 0.8392     |
  | eta_L (LoS服务率)       | 0.7396    | 0.5988    | 0.8392     |
  | 平均连接UAV数           | 2.96      | 2.40      | 3.36       |
  | lambda2_B (代数连通度)  | 0.0000    | 0.0000    | 0.5858     |
  | 最大连续断连(步)        | 109       | 121       | 54         |
  | 平均SINR (dB)           | 29.72     | 24.84     | 20.19      |
  | 重复搜索率              | 73.64%    | 73.98%    | 73.41%     |

关键结论：
  - 最大熵 vs 传统：覆盖率 +3.88pp，但 eta_B -14.1%（通信退化）
  - CARS vs 传统：  覆盖率 +4.52pp，eta_B +10.0%（覆盖+通信双提升）[目标达成]

============================================================================
4. 目录结构
============================================================================

UAV-USV-CrossDomain-Cooperative-Search-master/
  OldAlgorithm/                 传统算法（拓扑引导贪心搜索）
    runOldAlgorithm.m             入口
    comm/                        通信模型（SINR物理层 + LoS/NLoS + 代数连通度）
    core/                        核心决策（selectBestAction + evaluateCandidate）
    init/                        初始化（地图、平台、状态、参数）
    utils/                       工具函数
    viz/                         可视化（含 PNG+FIG 双格式输出）
    results_old/                 输出结果

  MaxEntropyOnly/               最大熵算法（仅熵场驱动，无信息素/前沿）
    runMaxEntropyAlgorithm.m      入口
    comm/core/init/utils/viz/    同上结构
    results_maxentropy/          输出结果

  NewAlgorithm/                 最大熵-信息素联合算法（完整参考）
    runNewAlgorithm.m             入口
    comm/core/init/utils/viz/    同上结构

  ImprovedAlgorithm/            CARS通信增强最大熵算法（最终方案）
    runImprovedAlgorithm.m        入口
    comm/core/init/utils/viz/    同上结构
    results_improved/            输出结果

  Compare/                      对比基础设施
    CompareViz/                  三算法对比可视化和报告
      compareThreeResults.m        对比结构体构建
      plotThreeCoverage.m          覆盖率曲线对比
      plotThreeMetricBars.m        通信指标柱状图
      plotThreeCommDashboard.m     通信仪表板
      plotThreeCommCurves.m        通信时间序列
      printThreeCompareSummary.m   汇总报告
    CompareResults/              对比输出（PNG+FIG+MAT+TXT）

  main_compare_three_algorithms.m  三算法对比入口

============================================================================
5. 算法详细说明
============================================================================

5.1 传统算法 (OldAlgorithm)
  - 枚举7个候选航向，贪心最大化加权评分函数
  - 评分项：覆盖增益 - 重复惩罚 + 中继得分 + 分散得分 + 平滑得分
  - 通信权重固定，不随连通状态变化
  - 岛屿优先阶段：早期优先安排UAV覆盖岛屿区域

5.2 最大熵算法 (MaxEntropyOnly)
  - 在传统算法基础上引入熵场：entropyMap，h = h * exp(-alpha) 指数衰减
  - 动态覆盖/熵权重：覆盖率低时重覆盖(lambdaC大)，覆盖率高时重熵(lambdaH大)
  - 无信息素/前沿机制 —— 纯粹最大熵驱动
  - 通信权重仍然固定 → 这是导致通信退化的关键缺陷

5.3 最大熵-信息素联合算法 (NewAlgorithm)
  - 完整保留吸引信息素、排斥信息素、前沿检测等机制
  - 通信建模与其余算法完全一致（SINR物理层 + 地形感知LoS判定）

5.4 CARS通信增强算法 (ImprovedAlgorithm)
  - 核心创新：relay/spread权重随eta_B平滑自适应调制
    relayFactor = 1 + relaySensitivity * max(0, target - eta) / target
    spreadFactor = 1 - spreadSensitivity * max(0, target - eta) / target
  - USV偏重中继优化（覆盖权重0.3，中继权重60）
  - 通信范围5.0km（扩展），每步融合（commUpdateEvery=1）
  - 效果：当eta_B下降时自动增强中继驱动力、削弱分散力，维持集群连通

============================================================================
6. 通信模型
============================================================================

所有算法共享相同的通信物理层模型（buildUAVRelayGraph.m）：
  - 载波频率：2.4 GHz，带宽：1 MHz
  - 发射功率：500 mW，噪声系数：10 dB
  - 路径损耗：LoS指数2.0，NLoS指数3.5 + 额外15dB穿透损耗
  - SINR阈值：10 dB，最小数据率：100 kbps
  - 地形感知LoS判定（沿链路DEM采样 + Fresnel余量30m）
  - 双层通信图：G^B（基本）和 G^L（LoS优质）
  - 代数连通度（Fiedler特征值）评估网络鲁棒性

============================================================================
7. 仿真场景
============================================================================

  - 地图尺寸：10 km × 10 km（200 × 200网格，分辨率50 m）
  - 岛屿：1个大岛 + 18个小岛，约占40%面积
  - 地形：3D DEM，最大高程420 m
  - UAV：4架，速度20 m/s，条带宽度300 m
  - USV：3艘，速度10 m/s，条带宽度150 m
  - 步长：10秒，最大600步（6000秒）
  - 目标覆盖率：90%

============================================================================
8. 输出结果说明
============================================================================

单独运行每个算法时，输出到各自 results_*/ 子目录：
  figure_01 ~ figure_11  PNG图表（各算法独立展示）
  对应的 .fig 文件（Matlab可编辑矢量图）
  算法结果 .mat 文件

三算法对比运行时，输出到 Compare/CompareResults/：
  three_compare_coverage.png       覆盖率对比曲线
  three_compare_metrics.png        通信指标柱状图
  three_compare_dashboard.png      通信仪表板（6面板）
  three_compare_comm_curves.png    通信时间序列曲线
  three_compare_report.txt         对比报告文本
  three_compare_results.mat        完整对比数据
  各对应 .fig 文件（可编辑矢量图）

============================================================================
9. 参数配置
============================================================================

对比配置修改：
  >> edit main_compare_three_algorithms.m   % 在 getCompareConfig() 内

关键可调参数：
  - maxSteps (默认600)       最大仿真步数
  - targetCoverage (默认0.90) 目标覆盖率
  - enableAnimation (默认true) 是否输出动画

各算法参数修改：
  传统算法：    OldAlgorithm/init/getDefaultParams.m
  最大熵算法：  MaxEntropyOnly/init/getMaxEntropyParams.m
  新算法：      NewAlgorithm/init/getDefaultParams.m
  改进算法：    ImprovedAlgorithm/init/getImprovedParams.m

============================================================================
10. 引用信息
============================================================================

理论基础参考文献：
  [1] Zavlanos & Pappas (2007), IEEE TRO — 代数连通度梯度
  [2] Ames et al. (2019), ECC — 控制障碍函数(CBF)安全性
  [3] Marden, Arslan & Shamma (2009), IEEE TSMC-B — 势博弈协调
  [4] Cui et al. (2025), MDPI Drones 9(8):592 — 最大熵DMPC-OODA优化
  [5] Julian et al. (2014), IEEE TRO — 信息论路径规划
  [6] Choi et al. (2009) — CBBA拍卖任务分配
  [7] MDPI Drones 9(11):794 (2025) — 拍卖-信息素混合搜索
