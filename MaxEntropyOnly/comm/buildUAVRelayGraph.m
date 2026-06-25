function [uavRelayConnected, connPerUSV, compID, directUAVUSV, metrics] = buildUAVRelayGraph(uavPos, usvPos, params)
% buildUAVRelayGraph  地形感知双层通信图构建（SINR物理模型 + LoS/NLoS区分）
%
%  基于SINR物理层模型评估每条链路质量，构建双层通信图：
%    G^B（基本通信图）：所有可用链路（含NLoS），保障最低连通
%    G^L（LoS优质通信图）：仅LoS链路，衡量通信品质
%
%  输入:
%    uavPos  - UAV 2D位置 (nUAV x 2, km)
%    usvPos  - USV 2D位置 (nUSV x 2, km)
%    params  - 参数结构体（含信道参数、阈值、地形数据）
%
%  输出:
%    uavRelayConnected - 1 x nUAV logical, UAV通过中继能否接入锚节点(G^B)
%    connPerUSV        - nUSV x 1, 每艘USV连接了多少UAV
%    compID            - nUAV x 1, UAV连通分量ID
%    directUAVUSV      - nUAV x nUSV logical, 直接UAV-USV链路(G^B)
%    metrics           - 结构体，含所有通信指标

    nUAV = size(uavPos, 1);
    nUSV = size(usvPos, 1);

    uavRelayConnected = false(1, nUAV);
    connPerUSV = zeros(nUSV, 1);
    compID = zeros(nUAV, 1);
    directUAVUSV = false(nUAV, nUSV);

    % --- 初始化metrics ---
    metrics.losRatio = 0;
    metrics.blockedRatio = 0;
    metrics.connectedCount = 0;
    metrics.connectedRatio = 0;
    metrics.meanLinkQuality = 0;
    metrics.meanDirectQuality = 0;
    metrics.directQuality = zeros(nUAV, nUSV);
    metrics.uavQuality = zeros(nUAV, nUAV);
    % 新增指标
    metrics.meanSINR_dB = 0;
    metrics.meanDataRate_kbps = 0;
    metrics.lambda2_B = 0;         % G^B代数连通度
    metrics.lambda2_L = 0;         % G^L代数连通度
    metrics.uavServiceB = false(1, nUAV);  % a_i^B
    metrics.uavServiceL = false(1, nUAV);  % a_i^L
    metrics.directUAVUSV_L = false(nUAV, nUSV);  % G^L直接链路

    if nUAV == 0 || nUSV == 0
        return;
    end

    % ---- 通信模型常量（从params提取） ----
    P_t_W = params.P_t_mW / 1000;
    B_Hz = params.B_MHz * 1e6;
    % 有效噪声功率: N0_eff = k*T*B*F (热噪声 * 噪声系数)
    k_B = params.k_B;
    T0 = params.T0_K;
    NF_lin = 10^(params.NF_dB / 10);
    N0_eff = k_B * T0 * NF_lin;  % effective noise PSD (W/Hz)
    N_total = N0_eff * B_Hz;     % total noise power (W)
    P_rx_noise = N_total;
    lambda = params.lambda_m;
    d0 = params.d0_m;
    gamma_th_lin = 10^(params.gamma_th_dB / 10);
    R_min_bps = params.R_min_kbps * 1000;
    D_max = params.D_max_km;
    G_t_lin = 10^(params.G_t_dBi / 10);
    G_r_lin = 10^(params.G_r_dBi / 10);
    alpha_L = params.alpha_L;
    alpha_N = params.alpha_N;
    L_NLoS_dB = params.L_NLoS_extra_dB;
    h_margin = params.commTerrainClearanceKm;
    kappa = params.kappa_terrain_dB_per_m;

    % ---- 链路评估 ----
    % UAV-USV links
    uavusv_B = false(nUAV, nUSV);    % G^B adjacency
    uavusv_L = false(nUAV, nUSV);    % G^L adjacency
    uavusv_SINR = zeros(nUAV, nUSV); % SINR linear
    uavusv_Rate = zeros(nUAV, nUSV); % Data rate in bps
    uavusv_LoS = false(nUAV, nUSV);  % LoS flag

    for i = 1:nUAV
        for j = 1:nUSV
            [linked_B, linked_L, sinr_lin, rate_bps, isLos, ~] = ...
                evaluateLink(uavPos(i,:), usvPos(j,:), params, P_t_W, B_Hz, P_rx_noise, ...
                    lambda, d0, G_t_lin, G_r_lin, alpha_L, alpha_N, L_NLoS_dB, ...
                    gamma_th_lin, R_min_bps, D_max, h_margin, kappa);
            uavusv_B(i,j) = linked_B;
            uavusv_L(i,j) = linked_L;
            uavusv_SINR(i,j) = sinr_lin;
            uavusv_Rate(i,j) = rate_bps;
            uavusv_LoS(i,j) = isLos;
            if linked_B || linked_L
                metrics.directQuality(i,j) = max(0, min(1, sinr_lin / (10 * gamma_th_lin)));
            end
        end
    end
    directUAVUSV = uavusv_B;
    metrics.directUAVUSV_L = uavusv_L;

    % UAV-UAV links
    uav_B = false(nUAV, nUAV);       % G^B adjacency
    uav_L = false(nUAV, nUAV);       % G^L adjacency
    uav_SINR = zeros(nUAV, nUAV);
    uav_Rate = zeros(nUAV, nUAV);
    uav_LoS = false(nUAV, nUAV);

    for i = 1:nUAV
        for q = i+1:nUAV
            [linked_B, linked_L, sinr_lin, rate_bps, isLos, ~] = ...
                evaluateLink(uavPos(i,:), uavPos(q,:), params, P_t_W, B_Hz, P_rx_noise, ...
                    lambda, d0, G_t_lin, G_r_lin, alpha_L, alpha_N, L_NLoS_dB, ...
                    gamma_th_lin, R_min_bps, D_max, h_margin, kappa);
            uav_B(i,q) = linked_B; uav_B(q,i) = linked_B;
            uav_L(i,q) = linked_L; uav_L(q,i) = linked_L;
            uav_SINR(i,q) = sinr_lin; uav_SINR(q,i) = sinr_lin;
            uav_Rate(i,q) = rate_bps; uav_Rate(q,i) = rate_bps;
            uav_LoS(i,q) = isLos; uav_LoS(q,i) = isLos;
            if linked_B || linked_L
                metrics.uavQuality(i,q) = max(0, min(1, sinr_lin / (10 * gamma_th_lin)));
                metrics.uavQuality(q,i) = metrics.uavQuality(i,q);
            end
        end
    end

    % ---- LoS & Blocked Ratio ----
    allLoS = [uavusv_LoS(:); uav_LoS(triu(true(nUAV),1))];
    allPossible = (nUAV*nUSV + nUAV*(nUAV-1)/2);
    if allPossible > 0 && ~isempty(allLoS)
        metrics.losRatio = sum(allLoS) / allPossible;
    else
        metrics.losRatio = 0;
    end
    % NLoS但链路仍可能通过G^B：所有活跃G^B中不是LoS的
    allB = [uavusv_B(:); uav_B(triu(true(nUAV),1))];
    allL = [uavusv_L(:); uav_L(triu(true(nUAV),1))];
    totalBLinks = sum(allB);
    if totalBLinks > 0
        metrics.blockedRatio = 1 - sum(allL) / totalBLinks;
    else
        metrics.blockedRatio = 0;
    end

    % ---- SINR & DataRate ----
    allSINR = [uavusv_SINR(uavusv_B); uav_SINR(uav_B & triu(true(nUAV),1))];
    allRate = [uavusv_Rate(uavusv_B); uav_Rate(uav_B & triu(true(nUAV),1))];
    if ~isempty(allSINR)
        metrics.meanSINR_dB = 10 * log10(mean(allSINR));
        metrics.meanDataRate_kbps = mean(allRate) / 1000;
    end
    allQ = [metrics.directQuality(uavusv_B); metrics.uavQuality(uav_B & triu(true(nUAV),1))];
    if ~isempty(allQ)
        metrics.meanLinkQuality = mean(allQ);
    end
    metrics.meanDirectQuality = mean(metrics.directQuality(:));

    % ---- G^B 连通分量分析 ----
    compCount = 0;
    for i = 1:nUAV
        if compID(i) ~= 0, continue; end
        compCount = compCount + 1;
        queue = i;
        compID(i) = compCount;
        head = 1;
        while head <= numel(queue)
            curr = queue(head);
            head = head + 1;
            neigh = find(uav_B(curr, :));
            for t = 1:numel(neigh)
                nb = neigh(t);
                if compID(nb) == 0
                    compID(nb) = compCount;
                    queue(end + 1) = nb;
                end
            end
        end
    end

    % ---- 服务接入判定 ----
    uavServiceB = false(1, nUAV);
    uavServiceL = false(1, nUAV);
    for c = 1:compCount
        members = find(compID == c);
        linkedUSV_B = any(uavusv_B(members, :), 1);
        linkedUSV_L = any(uavusv_L(members, :), 1);
        if any(linkedUSV_B)
            uavRelayConnected(members) = true;
            uavServiceB(members) = true;
            for j = find(linkedUSV_B)
                connPerUSV(j) = connPerUSV(j) + numel(members);
            end
        end
        if any(linkedUSV_L)
            uavServiceL(members) = true;
        end
    end
    metrics.uavServiceB = uavServiceB;
    metrics.uavServiceL = uavServiceL;

    metrics.connectedCount = sum(uavRelayConnected);
    metrics.connectedRatio = metrics.connectedCount / max(nUAV, 1);

    % ---- 代数连通度 (Fiedler eigenvalue) ----
    metrics.lambda2_B = computeAlgebraicConnectivity(uav_B);
    metrics.lambda2_L = computeAlgebraicConnectivity(uav_L);
