function saveFigureCompat(figHandle, fileName)
    if exist('exportgraphics', 'file') == 2
        exportgraphics(figHandle, fileName, 'Resolution', 300);
    else
        saveas(figHandle, fileName);
    end
end
