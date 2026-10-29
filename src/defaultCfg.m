function cfg = defaultCfg()
%DEFAULTCFG 모든 설정을 모아 둔 구조체. 시작값이며 "조정" 항목은 개발 데이터에서 바꾼다.
cfg.seed      = 1;
cfg.cellSize  = 1.5;   % [m] 실측 파일럿 후 결정
cfg.res       = 0.1;   % [m] 도면 격자 해상도
cfg.passFrac  = 0.5;   % 셀 면적 중 통로 비율이 이 값 이상이면 통행 가능
cfg.neighbor8 = false; % false: 상하좌우 4방향, true: 대각 포함 8방향

% ---- 신호 모델 (T2) ----
cfg.nBeacons      = 11;
cfg.P1m           = -59;     % [dBm] 1 m에서의 RSS
cfg.pathLossExp   = struct('corridor', 2.0, 'hall', 2.2);
cfg.minDist       = 1;       % [m] 거리 하한 (log 발산 방지)
cfg.beaconHeight  = 2;       % [m] 2차원 시뮬레이션에서는 무시
cfg.rssSigma      = 5;       % [dB] 조정
cfg.detThr        = -95;     % [dBm] 감지 한계, 기기 의존
cfg.logLikFloor   = -8;      % 비콘 하나의 로그 우도 하한 (정규화 거리 4)
cfg.pktLoss       = 0.05;    % 에포크당 패킷 손실 확률 (시뮬레이터용)

% ---- PDR 전이 (T3) ----
cfg.pdrSigma      = 0.8;     % [m] 전이 퍼짐, 조정

% ---- 융합·지표 (T4) ----
cfg.probFloor     = 1e-6;            % 칸당 확률 하한, 모든 방법에 동일하게 적용
cfg.wGrid         = 0:0.05:1;        % 고정 w 후보 21개
cfg.skipFirst     = true;            % 첫 에포크(모든 전략이 같음)는 지표에서 제외
cfg.toySpeed      = 1.2;             % [m/에포크] 장난감 경로용

% ---- 시뮬레이터 (T5a). 3x3 조건 격자(5.5)에서 바꾸는 값은 rssScale, driftDeg ----
cfg.sim.speed       = 1.2;        % [m/s] 경로마다 +-speedVar
cfg.sim.speedVar    = 0.1;
cfg.sim.stepLen     = 0.7;        % [m] 걸음 폭 (걸음 수 특징에 사용, T9)
cfg.sim.nWaypoints  = [3 5];      % 경유점 수 범위
cfg.sim.minWpDist   = 6;          % [m] 시작점과 경유점 사이 최소 거리
cfg.sim.epochRange  = [180 240];  % 경로당 에포크 수
cfg.sim.smoothWin   = 15;         % 이동 평균 창 (0.1 m 간격 샘플 기준, 1.5 m)
cfg.sim.hallWobble  = 0.3;        % [m] 홀의 좌우 흔들림 표준편차
cfg.sim.rssScale    = 1.0;        % RSS 잡음 배율 (0.6 / 1.0 / 1.5)
cfg.sim.pdrScaleSd  = 0.05;       % 경로마다 걸음 폭 배율의 표준편차
cfg.sim.pdrNoise    = 0.05;       % 에포크마다 곱셈 잡음
cfg.sim.h0Deg       = 3;          % [도] 시작 방향 오차 표준편차
cfg.sim.driftDeg    = 0.6;        % [도/에포크] 방향 드리프트 (낮음 0.3 / 중간 0.6 / 높음 1.2)
end
