function beacons = placeBeacons(map, cfg)
%PLACEBEACONS 시뮬레이션용 비콘 11개 배치 (로드맵 5.1)
%   복도: 중심선을 따라 일정 간격, 양쪽 벽에 번갈아 (벽에서 0.25 m 안쪽)
%   홀  : 가장자리 8개 + 기둥 근처 3개
%   beacons.pos (B x 2) [m], .height, .tx (B x 1) 1 m 기준 송신 출력, .id
B = cfg.nBeacons;
switch lower(map.type)
    case 'corridor'
        assert(B == 11, '복도 배치는 비콘 11개 기준입니다.');
        P = [24 1.5; 1.5 1.5; 1.5 12];            % 복도 중심선
        segLen = sqrt(sum(diff(P).^2, 2));
        cum = [0; cumsum(segLen)];
        L = cum(end);
        s = linspace(0.25, L - 0.25, B);
        pos = zeros(B, 2);
        for i = 1:B
            k = find(s(i) <= cum(2:end), 1, 'first');
            dir = (P(k+1,:) - P(k,:)) / segLen(k);
            pt = P(k,:) + dir * (s(i) - cum(k));
            nrm = [-dir(2) dir(1)];
            side = (-1)^(i-1);
            pos(i,:) = pt + side * 1.25 * nrm;      % 중심선에서 1.25 m = 벽에서 0.25 m
        end
    case 'hall'
        assert(B == 11, '홀 배치는 비콘 11개 기준입니다.');
        edge = [0.25 0.25; 7.5 0.25; 14.75 0.25; 14.75 6; ...
                14.75 11.75; 7.5 11.75; 0.25 11.75; 0.25 6];
        pill = [4.25 3.75; 9.75 6.75; 10.75 8.25];  % 기둥 근처 3개
        pos = [edge; pill];
    otherwise
        error('알 수 없는 지도 종류');
end
% 모든 비콘이 통로 위에 있는지 점검
iy = min(max(ceil(pos(:,2) / cfg.res), 1), size(map.pix, 1));
ix = min(max(ceil(pos(:,1) / cfg.res), 1), size(map.pix, 2));
assert(all(map.pix(sub2ind(size(map.pix), iy, ix))), '통로 밖에 놓인 비콘이 있습니다.');
beacons = struct('pos', pos, 'height', cfg.beaconHeight * ones(B,1), ...
    'tx', cfg.P1m * ones(B,1), 'id', (1:B)');
end
