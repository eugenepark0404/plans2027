function [wBest, iBest] = bestFixedW(sw, metric)
%BESTFIXEDW 경로 평균이 가장 좋은 w를 고른다. 지표마다 따로 고른다(6.1).
%   metric: 'hit'(높을수록 좋음) 또는 'logloss'(낮을수록 좋음)
%   동점이면 w가 0.5에 더 가까운 쪽을 택한다(6.2와 같은 규칙).
switch metric
    case 'hit',     v = mean(sw.hit, 2);      best = max(v);
    case 'logloss', v = mean(sw.logloss, 2);  best = min(v);
    otherwise, error('metric은 hit 또는 logloss');
end
cand = find(abs(v - best) < 1e-12);
[~, k] = min(abs(sw.wGrid(cand) - 0.5));
iBest = cand(k);  wBest = sw.wGrid(iBest);
end
