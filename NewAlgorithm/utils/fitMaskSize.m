function mask = fitMaskSize(mask, targetSize)
    nr = targetSize(1);
    nc = targetSize(2);

    if isequal(size(mask), [nr, nc])
        return;
    end

    newMask = false(nr, nc);
    rr = min(nr, size(mask, 1));
    cc = min(nc, size(mask, 2));
    if rr > 0 && cc > 0
        newMask(1:rr, 1:cc) = logical(mask(1:rr, 1:cc));
    end
    mask = newMask;
end
