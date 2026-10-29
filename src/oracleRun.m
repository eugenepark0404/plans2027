function run = oracleRun(traj, kind, map, radioMap, cfg)
%ORACLERUN 정답 칸을 알고 매 시점 w를 고르는 "반칙 선수"(6.2). 분석용 기준이며 학습에 쓰지 않는다.
%   kind: 'logloss' 또는 'hit'. 각 oracle은 독립된 필터 한 번이다.
%   매 에포크 t(>=2)마다:
%     1) 이전 사후분포를 전파해 prior를 만들고 신호 우도를 계산한다.
%     2) cfg.wGrid의 w 각각에 대해 융합 분포를 만든다 (고정 w 필터와 같은 fuseLog).
%     3) logloss: 정답 칸의 확률이 가장 큰 w.
%     4) hit: 1위 칸이 정답인 w들 중 정답 확률이 가장 큰 w. 하나도 없으면
%        정답 확률이 가장 큰 w를 고르되 그 시점은 실패(지표에서 자동으로 오답)다.
%     5) 고른 w의 융합 분포가 다음 에포크의 사후분포로 이어진다.
%   동점이면 w가 0.5에 더 가까운 쪽을 택한다. 시점별 선택이므로 경로 전체 최적은 아니다.
%   첫 에포크는 모든 전략과 같다(신호 기반 분포).
T = size(traj.rss, 1);  N = map.N;
wGrid = cfg.wGrid(:);   nW = numel(wGrid);
logPost = zeros(N, T);  logPriorAll = zeros(N, T);  logLikAll = zeros(N, T);
w = nan(T, 1);  hitPossible = false(T, 1);
for t = 1:T
    logLik = signalLogLik(traj.rss(t, :), radioMap, cfg);
    logLikAll(:, t) = logLik;
    if t == 1
        logPriorAll(:, t) = -log(N);
        logPost(:, t) = floorLog(logLik, cfg);
        w(t) = 1;
        continue
    end
    lpri = propagate(logPost(:, t-1), traj.pdr(t, :), map, cfg);
    logPriorAll(:, t) = lpri;
    cand = zeros(N, nW);
    for i = 1:nW
        cand(:, i) = fuseLog(lpri, logLik, wGrid(i), cfg);
    end
    c = traj.cell(t);
    lpTrue = cand(c, :);                           % 1 x nW 정답 칸의 로그 확률
    [~, top] = max(cand, [], 1);
    isHit = (top == c);
    hitPossible(t) = any(isHit);
    switch kind
        case 'logloss'
            pool = true(1, nW);
        case 'hit'
            if any(isHit), pool = isHit; else, pool = true(1, nW); end
        otherwise
            error('kind는 logloss 또는 hit');
    end
    vals = lpTrue;  vals(~pool) = -Inf;
    idx = find(vals >= max(vals) - 1e-12);
    [~, k] = min(abs(wGrid(idx) - 0.5));           % 동점이면 0.5에 가까운 w
    iBest = idx(k);
    w(t) = wGrid(iBest);
    logPost(:, t) = cand(:, iBest);
end
run = struct('logPost', logPost, 'logPrior', logPriorAll, 'logLik', logLikAll, ...
    'w', w, 'kind', kind, 'hitPossible', hitPossible);
end
