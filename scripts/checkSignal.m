% T2 완료 기준: 한 칸의 RSS를 넣었을 때 그 칸 근처가 높은 점수를 받는 지도 그림
% 사용: MATLAB 현재 폴더를 이 파일이 있는 scripts 로 바꾼 뒤 checkSignal 실행
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();
rng(cfg.seed);
types = {'corridor', 'hall'};
figure('Position', [100 100 1100 450]);
for t = 1:2
    map = makeMap(types{t}, cfg);
    bc  = placeBeacons(map, cfg);
    rm  = buildRadioMap(bc, map, cfg);
    N = map.N;  B = size(bc.pos, 1);

    % (1) 한 칸(가운데쯤)의 RSS 한 번을 넣고 칸별 점수 지도 그리기
    iTrue = round(N / 2);
    rss = rm.mu(iTrue, :) + cfg.rssSigma * randn(1, B);
    rss(rss < cfg.detThr) = NaN;
    ll = signalLogLik(rss, rm, cfg);
    post = exp(ll - max(ll));  post = post / sum(post);
    field = nan(map.nRows, map.nCols);
    field(map.cellId > 0) = post(map.cellId(map.cellId > 0));
    xv = ((1:map.nCols) - 0.5) * cfg.cellSize;
    yv = ((1:map.nRows) - 0.5) * cfg.cellSize;
    subplot(1, 2, t); hold on; axis equal; box on;
    himg = imagesc(xv, yv, field);  set(himg, 'AlphaData', ~isnan(field));
    set(gca, 'YDir', 'normal'); colorbar;
    plot(bc.pos(:,1), bc.pos(:,2), 'k^', 'MarkerFaceColor', 'w');
    plot(map.center(iTrue,1), map.center(iTrue,2), 'rp', 'MarkerSize', 14, 'MarkerFaceColor', 'r');
    xlim([0 map.nCols*cfg.cellSize]); ylim([0 map.nRows*cfg.cellSize]);
    title(sprintf('%s: 별 = 정답 셀, 삼각형 = 비콘', types{t}));

    % (2) 점검: 모든 셀에서 RSS만으로 1위가 정답인 비율 (200회 반복)
    nRep = 200;  hits = zeros(N, 1);
    for rep = 1:nRep
        for i = 1:N
            r = rm.mu(i, :) + cfg.rssSigma * randn(1, B);
            r(rand(1, B) < cfg.pktLoss) = NaN;       % 패킷 손실
            r(r < cfg.detThr) = NaN;                 % 감지 한계
            [~, j] = max(signalLogLik(r, rm, cfg));
            hits(i) = hits(i) + (j == i);
        end
    end
    fprintf('%s: N=%d, RSS 단독 1회 적중률 %.3f (셀별 최저 %.2f, 최고 %.2f)\n', ...
        types{t}, N, mean(hits)/nRep, min(hits)/nRep, max(hits)/nRep);
end

% 극단값 점검: 모든 비콘이 -110 dBm이어도 수치가 깨지지 않아야 한다
ll = signalLogLik(-110 * ones(1, B), rm, cfg);
assert(all(isfinite(ll)), '극단 RSS에서 수치가 깨졌습니다.');
disp('극단 RSS(-110 dBm) 점검 통과');
