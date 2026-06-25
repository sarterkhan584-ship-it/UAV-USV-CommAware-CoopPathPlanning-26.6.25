function [localUAV, localUSV] = fuseByUSVRelay(localUAV, localUSV, uavPos, usvPos, params)
    % 通信规则：
    % 1) commRangeKm 表示 UAV 的短距离通信半径，通信圆以 UAV 为圆心；
    % 2) 若 USV 位于某架 UAV 的通信范围内，则该 UAV 可接入 USV 网络并更新本地地图；
    % 3) UAV 与 UAV 距离不超过 commRangeKm 时可临时组链。若某个 UAV 连通分量中
    %    至少一架 UAV 可接入 USV，则该分量内所有 UAV 均可通过链路接入 USV 并更新；
    % 4) 所有 USV 之间仍默认全时全联通，用于汇聚各 USV 与接入 UAV 的信息。

    nUSV = size(usvPos, 1);
    nUAV = size(uavPos, 1);

    if nUSV == 0 || nUAV == 0
        return;
    end

    [uavConnected, ~, compID] = buildUAVRelayGraph(uavPos, usvPos, params);

    % ---------- 第 1 步：所有 USV 先做无距离限制的全局融合 ----------
    globalUSVMap = localUSV{1};
    for j = 2:nUSV
        globalUSVMap = globalUSVMap | localUSV{j};
    end
    for j = 1:nUSV
        localUSV{j} = globalUSVMap;
    end

    % ---------- 第 2 步：接入 USV 的 UAV 连通分量与 USV 网络交换 ----------
    compList = unique(compID(uavConnected(:)));
    for cIdx = 1:numel(compList)
        members = find(compID == compList(cIdx));
        fusedMap = globalUSVMap;
        for q = 1:numel(members)
            fusedMap = fusedMap | localUAV{members(q)};
        end

        % 分量内 UAV 均获得该分量与 USV 网络的融合图。
        for q = 1:numel(members)
            localUAV{members(q)} = fusedMap;
        end

        % 接入 UAV 的新信息写入 USV 网络。
        for j = 1:nUSV
            localUSV{j} = localUSV{j} | fusedMap;
        end
    end

    % ---------- 第 3 步：将任一 USV 从 UAV 链路获得的新信息同步给全体 USV ----------
    globalUSVMap = localUSV{1};
    for j = 2:nUSV
        globalUSVMap = globalUSVMap | localUSV{j};
    end
    for j = 1:nUSV
        localUSV{j} = globalUSVMap;
    end

    % ---------- 第 4 步：把 USV 网络共享图回写给当前可接入 USV 的 UAV ----------
    for i = 1:nUAV
        if uavConnected(i)
            localUAV{i} = localUAV{i} | globalUSVMap;
        end
    end
end
