function trajs = simulateSet(map, beacons, cfg, nPaths, seed)
%SIMULATESET 경로 nPaths개를 만든다. 경로 i의 시드는 seed*1000 + i (재현 가능).
%   각 경로의 pathId와 session은 i로 둔다. (T5b에서 세션 오프셋이 이 번호를 쓴다.)
trajs = cell(1, nPaths);
for i = 1:nPaths
    tr = simulateTraj(map, beacons, cfg, seed * 1000 + i);
    tr.pathId = i;  tr.session = i;
    trajs{i} = tr;
end
end
