function radioMap = buildRadioMap(beacons, map, cfg)
%BUILDRADIOMAP 셀 x 비콘 평균 RSS 표(전파 지도). 지금은 거리 감쇠 모델 버전.
%   (실측 조사 데이터로 만드는 버전은 1월에 같은 출력 형식으로 추가한다.)
%   radioMap.mu (N x B), .sigma (N x B), .detThr (스칼라)
n = cfg.pathLossExp.(lower(map.type));
dx = map.center(:,1) - beacons.pos(:,1)';      % N x B
dy = map.center(:,2) - beacons.pos(:,2)';
d = max(sqrt(dx.^2 + dy.^2), cfg.minDist);
mu = beacons.tx(:)' - 10 * n * log10(d);
radioMap = struct('mu', mu, 'sigma', cfg.rssSigma * ones(size(mu)), ...
    'detThr', cfg.detThr);
end
