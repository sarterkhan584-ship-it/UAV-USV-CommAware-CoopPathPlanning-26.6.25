function saveFigureCompat(figHandle, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(figHandle, fileName, 'Resolution', 300);
    else
        saveas(figHandle, fileName);
    end
    [p, n, ~] = fileparts(fileName);
    figName = fullfile(p, [n '.fig']);
    savefig(figHandle, figName);
end
