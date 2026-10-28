function lp = floorLog(lp, cfg)
%FLOORLOG 로그 확률을 정규화하고, 칸당 확률 하한(cfg.probFloor)을 적용한 뒤 다시 정규화한다.
%   하한은 모든 방법에 똑같이 적용한다(4.3).
lp = lp(:) - logsumexp(lp(:), 1);
lp = max(lp, log(cfg.probFloor));
lp = lp - logsumexp(lp, 1);
end
