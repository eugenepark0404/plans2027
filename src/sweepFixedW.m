function sw = sweepFixedW(trajs, map, radioMap, cfg)
%SWEEPFIXEDW 고정 w를 cfg.wGrid(21개)로 훑는다. 고정 w마다 필터를 따로 돌린다(피드백 때문).
%   trajs: 경로 구조체의 cell 배열.  sw.hit, sw.logloss, sw.top3 : (w 개수 x 경로 수)
wGrid = cfg.wGrid(:);  nW = numel(wGrid);  nP = numel(trajs);
sw.wGrid = wGrid;
sw.hit = nan(nW, nP);  sw.logloss = nan(nW, nP);  sw.top3 = nan(nW, nP);
for iw = 1:nW
    for ip = 1:nP
        run = runFilter(trajs{ip}, wGrid(iw), map, radioMap, cfg);
        m = metricsPerPath(run, trajs{ip}, cfg);
        sw.hit(iw, ip) = m.hit;  sw.logloss(iw, ip) = m.logloss;  sw.top3(iw, ip) = m.top3;
    end
end
end
