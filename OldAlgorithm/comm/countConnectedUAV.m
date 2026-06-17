function conn = countConnectedUAV(uavPos, usvPos, params)
% countConnectedUAV 返回各 USV 可通过 UAV 短距通信链覆盖到的 UAV 数量。
    [~, conn] = buildUAVRelayGraph(uavPos, usvPos, params);
end