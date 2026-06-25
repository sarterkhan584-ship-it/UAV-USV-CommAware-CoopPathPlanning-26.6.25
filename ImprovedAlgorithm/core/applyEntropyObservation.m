function [state, localMap, stat, observedMaskGlobal] = applyEntropyObservation(pos0, pos1, state, localMap, islandMask, params, platformType)
% applyEntropyObservation  执行条带探测，更新覆盖、访问计数与熵场（仅最大熵，无信息素）。

    if strcmpi(platformType, 'uav')
        widthKm = params.sensorStripWidthUAVKm;
    else
        widthKm = params.sensorStripWidthUSVKm;
    end

    [r1, r2, c1, c2, stripMask] = getStripMask(pos0, pos1, widthKm, params);

    gLocal = state.coveredGlobal(r1:r2, c1:c2);
    lLocal = localMap(r1:r2, c1:c2);
    islandLocal = islandMask(r1:r2, c1:c2);
    stripMask = fitMaskSize(stripMask, size(gLocal));

    if strcmpi(platformType, 'uav')
        validMask = stripMask;
    else
        validMask = stripMask & (~islandLocal);
    end

    newMask = validMask & ~gLocal;
    repeatMask = validMask & gLocal;

    gLocal(validMask) = true;
    lLocal(validMask) = true;

    state.coveredGlobal(r1:r2, c1:c2) = gLocal;
    localMap(r1:r2, c1:c2) = lLocal;

    observedMaskGlobal = false(params.N, params.N);
    observedMaskGlobal(r1:r2, c1:c2) = validMask;

    % 访问计数 + 熵衰减
    visitLocal = state.visitCountGlobal(r1:r2, c1:c2);
    entropyLocal = state.entropyMap(r1:r2, c1:c2);
    visitLocal(validMask) = visitLocal(validMask) + 1;
    entropyLocal(validMask) = entropyLocal(validMask) .* exp(-params.entropyAlpha);
    state.visitCountGlobal(r1:r2, c1:c2) = visitLocal;
    state.entropyMap(r1:r2, c1:c2) = entropyLocal;

    stat.newCount = nnz(newMask);
    stat.repeatCount = nnz(repeatMask);
end
