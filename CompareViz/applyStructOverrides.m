function params = applyStructOverrides(params, overrides)
% applyStructOverrides 将配置结构体字段覆盖到 params。

    names = fieldnames(overrides);
    for i = 1:numel(names)
        key = names{i};
        val = overrides.(key);
        if isempty(val)
            if strcmp(key, 'maxTime') && isfield(overrides, 'maxSteps')
                params.maxTime = params.dt * overrides.maxSteps;
            end
        else
            params.(key) = val;
        end
    end
    if isfield(overrides, 'maxSteps') && ~isempty(overrides.maxSteps)
        params.maxSteps = overrides.maxSteps;
        params.maxTime = params.dt * params.maxSteps;
    end
end
