function [uavConnectedFlags, connPerUSV, metrics] = getUAVConnectivity(uavPos, usvPos, params)
%  二维接入状态统计，返回通信指标用于对比。
%  接口已变更：第三个参数从 commRangeKm 改为 params 结构体
    [uavConnectedFlags, connPerUSV, ~, ~, metrics] = buildUAVRelayGraph(uavPos, usvPos, params);
end