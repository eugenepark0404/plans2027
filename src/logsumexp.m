function s = logsumexp(a, dim)
%LOGSUMEXP log(sum(exp(a), dim))를 수치적으로 안전하게 계산한다.
if nargin < 2
    dim = find(size(a) ~= 1, 1);
    if isempty(dim), dim = 1; end
end
m = max(a, [], dim);
m(~isfinite(m)) = 0;                 % 전부 -Inf인 경우 NaN 방지
s = m + log(sum(exp(a - m), dim));
end
