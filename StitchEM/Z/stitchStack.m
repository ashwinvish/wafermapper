%% ---- Parameters
%params.waferFolder = '/home/talmo/EMdata';
params.waferFolder = 'E:\EMdata\2000px';
params.dontRenderSection = true;
params.exportForTrakEM = true;

% SURF Feature extraction
params.MetricThreshold = 5000; % default = 1000
params.NumOctaves = 3; % default = 3
params.NumScaleLevels = 4; % default = 4
params.SURFSize = 64; % default = 64

% Feature matching (nearest neighbor ratio) matchFeatures
params.MatchThreshold = 0.2; % default = 1.0
params.MaxRatio = 0.6; % default = 0.6

% Inlier detection (RANSAC)
params.NumTrials = 8000; % default = 500
params.Confidence = 99.0; % default = 99
params.DistanceThreshold = 0.1; % default = 0.01

% Tikhonov
params.lambda = 0.005;
params.weight = 0.1; % for intersection (Z) fitting

%% ---- Process files
sections = processFiles(params.waferFolder);

%% ---- Extract features
sections = extractFeats(sections, params);

%% ---- Match features
sections = matchFeats(sections, params);

%% ---- Calculate transforms
sections = tikOptim(sections, params);

% For debugging:
%showMatchedFeatures(imread(sections(1).tiles(1).filename), imread(sections(2).tiles(1).filename), seams{2}(1).localPts, seams{2}(2).localPts, 'Method', 'falsecolor')
%lambdaCurveStack(sections, seams);

%% ---- Transform and render
renderSections(sections, params);
