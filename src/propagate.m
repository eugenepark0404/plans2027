function logPrior = propagate(logPost, dxy, map, cfg)
%PROPAGATE 이전 사후분포를 PDR 변위만큼 밀고 가우시안으로 퍼뜨려 prior를 만든다.
%   logPost : N x 1 이전 사후분포(로그)
%   dxy     : 1 x 2 이번 에포크의 PDR 변위 추정 [dx dy] (m, 지도 좌표계)
%   logPrior: N x 1 (로그, 합이 1이 되도록 정규화)
%
%   각 셀 i의 중심을 dxy만큼 옮긴 점에서 도착 셀 j 중심까지의 거리로
%   가우시안(퍼짐 cfg.pdrSigma)을 만들고, 출발 셀마다 합이 1이 되게 정규화한다.
%   도착 후보는 통행 가능 셀뿐이라 벽 칸으로는 질량이 가지 않고,
%   목표점이 벽 안이면 가장 가까운 통행 가능 셀로 모인다.
C = map.center;                                   % N x 2
tgt = C + dxy(:)';                                % 이동한 점
D2 = (tgt(:,1) - C(:,1)').^2 + (tgt(:,2) - C(:,2)').^2;   % N x N (출발 i -> 도착 j)
logT = -D2 / (2 * cfg.pdrSigma^2);
logT = logT - logsumexp(logT, 2);                 % 출발 셀(행)마다 정규화
logPrior = logsumexp(logPost(:) + logT, 1)';      % 도착 셀마다 합산, N x 1
logPrior = logPrior - logsumexp(logPrior, 1);
end
