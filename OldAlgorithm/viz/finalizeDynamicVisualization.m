function finalizeDynamicVisualization(viz)
    if ~isempty(viz) && isfield(viz, 'videoWriter') && ~isempty(viz.videoWriter)
        close(viz.videoWriter);
    end
end
