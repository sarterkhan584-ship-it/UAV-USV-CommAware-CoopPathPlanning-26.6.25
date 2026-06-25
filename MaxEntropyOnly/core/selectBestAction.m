function [nextPos, nextPsi] = selectBestAction(pos, psi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage)
% selectBestAction  最大熵算法动作选择（枚举7个候选航向，选最高分）。

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
