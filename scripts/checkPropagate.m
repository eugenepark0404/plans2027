% T3 완료 기준: 직선 이동 시 분포의 중심이 이동하고 퍼짐이 커지는 그림
% 사용: MATLAB 현재 폴더를 scripts 로 바꾼 뒤 checkPropagate 실행
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();
map = makeMap('hall', cfg);
N = map.N;
step = 1.2;  nEp = 10;                      % 에포크당 1.2 m, 10 에포크

% 출발: 왼쪽 중간(기둥이 없는 줄, y = 5.25 m 근처)의 한 셀
[~, i0] = min(sum((map.center - [2.25 5.25]).^2, 2));
lp = -Inf(N, 1);  lp(i0) = 0;

xv = ((1:map.nCols) - 0.5) * cfg.cellSize;
yv = ((1:map.nRows) - 0.5) * cfg.cellSize;
meanX = zeros(nEp+1, 1);  stdX = zeros(nEp+1, 1);
p = exp(lp);  meanX(1) = p' * map.center(:,1);  stdX(1) = 0;

figure('Position', [100 100 1000 420]);
subplot(1, 2, 1);
for t = 1:nEp
    lp = propagate(lp, [step 0], map, cfg);
    p = exp(lp);
    assert(abs(sum(p) - 1) < 1e-9 && all(isfinite(lp)), '확률 합이 1이 아니거나 NaN/Inf 발생');
    meanX(t+1) = p' * map.center(:,1);
    stdX(t+1)  = sqrt(p' * (map.center(:,1) - meanX(t+1)).^2);

    field = nan(map.nRows, map.nCols);
    field(map.cellId > 0) = p(map.cellId(map.cellId > 0));
    h = imagesc(xv, yv, field);  set(h, 'AlphaData', ~isnan(field));
    set(gca, 'YDir', 'normal'); axis equal; colorbar; hold on;
    plot(meanX(t+1), map.center(i0,2), 'rx', 'MarkerSize', 10, 'LineWidth', 2); hold off;
    xlim([0 map.nCols*cfg.cellSize]); ylim([0 map.nRows*cfg.cellSize]);
    title(sprintf('홀 직진 PDR 전파: 에포크 %d (x = 분포 평균)', t));
    drawnow; pause(0.3);
end
subplot(1, 2, 2); hold on; box on;
plot(0:nEp, meanX, 'o-');  plot(0:nEp, map.center(i0,1) + step*(0:nEp), 'k--');
plot(0:nEp, stdX, 's-');
legend('분포 평균 x', '이상적 위치(출발 + 1.2 m x 에포크)', '표준편차 x', 'Location', 'northwest');
xlabel('에포크'); ylabel('[m]'); title('중심 이동과 퍼짐 증가');

% ---- 단위 테스트 4: 변위 0, 퍼짐 거의 0이면 prior == 이전 사후
cfg0 = cfg;  cfg0.pdrSigma = 1e-3;
rng(cfg.seed);  lp0 = randn(N, 1);  lp0 = lp0 - logsumexp(lp0, 1);
diffMax = max(abs(propagate(lp0, [0 0], map, cfg0) - lp0));
assert(diffMax < 1e-9, '테스트 4 실패');
fprintf('테스트 4 통과 (최대 차이 %.1e)\n', diffMax);

% ---- 극단 변위(100 m)에서도 수치가 깨지지 않는가
big = propagate(lp0, [100 100], map, cfg);
assert(all(isfinite(big)) && abs(sum(exp(big)) - 1) < 1e-9, '극단 변위 실패');
disp('극단 변위(100 m) 점검 통과');

% ---- 복도: 벽 방향으로 이동해도 질량이 통로 밖으로 가지 않는다(통로 셀만 있으므로 자동)
mapC = makeMap('corridor', cfg);
[~, j0] = min(sum((mapC.center - [12.75 0.75]).^2, 2));
lpc = -Inf(mapC.N, 1);  lpc(j0) = 0;
for t = 1:3, lpc = propagate(lpc, [0 1.5], mapC, cfg); end
my = exp(lpc)' * mapC.center(:,2);
fprintf('복도 벽 방향 3회 이동 후 평균 y = %.2f m (통로는 y < 3)\n', my);
assert(my < 3, '벽 방향 이동 점검 실패');
