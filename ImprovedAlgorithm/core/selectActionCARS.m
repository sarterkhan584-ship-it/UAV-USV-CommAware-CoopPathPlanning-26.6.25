function [nextPos, nextPsi] = selectActionCARS(pos, psi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage)
% selectActionCARS  通信自适应动作选择
%  统一评测所有7个候选航向，使用通信自适应权重调制（无角色切换）。

    if strcmpi(platformType, 'uav')
        cand = params.turnCandidatesUAV;
        speed = params.vUAV;
    else
        cand = params.turnCandidatesUSV;
        speed = params.vUSV;
    end

    bestScore = -inf;
    nextPos = pos;
    nextPsi = psi;

    for ii = 1:numel(cand)
        dpsi = cand(ii);
        psiTry = wrapTo2PiLocal(psi + dpsi);
        posTry = pos + speed * params.dt * [cos(psiTry), sin(psiTry)];

        score = evaluateCommAdaptive(pos, posTry, dpsi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage);
        if score > bestScore
            bestScore = score;
            nextPos = posTry;
            nextPsi = psiTry;
        end
    end
end
