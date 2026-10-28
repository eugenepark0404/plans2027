function traj = makeToyTraj(map, beacons, cfg, seed, T)
%MAKETOYTRAJ 손으로 만든 장난감 경로(코드 점검용). 본격 시뮬레이터는 T5a에서 만든다.
%   지도 위 꺾은선을 왕복하며 걷고, 정답 셀·RSS·PDR 변위를 만든다.
%   PDR 오차: 경로별 걸음 폭 배율(5%), 시작 방향 오차 3도, 에포크마다 0.3도 무작위 누적, 곱셈 잡음 5%.
if nargin < 5, T = 120; end
rs = RandStream('mt19937ar', 'Seed', seed);
switch lower(map.type)
    case 'hall',     P = [2.25 2.25; 12.75 2.25; 12.75 9.75; 2.25 9.75];
    case 'corridor', P = [22.5 0.75; 0.75 0.75; 0.75 11.25];
    otherwise, error('알 수 없는 지도 종류');
end
seg = sqrt(sum(diff(P).^2, 2));  cum = [0; cumsum(seg)];  L = cum(end);
pos = zeros(T, 2);  trueCell = zeros(T, 1);
for e = 1:T
    s = mod((e-1) * cfg.toySpeed, 2*L);
    if s > L, s = 2*L - s; end                       % 왕복
    j = min(find(s >= cum(1:end-1), 1, 'last'), numel(seg));
    pos(e, :) = P(j, :) + (P(j+1, :) - P(j, :)) / seg(j) * (s - cum(j));
    [~, trueCell(e)] = min(sum((map.center - pos(e, :)).^2, 2));   % 중심이 가장 가까운 셀
end
dt = [0 0; diff(pos)];
scale = 1 + 0.05 * randn(rs);
hd = deg2rad(3) * randn(rs);
pdr = zeros(T, 2);
for e = 2:T
    hd = hd + deg2rad(0.3) * randn(rs);
    R = [cos(hd) -sin(hd); sin(hd) cos(hd)];
    pdr(e, :) = (scale * (1 + 0.05 * randn(rs)) * (R * dt(e, :)'))';
end
B = size(beacons.pos, 1);
n = cfg.pathLossExp.(lower(map.type));
dx = pos(:,1) - beacons.pos(:,1)';  dy = pos(:,2) - beacons.pos(:,2)';
d = max(sqrt(dx.^2 + dy.^2), cfg.minDist);
rss = beacons.tx(:)' - 10 * n * log10(d) + cfg.rssSigma * randn(rs, T, B);
rss(rand(rs, T, B) < cfg.pktLoss) = NaN;             % 패킷 손실
rss(rss < cfg.detThr) = NaN;                         % 감지 한계
traj = struct('t', (0:T-1)', 'pos', pos, 'cell', trueCell, 'rss', rss, 'pdr', pdr, 'seed', seed);
end
