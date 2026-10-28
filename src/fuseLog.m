function logPost = fuseLog(logPrior, logLik, w, cfg)
%FUSELOG 가중 기하 결합: posterior ∝ prior^(1-w) * likelihood^w  (로그 영역)
%   w = 0 이면 이동만(prior), w = 1 이면 신호만. 결과는 정규화 + 확률 하한 적용.
%   w가 0 또는 1일 때 0 * (-Inf) = NaN 이 되지 않도록 해당 항은 아예 더하지 않는다.
lp = zeros(numel(logPrior), 1);
if w < 1, lp = lp + (1 - w) * logPrior(:); end
if w > 0, lp = lp + w * logLik(:); end
logPost = floorLog(lp, cfg);
end
