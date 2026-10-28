function map = makeMap(type, cfg)
%MAKEMAP 도면(0.1 m 격자)을 그려 셀 격자 지도를 만든다.
%   map = makeMap('corridor', cfg) 또는 makeMap('hall', cfg)
%
%   map.type, map.cellSize
%   map.nRows, map.nCols      셀 격자 크기(행=y 방향, 열=x 방향)
%   map.N                     통행 가능 셀 수
%   map.cellId (nRows x nCols) 통행 가능 셀의 번호, 아니면 0
%   map.center (N x 2)        셀 중심 좌표 [x y] (m)
%   map.rc     (N x 2)        셀의 [행 열] 위치
%   map.adj    (N x N sparse) 이웃 관계(대칭)
%   map.pix    (H x W logical) 0.1 m 해상도 통로 도면 (true = 통로)
%   map.doors  (D x 2)        문 중심 좌표 (격자에는 반영하지 않음, 경로 생성용)
%   map.wallSegs              벽 선분(T5b에서 채움)

if nargin < 2, cfg = defaultCfg(); end
res = cfg.res;
k = round(cfg.cellSize / res);
assert(abs(k*res - cfg.cellSize) < 1e-9, ...
    'cellSize는 res의 정수배여야 합니다.');

m = @(v) round(v / res);          % 미터 -> 픽셀 수

switch lower(type)
    case 'corridor'
        % ㄱ자 복도: 폭 3 m, 긴 변 24 m, 짧은 변 12 m (모퉁이 포함)
        W = m(24); H = m(12); w = m(3);
        pix = false(H, W);        % 행 = y, 열 = x
        pix(1:w, 1:W) = true;     % 긴 변: x 0~24, y 0~3
        pix(1:H, 1:w) = true;     % 짧은 변: x 0~3, y 0~12
        doors = [9 3; 17 0];      % 임시 위치(m). 복도 벽 쪽 문 두 곳
    case 'hall'
        % 홀: 15 m x 12 m 개방 공간, 1.5 m x 1.5 m 기둥 2개
        W = m(15); H = m(12);
        pix = true(H, W);
        pix(m(3)+1:m(4.5),  m(4.5)+1:m(6))  = false;   % 기둥 1
        pix(m(7.5)+1:m(9),  m(9)+1:m(10.5)) = false;   % 기둥 2
        doors = zeros(0, 2);
    otherwise
        error('type은 ''corridor'' 또는 ''hall'' 이어야 합니다.');
end

% ---- 셀 크기로 줄이기: 블록 면적의 passFrac 이상이 통로면 통행 가능 ----
nby = floor(H / k);  nbx = floor(W / k);
blocks = reshape(pix(1:nby*k, 1:nbx*k), k, nby, k, nbx);
frac = reshape(mean(mean(blocks, 1), 3), nby, nbx);
walk = frac >= cfg.passFrac;

% ---- 번호, 중심 좌표, 이웃 관계 ----
cellId = zeros(nby, nbx);
[r, c] = find(walk);                      % 열 우선 순서
N = numel(r);
cellId(sub2ind(size(cellId), r, c)) = 1:N;
center = [(c - 0.5) * cfg.cellSize, (r - 0.5) * cfg.cellSize];

if cfg.neighbor8
    offs = [-1 0; 1 0; 0 -1; 0 1; -1 -1; -1 1; 1 -1; 1 1];
else
    offs = [-1 0; 1 0; 0 -1; 0 1];
end
I = []; J = [];
for o = 1:size(offs, 1)
    rr = r + offs(o, 1);  cc = c + offs(o, 2);
    ok = rr >= 1 & rr <= nby & cc >= 1 & cc <= nbx;
    nb = zeros(N, 1);
    nb(ok) = cellId(sub2ind(size(cellId), rr(ok), cc(ok)));
    keep = nb > 0;
    I = [I; find(keep)];  J = [J; nb(keep)];   %#ok<AGROW>
end
adj = sparse(I, J, 1, N, N);

map = struct('type', type, 'cellSize', cfg.cellSize, ...
    'nRows', nby, 'nCols', nbx, 'N', N, 'cellId', cellId, ...
    'center', center, 'rc', [r c], 'adj', adj, 'pix', pix, ...
    'doors', doors, 'wallSegs', []);
end
