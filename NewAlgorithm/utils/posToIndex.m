function [row, col] = posToIndex(pos, params)
    row = floor(pos(2) / params.dx) + 1;
    col = floor(pos(1) / params.dx) + 1;
    row = min(max(row, 1), params.N);
    col = min(max(col, 1), params.N);
end
