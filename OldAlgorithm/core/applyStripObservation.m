function [coveredGlobal, localMap, stat] = applyStripObservation(pos0, pos1, coveredGlobal, localMap, islandMask, params, platformType)
    if strcmpi(platformType, 'uav')
        widthKm = params.sensorStripWidthUAVKm;
    else
        widthKm = params.sensorStripWidthUSVKm;
    end

    [r1, r2, c1, c2, stripMask] = getStripMask(pos0, pos1, widthKm, params);

    gLocal = coveredGlobal(r1:r2, c1:c2);
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

    coveredGlobal(r1:r2, c1:c2) = gLocal;
    localMap(r1:r2, c1:c2) = lLocal;

    stat.newCount = nnz(newMask);
    stat.repeatCount = nnz(repeatMask);
end
