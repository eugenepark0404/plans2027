% T4 완료 기준: w-성능 곡선이 나오고, 2장 세 칸 예시 표와 같은 숫자가 재현된다.
% 사용: MATLAB 현재 폴더를 scripts 로 바꾼 뒤 checkFuse 실행 (30초~1분)
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();

% (1) 2장 세 칸 예시
fprintf('2장 예시 (prior = [0.2 0.5 0.3], 우도 = [0.3 0.3 0.6])\n');
for w = [0 0.2 0.5 0.8 1]
    p = exp(fuseLog(log([0.2 0.5 0.3])', log([0.3 0.3 0.6])', w, cfg))';
    [~, top] = max(p);  letters = 'ABC';
    fprintf('  w=%.1f: [%.2f %.2f %.2f]  1위 = %s\n', w, p, letters(top));
end

% (2) 장난감 경로 10개로 고정 w 스윕 (손으로 만든 짧은 경로: 코드 점검용, 연구 결과 아님)
types = {'hall', 'corridor'};
figure('Position', [100 100 1100 650]);
for t = 1:2
    map = makeMap(types{t}, cfg);  bc = placeBeacons(map, cfg);  rm = buildRadioMap(bc, map, cfg);
    trajs = cell(1, 10);
    for i = 1:10, trajs{i} = makeToyTraj(map, bc, cfg, 100 + i, 120); end
    sw = sweepFixedW(trajs, map, rm, cfg);
    [wH, iH] = bestFixedW(sw, 'hit');  [wL, iL] = bestFixedW(sw, 'logloss');
    fprintf('\n%s: 경로 10개 x 120 에포크\n', types{t});
    fprintf('  최적 고정 w: 적중 기준 %.2f (적중률 %.3f), 로그손실 기준 %.2f (손실 %.3f)\n', ...
        wH, mean(sw.hit(iH, :)), wL, mean(sw.logloss(iL, :)));
    fprintf('  RSS 단독(w=1) 적중 %.3f, PDR 단독(w=0) 적중 %.3f\n', mean(sw.hit(end, :)), mean(sw.hit(1, :)));
    subplot(2, 2, t); hold on; box on;
    plot(sw.wGrid, sw.hit, '-', 'Color', [0.8 0.8 0.8]);
    plot(sw.wGrid, mean(sw.hit, 2), 'b-', 'LineWidth', 2);  plot(wH, mean(sw.hit(iH, :)), 'rp', 'MarkerSize', 12);
    xlabel('고정 w (0 = 이동만, 1 = 신호만)'); ylabel('셀 적중률'); title([types{t} ': 적중률 (회색 = 경로별)']);
    subplot(2, 2, 2 + t); hold on; box on;
    plot(sw.wGrid, sw.logloss, '-', 'Color', [0.8 0.8 0.8]);
    plot(sw.wGrid, mean(sw.logloss, 2), 'b-', 'LineWidth', 2);  plot(wL, mean(sw.logloss(iL, :)), 'rp', 'MarkerSize', 12);
    xlabel('고정 w'); ylabel('로그 손실'); title([types{t} ': 로그 손실']);
end
