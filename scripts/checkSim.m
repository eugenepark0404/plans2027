% T5a 완료 기준: 경로 50개를 자동 생성해 T4 파이프라인으로 돌린다.
% 사용: MATLAB 현재 폴더를 scripts 로 바꾼 뒤 checkSim 실행.
% 경로 50개 x w 21개를 지도마다 돌리므로 수 분~십수 분 걸릴 수 있다(점이 w마다 하나씩 찍힘).
% 먼저 아래 nPaths를 10으로 바꿔 빠르게 확인한 뒤 50으로 돌려도 된다.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();  cfg.verbose = true;
nPaths = 50;  types = {'hall', 'corridor'};
figure('Position', [50 50 1300 800]);
for t = 1:2
    map = makeMap(types{t}, cfg);  bc = placeBeacons(map, cfg);  rm = buildRadioMap(bc, map, cfg);
    tic;  trajs = simulateSet(map, bc, cfg, nPaths, 11);  tGen = toc;
    nEp = cellfun(@(x) size(x.rss, 1), trajs);
    fprintf('\n=== %s: 경로 %d개 생성 %.1f초 ===\n', types{t}, nPaths, tGen);
    fprintf('  에포크 수 %d~%d (목표 180~240), 경유점 수 %d~%d, 속도 %.2f~%.2f m/s\n', ...
        min(nEp), max(nEp), min(cellfun(@(x) x.nWaypoints, trajs)), max(cellfun(@(x) x.nWaypoints, trajs)), ...
        min(cellfun(@(x) x.speed, trajs)), max(cellfun(@(x) x.speed, trajs)));

    % (1) 그림: 지도 + 경로 3개
    subplot(2, 3, 3*(t-1) + 1); hold on; axis equal; box on;
    [H, W] = size(map.pix);
    imagesc([0 W*cfg.res], [0 H*cfg.res], ~map.pix);  colormap(gca, [1 1 1; 0.8 0.8 0.8]);
    set(gca, 'YDir', 'normal');  plot(bc.pos(:,1), bc.pos(:,2), 'k^', 'MarkerFaceColor', 'w');
    cols = lines(3);
    for i = 1:3
        plot(trajs{i}.pos(:,1), trajs{i}.pos(:,2), '-', 'Color', cols(i,:));
        plot(trajs{i}.pos(1,1), trajs{i}.pos(1,2), 'o', 'Color', cols(i,:), 'MarkerFaceColor', cols(i,:));
    end
    xlim([0 W*cfg.res]); ylim([0 H*cfg.res]);  title([types{t} ': 참 경로 3개 (원 = 시작)']);

    % (2) 점검: PDR만으로 적분한 위치 오차는 시간이 갈수록 커지는가 (5.6의 2번)
    errT = nan(nPaths, 240);
    for i = 1:nPaths
        tr = trajs{i};  T = size(tr.pos, 1);
        dr = tr.pos(1, :) + cumsum([0 0; tr.pdr(2:end, :)], 1);
        errT(i, 1:T) = sqrt(sum((dr - tr.pos).^2, 2))';
    end
    subplot(2, 3, 3*(t-1) + 2); hold on; box on;
    plot(1:240, mean(errT, 1, 'omitnan'), 'b-', 'LineWidth', 2);
    xlabel('에포크'); ylabel('PDR만 적분한 위치 오차 [m] (경로 평균)'); title('PDR 오차가 시간에 따라 커지는가');
    for e = [30 100 180]
        fprintf('  PDR만 적분한 위치 오차 @에포크 %d: 평균 %.2f m\n', e, mean(errT(:, e), 'omitnan'));
    end

    % (3) T4 파이프라인: 고정 w 스윕 (경로 50개 전부, 코드 점검용)
    sw = sweepFixedW(trajs, map, rm, cfg);
    [wH, iH] = bestFixedW(sw, 'hit');  [wL, iL] = bestFixedW(sw, 'logloss');
    fprintf('  RSS 단독(w=1) 적중 %.3f, PDR 단독(w=0) 적중 %.3f\n', mean(sw.hit(end, :)), mean(sw.hit(1, :)));
    fprintf('  최적 고정 w: 적중 기준 %.2f (%.3f), 로그 손실 기준 %.2f (%.3f)\n', ...
        wH, mean(sw.hit(iH, :)), wL, mean(sw.logloss(iL, :)));
    subplot(2, 3, 3*(t-1) + 3); hold on; box on;
    yyaxis left;  plot(sw.wGrid, mean(sw.hit, 2), 'b-', 'LineWidth', 2);  plot(wH, mean(sw.hit(iH, :)), 'bp', 'MarkerSize', 12);
    ylabel('셀 적중률');
    yyaxis right; plot(sw.wGrid, mean(sw.logloss, 2), 'r-', 'LineWidth', 2);  plot(wL, mean(sw.logloss(iL, :)), 'rp', 'MarkerSize', 12);
    ylabel('로그 손실');  xlabel('고정 w (0 = 이동만, 1 = 신호만)');  title([types{t} ': w 곡선 (경로 50개 평균)']);
end
