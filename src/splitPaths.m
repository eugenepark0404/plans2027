function sp = splitPaths(trajs, ratios, seed)
%SPLITPATHS 경로 단위로 훈련/검증/테스트를 나눈다(6.5). 같은 경로의 샘플은 한 덩어리에만 들어간다.
%   ratios = [0.6 0.2 0.2]. sp.train/.val/.test 는 trajs의 인덱스. 겹침 검사 포함(단위 테스트 8번).
n = numel(trajs);
ids = cellfun(@(x) x.pathId, trajs);
assert(numel(unique(ids)) == n, '경로 번호(pathId)가 서로 달라야 합니다.');
rs = RandStream('mt19937ar', 'Seed', seed);
perm = randperm(rs, n);
nTr = round(ratios(1) * n);  nVa = round(ratios(2) * n);
sp.train = sort(perm(1:nTr));
sp.val   = sort(perm(nTr+1 : nTr+nVa));
sp.test  = sort(perm(nTr+nVa+1 : end));
a = ids(sp.train);  b = ids(sp.val);  c = ids(sp.test);
assert(isempty(intersect(a, b)) && isempty(intersect(a, c)) && isempty(intersect(b, c)), ...
    '훈련/검증/테스트 경로 번호가 겹칩니다.');
assert(numel(a) + numel(b) + numel(c) == n, '분할에서 빠진 경로가 있습니다.');
end
