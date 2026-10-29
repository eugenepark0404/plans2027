% T6 완료 기준: 한 경로에서 세 가지(최적 고정, 두 oracle)의 w 변화 그림 + oracle 이득 미리보기.
% 사용: MATLAB 현재 폴더를 scripts 로 바꾼 뒤 checkOracle 실행 (지도마다 수 분)
% 주의: 아래 이득은 가정에서 나온 값이며 코드 점검용이다. G1(11/8)에서 잡음 설정 3개로 정식으로 본다.
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();  cfg.verbose = true;
types = {'hall', 'corridor'};
figure('Position', [50 50 1300 700]);
for t = 1:2
    map = makeMap(types{t}, cfg);  bc = placeBeacons(map, cfg);  rm = buildRadioMap(bc, map, cfg);
    trajs = simulateSet(map, bc, cfg, 60, 21);
    sp = splitPaths(trajs, [0.6 0.2 0.2], 5);
    val = trajs(sp.val);
    fprintf('\n=== %s: 경로 60개를 훈련 %d / 검증 %d / 테스트 %d 로 분할 (겹침 없음) ===\n', ...
        types{t}, numel(sp.train), numel(sp.val), numel(sp.test));

    sw = sweepFixedW(val, map, rm, cfg);                 % 최적 고정 w는 검증 경로에서 고른다
    [wH, iH] = bestFixedW(sw, 'hit');  [wL, iL] = bestFixedW(sw, 'logloss');
    fixedHit = mean(sw.hit(iH, :));  fixedLL = mean(sw.logloss(iL, :));

    nV = numel(val);  oraLL = zeros(nV, 1);  oraHit = zeros(nV, 1);  runsLL = cell(nV, 1);  runsH = cell(nV, 1);
    for i = 1:nV
        runsLL{i} = oracleRun(val{i}, 'logloss', map, rm, cfg);
        runsH{i}  = oracleRun(val{i}, 'hit',     map, rm, cfg);
        oraLL(i)  = metricsPerPath(runsLL{i}, val{i}, cfg).logloss;
        oraHit(i) = metricsPerPath(runsH{i},  val{i}, cfg).hit;
    end
    fprintf('최적 고정: 적중 기준 w=%.2f (%.3f), 로그 손실 기준 w=%.2f (%.3f)\n', wH, fixedHit, wL, fixedLL);
    fprintf('log-loss oracle: 로그 손실 %.3f -> oracle 이득 %.3f\n', mean(oraLL), fixedLL - mean(oraLL));
    fprintf('hit oracle     : 적중 %.3f -> oracle 이득 %+.3f\n', mean(oraHit), mean(oraHit) - fixedHit);
    fprintf('경로별 이득이 0보다 큰 경로: 로그 손실 %d/%d, 적중 %d/%d\n', ...
        sum(sw.logloss(iL, :)' - oraLL > 0), nV, sum(oraHit - sw.hit(iH, :)' > 0), nV);
    wsLL = cell2mat(cellfun(@(r) r.w(2:end), runsLL, 'UniformOutput', false));
    wsH  = cell2mat(cellfun(@(r) r.w(2:end), runsH,  'UniformOutput', false));
    fprintf('oracle이 고른 w: log-loss 평균 %.2f (5/95%% %.2f/%.2f), hit 평균 %.2f (5/95%% %.2f/%.2f)\n', ...
        mean(wsLL), prctile(wsLL, 5), prctile(wsLL, 95), mean(wsH), prctile(wsH, 5), prctile(wsH, 95));

    % 한 경로에서 w의 시간 변화
    r1 = runFilter(val{1}, wL, map, rm, cfg);
    subplot(2, 2, 2*(t-1) + 1); hold on; box on;
    plot(runsLL{1}.w, '-', 'Color', [0.85 0.33 0.1]);  plot(runsH{1}.w, '-', 'Color', [0.1 0.5 0.85]);
    plot(r1.w, 'k--', 'LineWidth', 1.5);
    ylim([-0.05 1.05]);  xlabel('에포크');  ylabel('w');
    legend('log-loss oracle', 'hit oracle', sprintf('최적 고정 (w=%.2f)', wL), 'Location', 'best');
    title([types{t} ': 한 경로에서 w의 시간 변화']);
    subplot(2, 2, 2*(t-1) + 2); hold on; box on;
    histogram(wsLL(:), cfg.wGrid, 'FaceAlpha', 0.5);  histogram(wsH(:), cfg.wGrid, 'FaceAlpha', 0.5);
    xlabel('oracle이 고른 w');  ylabel('시점 수');  legend('log-loss oracle', 'hit oracle');
    title([types{t} ': oracle이 고른 w의 분포 (검증 경로 전체)']);
end
