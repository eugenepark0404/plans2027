function traj = simulateTraj(map, beacons, cfg, seed)
%SIMULATETRAJ 정답을 아는 가짜 경로 하나를 만든다 (T5a 기본 시뮬레이터).
%   1) 시작점과 경유점 3~5개를 서로 6 m 이상 떨어지게 고른다.
%   2) 이웃 관계 그래프의 최단 경로로 잇고 이동 평균으로 부드럽게 다듬는다.
%   3) 경로마다 속도(1.2 m/s ±10%)를 정하고 1초 간격으로 샘플링한다.
%      코스가 짧으면 코스를 왕복하며 이어 붙여 180~240 에포크로 맞춘다.
%   4) 홀에서는 좌우로 작은 무작위 흔들림을 더해 자유 보행처럼 만든다.
%   5) RSS: 거리 감쇠 참값 + 가우시안 백색 잡음, 패킷 손실, 감지 한계.
%   6) PDR: 걸음 폭 배율(경로마다), 에포크 곱셈 잡음, 시작 방향 오차, 방향 드리프트(무작위 보행 누적).
%   (상관 RSS 오차, 세션 오프셋, 회전 의존 PDR 오차는 T5b에서 추가한다.)
%
%   traj.pos (T x 2) 참 위치, traj.cell (T x 1) 정답 셀, traj.rss (T x B, NaN = 미수신),
%   traj.pdr (T x 2) 에포크 t-1 -> t 의 변위 추정 (1행은 쓰지 않음), traj.heading (T x 1) 방향 추정
rs = RandStream('mt19937ar', 'Seed', seed);
sim = cfg.sim;
N = map.N;  B = size(beacons.pos, 1);
G = graph(map.adj);

% ---- 1) 에포크 수, 시작점과 경유점 (서로 minWpDist 이상). 후보를 걸러 가며 뽑고, 못 놓으면 경유점 수를 줄인다.
nEp = randi(rs, sim.epochRange, 1, 1);
k = randi(rs, sim.nWaypoints, 1, 1);
while true
    for attempt = 1:50
        pts = randi(rs, N, 1, 1);
        while numel(pts) < k + 1
            dm = min(sqrt((map.center(:, 1) - map.center(pts, 1)').^2 + ...
                          (map.center(:, 2) - map.center(pts, 2)').^2), [], 2);
            cand = find(dm >= sim.minWpDist);
            if isempty(cand), break; end
            pts(end+1, 1) = cand(randi(rs, numel(cand), 1, 1));          %#ok<AGROW>
        end
        if numel(pts) == k + 1, break; end
    end
    if numel(pts) == k + 1, break; end
    k = k - 1;
    assert(k >= 1, '경유점을 놓을 수 없습니다. minWpDist를 줄이세요.');
end

% ---- 2) 최단 경로로 잇고 다듬기
route = pts(1);
for i = 1:numel(pts) - 1
    seg = shortestpath(G, pts(i), pts(i+1));
    route = [route, seg(2:end)];                                        %#ok<AGROW>
end
poly = map.center(route, :);
s = [0; cumsum(sqrt(sum(diff(poly).^2, 2)))];
sf = (0:0.1:s(end))';
px = movmean(interp1(s, poly(:, 1), sf), sim.smoothWin);
py = movmean(interp1(s, poly(:, 2), sf), sim.smoothWin);
L = sf(end);

% ---- 3) 속도와 1초 샘플링 (코스를 왕복)
v = sim.speed * (1 + sim.speedVar * (2 * rand(rs) - 1));
se = mod((0:nEp-1)' * v, 2 * L);
se(se > L) = 2 * L - se(se > L);
pos = [interp1(sf, px, se), interp1(sf, py, se)];

% ---- 4) 홀: 좌우 흔들림 (AR(1), 상관 0.8). 통로 밖으로 나가면 흔들림을 적용하지 않는다.
if strcmpi(map.type, 'hall') && sim.hallWobble > 0
    tx = gradient(pos(:, 1));  ty = gradient(pos(:, 2));
    nn = max(hypot(tx, ty), 1e-9);
    nrm = [-ty ./ nn, tx ./ nn];
    o = zeros(nEp, 1);
    for e = 2:nEp
        o(e) = 0.8 * o(e-1) + sqrt(1 - 0.64) * sim.hallWobble * randn(rs);
    end
    cand = pos + o .* nrm;
    ok = isWalkable(map, cand, cfg);
    pos(ok, :) = cand(ok, :);
end

% ---- 정답 셀: 위치가 들어 있는 셀. 통로가 아닌 셀이면 가장 가까운 통로 셀.
r = min(max(floor(pos(:, 2) / cfg.cellSize) + 1, 1), map.nRows);
c = min(max(floor(pos(:, 1) / cfg.cellSize) + 1, 1), map.nCols);
trueCell = map.cellId(sub2ind(size(map.cellId), r, c));
for e = find(trueCell == 0)'
    [~, trueCell(e)] = min(sum((map.center - pos(e, :)).^2, 2));
end

% ---- 6) PDR 변위 추정
dt = [0 0; diff(pos)];
pscale = 1 + sim.pdrScaleSd * randn(rs);
hd = deg2rad(sim.h0Deg) * randn(rs);
pdr = zeros(nEp, 2);  heading = nan(nEp, 1);
for e = 2:nEp
    hd = hd + deg2rad(sim.driftDeg) * randn(rs);
    R = [cos(hd) -sin(hd); sin(hd) cos(hd)];
    pdr(e, :) = (pscale * (1 + sim.pdrNoise * randn(rs)) * (R * dt(e, :)'))';
    heading(e) = atan2(pdr(e, 2), pdr(e, 1));
end

% ---- 5) RSS
n = cfg.pathLossExp.(lower(map.type));
dx = pos(:, 1) - beacons.pos(:, 1)';  dy = pos(:, 2) - beacons.pos(:, 2)';
d = max(hypot(dx, dy), cfg.minDist);
rss = beacons.tx(:)' - 10 * n * log10(d) + sim.rssScale * cfg.rssSigma * randn(rs, nEp, B);
rss(rand(rs, nEp, B) < cfg.pktLoss) = NaN;                              % 패킷 손실
rss(rss < cfg.detThr) = NaN;                                            % 감지 한계

traj = struct('t', (0:nEp-1)', 'pos', pos, 'cell', trueCell, 'rss', rss, 'pdr', pdr, ...
    'heading', heading, 'pathId', 0, 'session', 0, 'seed', seed, ...
    'speed', v, 'nWaypoints', k, 'routeLen', L);
end

function ok = isWalkable(map, p, cfg)
H = size(map.pix, 1);  W = size(map.pix, 2);
inb = p(:, 1) > 0 & p(:, 1) < W * cfg.res & p(:, 2) > 0 & p(:, 2) < H * cfg.res;
iy = min(max(ceil(p(:, 2) / cfg.res), 1), H);
ix = min(max(ceil(p(:, 1) / cfg.res), 1), W);
ok = inb & map.pix(sub2ind(size(map.pix), iy, ix));
end
