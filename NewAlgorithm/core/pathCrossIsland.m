function tf = pathCrossIsland(pos0, pos1, islandMask, params)
    segLen = norm(pos1 - pos0);
    nSample = max(2, ceil(segLen / (params.dx / 2)) + 1);
    tf = false;
    for kk = 1:nSample
        a = (kk - 1) / (nSample - 1);
        p = pos0 + a * (pos1 - pos0);
        row = min(max(floor(p(2) / params.dx) + 1, 1), params.N);
        col = min(max(floor(p(1) / params.dx) + 1, 1), params.N);
        if islandMask(row, col)
            tf = true;
            return;
        end
    end
end