end

% ==================================================================
function [linked_B, linked_L, sinr_lin, rate_bps, isLos, clearance] = ...
    evaluateLink(p1, p2, params, P_t_W, B_Hz, P_rx_noise, lambda, d0, G_t_lin, G_r_lin, ...
        alpha_L, alpha_N, L_NLoS_dB, gamma_th_lin, R_min_bps, D_max, h_margin, kappa)
% evaluateLink  评估两点间链路质量（SINR + LoS/NLoS + 数据率）
%  使用热噪声物理模型: k_B * T0 * B * NF
%  3.5km @ 2.4GHz, LoS → SINR ≈ 20dB ✅
%  返回:
%    linked_B  - G^B链路存在标志
%    linked_L  - G^L链路存在标志
%    sinr_lin  - 线性SINR
%    rate_bps  - Shannon容量 (bps)
%    isLos     - 视距标志
%    clearance - 地形净空

    d_km = norm(p1 - p2);  % 2D distance in km (approximates 3D for LoS check)
    d_m = d_km * 1000;

    % 获取高度用于LoS判定
    if isfield(params, 'terrainHeightMap') && ~isempty(params.terrainHeightMap)
        z1 = getNodeZ(p1, params);
        z2 = getNodeZ(p2, params);
    else
        z1 = params.uavCruiseAltitudeKm;
        z2 = params.uavCruiseAltitudeKm;
    end

    % --- LoS判定（含Fresnel余量） ---
    if isfield(params, 'terrainHeightMap') && ~isempty(params.terrainHeightMap)
        [isLos, clearance] = hasTerrainLoS2D(p1, p2, z1, z2, params, h_margin);
    else
        isLos = true;
        clearance = inf;
    end

    % --- 路径损耗计算（dB）---
    % Free-space path loss: PL(d) = PL(d0) + 10*alpha*log10(d/d0)
    % with PL(d0) = 20*log10(4*pi*d0/lambda)  (free-space reference)
    alpha = iif(isLos, alpha_L, alpha_N);
    PL0_dB = 20 * log10(4 * pi * d0 / lambda);
    PL_dB = PL0_dB + 10 * alpha * log10(max(d_m, d0) / d0);

    % NLoS额外穿透损耗
    if ~isLos
        PL_dB = PL_dB + L_NLoS_dB;
    end

    % 地形附加损耗
    if ~isLos && clearance < 0
        L_terrain_dB = kappa * abs(clearance) * 1000;
        PL_dB = PL_dB + L_terrain_dB;
    end

    % --- SINR ---
    PL_lin = 10^(PL_dB / 10);
    h_ij = G_t_lin * G_r_lin / PL_lin;
    P_rx = P_t_W * h_ij;
    sinr_lin = P_rx / P_rx_noise;

    % --- Data rate ---
    if sinr_lin > 0
        rate_bps = B_Hz * log2(1 + sinr_lin);
    else
        rate_bps = 0;
    end

    % --- Link eligibility ---
    linked_B = (sinr_lin >= gamma_th_lin) && (rate_bps >= R_min_bps) && (d_km <= D_max);
    linked_L = linked_B && isLos;
