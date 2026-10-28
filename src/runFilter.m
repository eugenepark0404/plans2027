function run = runFilter(traj, wSpec, map, radioMap, cfg)
%RUNFILTER 경로 하나에 대해 필터를 처음부터 끝까지 돌린다.
%   wSpec : 스칼라(고정 w) 또는 함수 핸들 w = wSpec(logPrior, logLik, t)
%   첫 에포크: 신호 기반 분포를 초기 분포로 쓴다(시작 위치를 미리 알려 주지 않음, 6.1).
%   이후 에포크: prior = propagate(이전 사후, PDR 변위), 사후 = fuseLog(prior, 우도, w).
%   traj.pdr(t,:)는 에포크 t-1 -> t 의 변위 추정이며 traj.pdr(1,:)은 쓰지 않는다.
T = size(traj.rss, 1);  N = map.N;
logPost = zeros(N, T);  logPriorAll = zeros(N, T);  logLikAll = zeros(N, T);
w = nan(T, 1);
for t = 1:T
    logLik = signalLogLik(traj.rss(t, :), radioMap, cfg);
    logLikAll(:, t) = logLik;
    if t == 1
        logPriorAll(:, t) = -log(N);                    % 균등(기록용)
        logPost(:, t) = floorLog(logLik, cfg);
        w(t) = 1;
    else
        lpri = propagate(logPost(:, t-1), traj.pdr(t, :), map, cfg);
        logPriorAll(:, t) = lpri;
        if isa(wSpec, 'function_handle')
            w(t) = wSpec(lpri, logLik, t);
        else
            w(t) = wSpec;
        end
        logPost(:, t) = fuseLog(lpri, logLik, w(t), cfg);
    end
end
run = struct('logPost', logPost, 'logPrior', logPriorAll, 'logLik', logLikAll, 'w', w);
end
