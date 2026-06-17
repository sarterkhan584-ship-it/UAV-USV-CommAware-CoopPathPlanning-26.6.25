function rgb = buildCoverageRGB(islandMask, coveredGlobal)
    seaCovered = coveredGlobal & ~islandMask;
    islandCovered = coveredGlobal & islandMask;
    rgb = zeros([size(islandMask), 3]);
    rgb(:, :, 1) = 0.78 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
    rgb(:, :, 2) = 0.90 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
    rgb(:, :, 3) = 1.00 * (~islandMask & ~seaCovered) + 1.00 * seaCovered + 0.00 * (~coveredGlobal & islandMask) + 0.55 * islandCovered;
end
