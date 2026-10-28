function m = metricsPerPath(run, traj, cfg)
%METRICSPERPATH 경로 하나의 지표. 첫 에포크는 모든 전략이 같으므로 제외한다(cfg.skipFirst).
%   m.hit 적중률, m.logloss 평균 -ln(정답 확률), m.top3 상위 3위 안 비율
%   m.hitVec, m.nllVec : 시점별 값(나중에 경계 셀·전반/후반 분석에 사용)
T = size(run.logPost, 2);
idx = 1:T;  if cfg.skipFirst, idx = 2:T; end
trueCell = traj.cell(idx);  trueCell = trueCell(:);
LP = run.logPost(:, idx);
lpTrue = LP(sub2ind(size(LP), trueCell', 1:numel(idx)));      % 1 x len
[~, top1] = max(LP, [], 1);
[~, order] = sort(LP, 1, 'descend');
m.hitVec = (top1(:) == trueCell);
m.nllVec = -lpTrue(:);
m.hit = mean(m.hitVec);
m.logloss = mean(m.nllVec);
m.top3 = mean(any(order(1:3, :) == trueCell', 1));
end
