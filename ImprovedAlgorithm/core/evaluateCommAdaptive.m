function score = evaluateCommAdaptive(pos0, pos1, dpsi, knownMap, relayTargets, sameTypeOthers, islandMask, state, params, platformType, agentID, currIslandCoverage)
% evaluateCommAdaptive  通信自适应最大熵评分
%  relay/spread权重依eta_B平滑调制。USV完全中继优化。

    if pos1(1)<0||pos1(1)>=params.mapLenKm||pos1(2)<0||pos1(2)>=params.mapLenKm
        score=-1e12;return;
    end
    if strcmpi(platformType,'uav'), wKm=params.sensorStripWidthUAVKm;
    else, wKm=params.sensorStripWidthUSVKm; end

    if strcmpi(platformType,'usv')
        if pathCrossIsland(pos0,pos1,islandMask,params),score=-1e12;return;end
        [dMin,thCost,apfA]=sampleUSVThreatInfo(pos0,pos1,wKm,params);
        if dMin-wKm/2<=params.usvHardClearanceKm,score=-1e12;return;end
    else, thCost=0;apfA=0;end

    if strcmpi(platformType,'uav')&&isfield(params,'terrainThreatMap')&&~isempty(params.terrainThreatMap)
        [tCost,tAlign]=sampleUAVTerrainInfo(pos0,pos1,params);
    else, tCost=0;tAlign=0;end

    [r1,r2,c1,c2,strip]=getStripMask(pos0,pos1,wKm,params);
    localK=knownMap(r1:r2,c1:c2); localI=islandMask(r1:r2,c1:c2);
    localE=state.entropyMap(r1:r2,c1:c2); localV=state.visitCountGlobal(r1:r2,c1:c2);
    strip=fitMaskSize(strip,size(localK));

    if strcmpi(platformType,'uav'), vM=strip; else, vM=strip&~localI; end
    newSea=nnz(vM&~localK&~localI); newIsl=nnz(vM&~localK&localI);
    revisit=nnz(vM&localK);

    rho=mean(state.coveredGlobal(:));
    [lC,lH,lR]=getDynamicWeights(rho,params);
    eGain=sum(localE(vM));
    rCost=sum(localV(vM).^params.visitPenaltyPower)+revisit;

    % ==== 通信自适应 ====
    eta=state.smoothedEta; tg=params.commAdaptTarget;

    if strcmpi(platformType,'uav')
        % relayFactor: eta低时放大中继驱动力
        relayF=1+params.relaySensitivity*max(0,tg-eta)/tg;
        % spreadFactor: eta低时削弱分散力
        spreadF=1-params.spreadSensitivity*max(0,tg-eta)/tg;
        spreadF=max(0.3,spreadF);
    else
        % USV: 完全中继导向，覆盖权重极小
        relayF=1.5; spreadF=0.6;
    end

    % 中继得分
    if isempty(relayTargets), relaySc=0;
    else
        d=sqrt(sum((relayTargets-pos1).^2,2));
        if strcmpi(platformType,'uav')
            relaySc=max(0,1-min(d)/params.commRangeKm);
        else
            inR=d<=params.commRangeKm;
            if any(inR)
                relaySc=0.6*sum(inR)/size(relayTargets,1)+...
                        0.4*(1-mean(d(inR))/params.commRangeKm);
            else, relaySc=0;
            end
        end
    end

    % 分散得分
    if isempty(sameTypeOthers),spreadSc=1;
    else
        if strcmpi(platformType,'uav')
            spreadSc=min(min(sqrt(sum((sameTypeOthers-pos1).^2,2)))/params.spreadRefUAV,1);
        else
            spreadSc=min(min(sqrt(sum((sameTypeOthers-pos1).^2,2)))/params.spreadRefUSV,1);
        end
    end

    if strcmpi(platformType,'uav')
        smSc=1-abs(dpsi)/max(abs(params.turnCandidatesUAV));
    else, smSc=1-abs(dpsi)/max(abs(params.turnCandidatesUSV));
    end

    bndSc=getBoundaryScore(pos1,params);

    if strcmpi(platformType,'uav')
        isIsland=(currIslandCoverage<params.islandStageThreshold);
        if isIsland&&agentID<=2, wS=0.6;wI=2.0;
        elseif isIsland, wS=1.0;wI=1.2;
        else, wS=1.0;wI=1.0; end
        covG=wS*newSea+wI*newIsl;
        wT=params.terrainAPFWeightUAV; wTA=min(8,wT*0.5);
        score=lC*covG+lH*eGain-lR*rCost+...
              relayF*params.relayWeightUAV_base*relaySc+...
              spreadF*params.spreadWeightUAV_base*spreadSc+...
              params.smoothWeightUAV*smSc+...
              params.boundaryPotentialWeightUAV*bndSc-...
              wT*tCost+wTA*tAlign;
    else
        covG=newSea;
        score=params.usvCovWeight*covG+...
              0.5*lH*eGain-0.8*lR*rCost+...
              relayF*params.usvRelayWeight*relaySc+...
              spreadF*params.usvSpreadWeight*spreadSc+...
              params.usvSmoothWeight*smSc+...
              params.boundaryPotentialWeightUSV*bndSc-...
              120*params.usvThreatWeight*thCost+...
              20*params.usvAPFAlignWeight*apfA;
    end
end

function [lC,lH,lR]=getDynamicWeights(rho,params)
    rho=min(max(rho,0),1);p=params.dynamicWeightPower;
    lC=params.lambdaCMin+(params.lambdaCMax-params.lambdaCMin)*(1-rho)^p;
    lH=params.lambdaHMin+(params.lambdaHMax-params.lambdaHMin)*rho^p;
    lR=params.lambdaRMin+(params.lambdaRMax-params.lambdaRMin)*rho^p;
end
function s=getBoundaryScore(pos,params)
    e=params.boundaryEpsKm;x=pos(1);y=pos(2);L=params.mapLenKm;
    s=-((e/(x+e))+(e/(L-x+e))+(e/(y+e))+(e/(L-y+e)));
end
function [tc,ta]=sampleUAVTerrainInfo(pos0,pos1,params)
    seg=norm(pos1-pos0);n=max(5,ceil(seg/(params.dx/2))+1);
    tv=zeros(n,1);fv=zeros(n,2);
    for kk=1:n
        a=(kk-1)/max(n-1,1);p=pos0+a*(pos1-pos0);
        [r,c]=posToIndex(p,params);
        tv(kk)=params.terrainThreatMap(r,c);
        fv(kk,1)=params.terrainForceX(r,c);
        fv(kk,2)=params.terrainForceY(r,c);
    end
    tc=0.55*mean(tv)+0.30*max(tv);tc=min(max(tc,0),1.5);
    mv=pos1-pos0;af=mean(fv,1);
    if norm(mv)<1e-12||norm(af)<1e-12,ta=0;
    else,mh=mv/norm(mv);fh=af/norm(af);ta=max(0,dot(mh,fh));end
end
