% 4.4 단위 테스트 모음. 새 모듈을 만들 때마다 여기에 테스트를 더한다.
% 사용: MATLAB 현재 폴더를 scripts 로 바꾼 뒤 runUnitTests 실행
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();
map = makeMap('hall', cfg);  bc = placeBeacons(map, cfg);  rm = buildRadioMap(bc, map, cfg);
N = map.N;
tr = makeToyTraj(map, bc, cfg, 1, 60);

% 테스트 1: 모든 시점에서 확률 합이 1이고 NaN/Inf가 없다 (+ 확률 하한 유지)
run = runFilter(tr, 0.3, map, rm, cfg);
check('1 합=1, NaN/Inf 없음', all(isfinite(run.logPost(:))) && ...
    max(abs(sum(exp(run.logPost), 1) - 1)) < 1e-9);
check('1 확률 하한 유지', min(exp(run.logPost(:))) > 0.99 * cfg.probFloor / (1 + N*cfg.probFloor));

% 테스트 2: w=0이면 사후=prior, w=1이면 신호만의 분포
rng(2);  lpri = randn(N, 1);  llik = randn(N, 1);
check('2 w=0 -> prior', max(abs(fuseLog(lpri, llik, 0, cfg) - floorLog(lpri, cfg))) < 1e-12);
check('2 w=1 -> 신호만', max(abs(fuseLog(lpri, llik, 1, cfg) - floorLog(llik, cfg))) < 1e-12);

% 테스트 3 (수정판): 우도가 모든 칸에서 같으면 사후 = prior^(1-w)를 정규화한 것.
%   w=0일 때만 prior와 같다. (가중 기하 결합은 prior를 평평하게 만든다. 2.3절의 "손잡이 하나" 문제)
for w = [0 0.4 0.8]
    got = fuseLog(lpri, zeros(N, 1), w, cfg);
    check(sprintf('3 우도 동일, w=%.1f', w), max(abs(got - floorLog((1-w) * lpri, cfg))) < 1e-12);
end

% 테스트 4: 변위 0, 퍼짐 거의 0이면 prior = 이전 사후
cfg0 = cfg;  cfg0.pdrSigma = 1e-3;
lp0 = floorLog(randn(N, 1), cfg);
check('4 변위 0 -> prior = 이전 사후', max(abs(propagate(lp0, [0 0], map, cfg0) - lp0)) < 1e-9);

% 테스트 5: 2장의 세 칸 예시 표
tab = [0.20 0.50 0.30; 0.21 0.45 0.34; 0.23 0.37 0.40; 0.24 0.29 0.46; 0.25 0.25 0.50];
ws = [0 0.2 0.5 0.8 1];  ok = true;
for i = 1:5
    p = exp(fuseLog(log([0.2 0.5 0.3])', log([0.3 0.3 0.6])', ws(i), cfg))';
    ok = ok && max(abs(p - tab(i, :))) < 0.006;
end
check('5 세 칸 예시 표 재현', ok);

% 테스트 7: 시드를 고정하면 같은 결과
trB = makeToyTraj(map, bc, cfg, 1, 60);
runB = runFilter(trB, 0.3, map, rm, cfg);
check('7 같은 시드 -> 같은 결과', isequaln(tr.rss, trB.rss) && isequal(run.logPost, runB.logPost));

% 테스트 9: 극단적인 RSS(-110 dBm)에서도 수치가 깨지지 않는다
trX = tr;  trX.rss = -110 * ones(size(tr.rss));
runX = runFilter(trX, 0.5, map, rm, cfg);
check('9 극단 RSS', all(isfinite(runX.logPost(:))));

% ---- T5a 시뮬레이터 테스트 ----
simA = simulateTraj(map, bc, cfg, 5);  simB = simulateTraj(map, bc, cfg, 5);
check('S1 같은 시드 -> 같은 경로', isequaln(simA.rss, simB.rss) && isequal(simA.pos, simB.pos) && isequal(simA.pdr, simB.pdr));
set5 = simulateSet(map, bc, cfg, 5, 3);
nEp5 = cellfun(@(x) size(x.rss, 1), set5);
check('S2 에포크 수 180~240', all(nEp5 >= 180 & nEp5 <= 240));
check('S3 정답 셀이 1..N, 참 위치가 통로 위', all(cellfun(@(x) all(x.cell >= 1 & x.cell <= map.N), set5)) && ...
    all(cellfun(@(x) all(map.cellId(sub2ind(size(map.cellId), min(max(floor(x.pos(:,2)/cfg.cellSize)+1,1),map.nRows), ...
    min(max(floor(x.pos(:,1)/cfg.cellSize)+1,1),map.nCols))) > 0), set5)));
check('S4 경로 번호가 서로 다름', numel(unique(cellfun(@(x) x.pathId, set5))) == 5);
runS = runFilter(set5{1}, 0.3, map, rm, cfg);
check('S5 시뮬레이션 경로에서 필터가 정상 동작', all(isfinite(runS.logPost(:))));

disp('--- 단위 테스트 끝 (6: oracle, 8: 분할 겹침 검사는 해당 모듈을 만들 때 추가) ---');

function check(name, cond)
if cond, fprintf('  통과  %s\n', name);
else, error('  실패  %s', name); end
end