end

% ==================================================================
function [isLos, clearance] = hasTerrainLoS2D(p1, p2, z1, z2, params, h_margin)
% hasTerrainLoS2D  2D位置上的地形LoS判定（UAV高度自适应地形）
%  在两点间采样，检查DEM高程是否侵入信号路径（含Fresnel余量）

    isLos = true;
    clearance = inf;

    if ~isfield(params, 'terrainHeightMap') || isempty(params.terrainHeightMap)
        return;
    end

    xyLen = norm(p2 - p1);
    nSample = max(3, ceil(xyLen / (params.dx / 2)) + 1);

    for k = 1:nSample
        a = (k - 1) / max(nSample - 1, 1);
        p = p1 + a * (p2 - p1);
        z_line = z1 + a * (z2 - z1);

        terrainZ = getTerrainHeightAtPos(p, params);
        if terrainZ > 0  % only check where terrain exists
            chi = z_line - terrainZ - h_margin;
            clearance = min(clearance, chi);
            if chi < 0
                isLos = false;
                % continue checking to find worst clearance
            end
        end
    end
end

% ==================================================================
function z = getNodeZ(pos2D, params)
% getNodeZ 根据2D位置获取节点高度（UAV自适应，USV=0.015km）
% 简化：假定调用方知道平台类型；这里取巡航高度作为默认
    if isfield(params, 'uavCruiseAltitudeKm')
        terrainZ = getTerrainHeightAtPos(pos2D, params);
        z = max(params.uavCruiseAltitudeKm, terrainZ + params.uavTerrainClearanceKm);
    else
        z = 0;
    end
end

% ==================================================================
function val = iif(condition, trueVal, falseVal)
    if condition
        val = trueVal;
    else
        val = falseVal;
    end
end

% ==================================================================
function lambda2 = computeAlgebraicConnectivity(adj)
% computeAlgebraicConnectivity 计算图的代数连通度（Laplacian第二小特征值）
    n = size(adj, 1);
    if n == 0 || all(adj(:) == 0)
        lambda2 = 0;
        return;
    end
    deg = sum(adj, 2);
    L = diag(deg) - adj;
    if n <= 3
        eigVals = sort(eig(L));
        lambda2 = eigVals(2);
    else
        try
            eigVals = eigs(L, 3, 'smallestreal');
            eigVals = sort(real(eigVals));
            lambda2 = eigVals(2);
        catch
            lambda2 = 0;
        end
    end
end
