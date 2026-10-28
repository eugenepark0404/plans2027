function logLik = signalLogLik(rss, radioMap, cfg)
%SIGNALLOGLIK 받은 RSS가 각 셀에서 나올 가능성의 로그 (N x 1)
%   rss: 1 x B (미수신은 NaN). 감지 한계보다 약한 값도 미수신으로 취급한다.
%   수신한 비콘: 가우시안 로그 우도 (셀과 무관한 상수는 생략)
%   미수신 비콘: "감지 한계 아래로 떨어질 확률"의 로그
%   비콘 하나의 기여는 cfg.logLikFloor 아래로 내려가지 않는다(셀 영구 배제 방지).
rss = rss(:)';
mu = radioMap.mu;  sg = radioMap.sigma;
got = ~isnan(rss) & (rss >= radioMap.detThr);
ll = -0.5 * ((rss - mu) ./ sg).^2;                       % N x B
zd = (radioMap.detThr - mu) ./ sg;
llMiss = log(0.5 * erfc(-zd / sqrt(2)));                  % log P(RSS < 감지 한계)
ll(:, ~got) = llMiss(:, ~got);
ll = max(ll, cfg.logLikFloor);                            % -Inf도 바닥값으로
logLik = sum(ll, 2);
end
