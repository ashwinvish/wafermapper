function params = defaultParameters(tileFolder)

% Feature matching
params.MaxRatio = 0.6; % default = 0.6

% Inlier detection (RANSAC)
params.NumTrials = 500; % default = 500
params.Confidence = 99.0; % default = 99
params.DistanceThreshold = 0.01; % default = 0.01

% Tikhonov
params.weight = 1.0; % for intrasection fitting (XY)

%% ---- File Processing (processFiles.m)

% This is the folder that the tile images reside in. They must follow this
% naming format:
% 'Tile_r##-c##_{...}.tif' where the ## correspond to the row and column
%   of the tile.
% Notes: - Do not include a trailing slash.
%        - Both Unix and Windows paths are supported ('/' or '\').
if nargin < 1
    %params.tileFolder = '/home/talmo/EMdata/S2-W002_Sec101_Montage';
    params.tileFolder = 'E:\Documents\Dropbox\MIT\SeungLab\Wafer007\2000px';
else
    params.tileFolder = tileFolder;
end
% This will only load this number of tiles. This is primarily for
% debugging, i.e.: to stitch only the first two tiles, set this value to 2.
% Leaving this at 0 will load every tile.
% Default: 0 || Recommended: 0
params.truncateFiles = 0;

%% ---- General Parameters
params.baseName = regexp(params.tileFolder, '[^/\\]+[/\\]?$', 'match'); params.baseName = params.baseName{1};

% Comment this line out or set it to '' to disable output file logging.
params.LogFile = [params.baseName '.log'];

%% ---- Feature Matching (matchTileFeatures.m)

% Thi specifies the threshold for blob detection by SURF. A higher value
% means stronger, but less features will be returned.
% See: http://www.mathworks.com/help/vision/ref/detectsurffeatures.html
% Values [1-Inf] || Default: 1000 || Recommended: 4000-5000
params.MetricThreshold = 2000;

% SURF will find features at different scales. At higher octaves, it will
% subsample the image data and find larger-sized blobs. Increasing this
% value makes it possible to find larger features.
% See: http://www.mathworks.com/help/vision/ref/detectsurffeatures.html
% Values: integers >= 1 || Default: 3 || Recommended: 1-4
params.NumOctaves = 3;

% Increasing this value will lead to detection of features at smaller scale
% increments.
% See: http://www.mathworks.com/help/vision/ref/detectsurffeatures.html
% Values: integers >= 3 || Default: 4 || Recommended: 3-6
params.NumScaleLevels = 4;

% The higher value leads to greater accuracy but slower feature matching.
% See: http://www.mathworks.com/help/vision/ref/extractfeatures.html
% Values: 64 or 128 || Default: 64 || Recommended: 64
params.SURFSize = 64;

% This is a parameter passed to MATLAB's matchFeatures function.
% Lower is more strict and therefore will results in less matches. Higher
% values results in more matches, but potentially more false positives that
% make it harder to fit a transformation.
% See: http://www.mathworks.com/help/vision/ref/matchfeatures.html
% Values: [0-1.0] || Default: 0.2 || Recommended: 0.15-0.25
params.MatchThreshold = 0.18475;


% The amount of expected overlap between tiles. If the tiles are imaged
% with a 10% overlap, set this value to 0.1.
% Smaller overlaps results in more true matches and much faster runtimes
% since the program will only look for matches in the overlap region.
% Naive feature matching where the features may be anywhere in the tile is
% the same as setting this value to 1.0 (the whole tile is searched).
% Values: [0-1.0] || Default: 0.1
params.overlapRatio = 0.1;


% If true, will find SURF features even if there already exists some for a
% given pair of tiles.
% This is a way to disable a simple optimization wherein we skip finding
% matches for tiles j <-> i if we already have matches for i <-> j.
% Default: false || Recommended: false
params.overwriteSURF = false;


%% ---- Tikhonov Optimization (tikhonovOptimization.m)

% The weight of the constraint term to prevent singular solutions.
% Values: [0-inf] || Default: 0.005
params.lambda = 0.005;


%% ---- Transform Optimization (optimizeTransform.m)

% This is the threshold of change in pixel error per tile. Every subsequent
% optimization step decreases the pixel error, but by a smaller amount each
% time. To determine convergence, the program will calculate this change in
% error and once it is decreasing at a sufficiently small rate, it will
% stop. Smaller values are preferred but will take more time.
% Note that every image will not converge at a predictable amount of
% iterations for a given threshold, so this should be one of the main
% parameters you might need to tweak.
% Set this to 0 to threshold only by iterations (see below).
% Values: (0-inf] || Default: 0.0001 || Recommended: 0.00001-0.0001
params.deltaThreshold = 0.00001;


% Similar to deltaThreshold above, the program also ensures that it will
% run for at least this many iterations. The more iterations, the better
% the fit and lower the error. Experimentally, good fits appear to be found
% after at least 20000 iterations for 8K x 8K x 16 tile sections.
% Values: [0, inf] || Default: 20000 || Recommended: 20000-50000
params.minIterations = 1000;


% This determines after how many iterations the program should print out
% information. A value of 1 means that it will print out metrics after
% every iteration (not recommended -- several hundred iterations can be 
% computed in a second).
% Values: [1, inf] || Default: 1000 || Recommended: 100-1000
params.iterVerbosity = 100;

%% ---- Rendering (renderTiles.m)

% This is a flag to determine whether the section should be rendered. If
% set to false, the tiles will only be transformed but not rendered
% together into a single image.
% Default: true
params.render = true;


% Set this to true if you want to save the transformed images in memory
% after done rendering (neccessary if you want to save the individual
% transformed tiles separately)
params.saveTImgs = false;


% This is the name used for the logfile and the final rendered file. Set it
% here manually if you want to use a different naming convention. By
% default it will use the folder name that the tiles reside in.
params.montageFilename = strcat(params.baseName, '.tif');

end