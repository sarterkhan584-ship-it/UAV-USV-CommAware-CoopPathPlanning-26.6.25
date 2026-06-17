function [covAll, covSea, covIsland] = getCoverageStats(coveredGlobal, seaMask, islandMask)
    covAll = nnz(coveredGlobal) / numel(coveredGlobal);
    covSea = nnz(coveredGlobal & seaMask) / nnz(seaMask);
    covIsland = nnz(coveredGlobal & islandMask) / nnz(islandMask);
end
