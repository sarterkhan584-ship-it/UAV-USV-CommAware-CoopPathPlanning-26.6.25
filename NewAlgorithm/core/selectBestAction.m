function [nextPos, nextPsi] = selectBestAction(pos, psi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage)
% selectBestAction 采用最大熵-信息素联合评价函数筛选最优候选动作。

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

        score = evaluateCandidate(pos, posTry, dpsi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage);
        if score > bestScore
            bestScore = score;
            nextPos = posTry;
            nextPsi = psiTry;
        end
    end
end
