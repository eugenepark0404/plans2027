% T1 완료 기준: 두 지도를 그림으로 그려 눈으로 확인
% 실행: 프로젝트 루트에서 addpath('src'); checkMaps
addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));
cfg = defaultCfg();
types = {'corridor', 'hall'};
figure('Position', [100 100 1100 450]);
for t = 1:2
    map = makeMap(types{t}, cfg);
    fprintf('%s: 통행 가능 셀 %d개 (격자 %d x %d), 이웃 연결 %d개\n', ...
        types{t}, map.N, map.nRows, map.nCols, nnz(map.adj)/2);
    % 대칭성 점검
    assert(isequal(map.adj, map.adj.'), '이웃 행렬이 대칭이 아닙니다.');
    subplot(1, 2, t); hold on; axis equal; box on;
    [H, W] = size(map.pix);
    imagesc([0 W*cfg.res], [0 H*cfg.res], ~map.pix);   % 어두운 곳 = 통로 아님
    colormap(gca, [1 1 1; 0.8 0.8 0.8]); set(gca, 'YDir', 'normal');
    for i = 1:map.N
        x = map.center(i,1); y = map.center(i,2); h = cfg.cellSize/2;
        rectangle('Position', [x-h y-h cfg.cellSize cfg.cellSize], 'EdgeColor', [0.2 0.4 0.8]);
        text(x, y, num2str(i), 'HorizontalAlignment', 'center', 'FontSize', 7);
    end
    [ii, jj] = find(triu(map.adj));
    for e = 1:numel(ii)
        plot(map.center([ii(e) jj(e)], 1), map.center([ii(e) jj(e)], 2), '-', 'Color', [0.8 0.3 0.3 0.4]);
    end
    xlim([0 W*cfg.res]); ylim([0 H*cfg.res]);
    title(sprintf('%s (N = %d)', types{t}, map.N)); xlabel('x [m]'); ylabel('y [m]');
end
