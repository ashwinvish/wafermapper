%% ---- Parameters
waferFolder = '/path/to/wafer/folder';

% SURF Feature extraction
params.MetricThreshold = 4500; % default = 1000
params.NumOctaves = 4; % default = 3
params.NumScaleLevels = 6; % default = 4
params.SURFSize = 64; % default = 64

% Feature matching (nearest neighbor symmetric)
params.MatchThreshold = 1.0; % default = 1.0
params.MaxRatio = 1.0; % default = 0.6

% Inlier detection (RANSAC)
params.NumTrials = 8000; % default = 500
params.Confidence = 99.0; % default = 99
params.DistanceThreshold = 0.01; % default = 0.01

params.lambda = 0.005;

%% ---- Process files
fprintf('------- Processing files and collecting metadata...\n'); processSecsTime = tic;

% Get filesystem information
directory = dir(waferFolder);
folders = {directory([directory.isdir]).name}';
sectionIndices = ~cellfun(@isempty, regexp(folders, '_Sec[0-9]*_'));
sectionNames = folders(sectionIndices);
sectionFolders = strcat(waferFolder, filesep, sectionNames);
namedTokens = regexp(sectionFolders, '_Sec(?<sec>[0-9]*)_', 'names');

% Create data structure that will contain alignment and meta- data
sections = struct();
for i = 1:length(sectionFolders)
    % Section-specific parameters
    sections(i).params = defaultParameters(sectionFolders{i});
    sections(i).params.montageFilename = [waferFolder filesep sections(i).params.baseName '.tif'];
    
    % Create tiles substructure
    sections(i).tiles = processTiles(sections(i).params, length(sectionFolders));
    
    % Section metadata
    sections(i).path = sectionFolders{i};
    sections(i).name = sectionNames{i};
    sections(i).secNum = str2num(namedTokens{i}.sec); %#ok<ST2NM>
    sections(i).numTiles = length(sections(i).tiles);
    sections(i).rows = max([sections(i).tiles(:).row]);
    sections(i).cols = max([sections(i).tiles(:).col]);
end

fprintf('Done processing all sections. [%.2fs]\n\n', toc(processSecsTime));

%% ---- Extract features
fprintf('------- Extracting features...\n'); extractFeatsTime = tic;

for s = 1:length(sections)
    fprintf('Finding features in section %d...', sections(s).secNum); tic;
    
    % Slice elements of sections data structure for parallelization
    sectionTiles = sections(s).tiles;
    sectionParams = sections(s).params;
    rows = sections(s).rows;
    cols = sections(s).cols;
    numTiles = sections(s).numTiles;
    
    % Figure out seams and extract features
    parfor i = 1:numTiles
        oR = sectionParams.overlapRatio;
        w = sectionTiles(i).width;
        h = sectionTiles(i).height;
        r = sectionTiles(i).row;
        c = sectionTiles(i).col;
        siz = [rows, cols];
        
        % Parameters for calculating putative seams
        % Seams:     top                 right                   bottom               left
        indices =   [(r - 2) * cols + c  (r - 1) * cols + c + 1  r * cols + c         (r - 1) * cols + c - 1 ];
        startRows = [1                   1                       round(h * (1 - oR))  1                      ];
        endRows =   [round(h * oR)       h                       h                    h                      ];
        startCols = [1                   round(w * (1 - oR))     1                    1                      ];
        endCols =   [w                   w                       w                    round(w * oR)          ];

        for seam = [indices; startRows; endRows; startCols; endCols]
            j = seam(1); [jC, jR] = ind2sub([rows, cols], j);
            if j > 0 && j <= numTiles && (r == jR || c == jC)
                startRow = seam(2); endRow = seam(3); startCol = seam(4); endCol = seam(5);
                
                % Load image
                seamImg = imread(sectionTiles(i).filename);
                
                % Extract image data from the seam region
                seamImg = seamImg(startRow:endRow, startCol:endCol);
                
                % Detect and extract features
                surfFeats = detectSURFFeatures(seamImg, 'MetricThreshold', sectionParams.MetricThreshold, 'NumOctaves', sectionParams.NumOctaves, 'NumScaleLevels', sectionParams.NumScaleLevels);
                [sectionTiles(i).SURFFeats{j}, sectionTiles(i).SURFPoints{j}] = extractFeatures(seamImg, surfFeats, 'SURFSize', sectionParams.SURFSize);
                
                % Save seam parameters
                sectionTiles(i).seams{j} = struct('startRow', startRow, 'endRow', endRow, 'startCol', startCol, 'endCol', endCol);
            end
        end
    end
    
    % Save data back into sections structure
    sections(s).tiles = sectionTiles;
    
    fprintf(' Done. [%.2fs]\n', toc);
end

fprintf('Done extracting features. [%.2fs]\n\n', toc(extractFeatsTime));

%% ---- Match features
fprintf('------- Matching features...\n'); matchFeatsTime = tic;

% Construct seams structure that can be spliced and looped
seams = {};
for s = 1:length(sections)
    for i = 1:length(sections(s).tiles)
        for j = i:length(sections(s).tiles(i).seams)
            if ~isempty(sections(s).tiles(i).seams{j})
                % XY (same section seam)
                seam = struct('sec', {s, s}, 'tile1', {i, j}, 'tile2', {j, i}, ...
                    'SURFFeats', {sections(s).tiles(i).SURFFeats{j}, sections(s).tiles(j).SURFFeats{i}}, ...
                    'SURFPoints', {sections(s).tiles(i).SURFPoints{j}, sections(s).tiles(j).SURFPoints{i}}, ...
                    'inliers', []);
                seams = [seams {seam}];
                
                % Z (seam with sections above or below)
                for sec = 1:length(sections)
                    if abs(sec - s) == 1
                        % sec(a).tile(i) <-> sec(b).tile(i)
                        seam = struct('sec', {s, sec}, 'tile1', {i, j}, 'tile2', {i, j}, ...
                            'SURFFeats', {sections(s).tiles(i).SURFFeats{j}, sections(sec).tiles(i).SURFFeats{j}}, ...
                            'SURFPoints', {sections(s).tiles(i).SURFPoints{j}, sections(sec).tiles(i).SURFPoints{j}}, ...
                            'inliers', []);
                        seams = [seams {seam}];
                        
                        % sec(a).tile(i) <-> sec(b).tile(j)
                        seam = struct('sec', {s, sec}, 'tile1', {i, j}, 'tile2', {j, i}, ...
                            'SURFFeats', {sections(s).tiles(i).SURFFeats{j}, sections(sec).tiles(j).SURFFeats{i}}, ...
                            'SURFPoints', {sections(s).tiles(i).SURFPoints{j}, sections(sec).tiles(j).SURFPoints{i}}, ...
                            'inliers', []);
                        seams = [seams {seam}];
                        
                        % sec(a).tile(j) <-> sec(b).tile(j)
                        seam = struct('sec', {s, sec}, 'tile1', {j, i}, 'tile2', {j, i}, ...
                            'SURFFeats', {sections(s).tiles(j).SURFFeats{i}, sections(sec).tiles(j).SURFFeats{i}}, ...
                            'SURFPoints', {sections(s).tiles(j).SURFPoints{i}, sections(sec).tiles(j).SURFPoints{i}}, ...
                            'inliers', []);
                        seams = [seams {seam}];
                    end
                end
            end
        end
    end
end

% Find matches and inliers
parfor n = 1:length(seams)
%     params.MatchThreshold
%     params.MaxRatio
%     params.NumTrials
%     params.Confidence
%     params.DistanceThreshold
    indexPairs = matchFeatures(seams{n}(1).SURFFeats, seams{n}(2).SURFFeats, 'MatchThreshold', params.MatchThreshold, 'Metric', 'SSD', 'MaxRatio', params.MaxRatio);
    putativePtsI = seams{n}(1).SURFPoints(indexPairs(:, 1));
    putativePtsJ = seams{n}(2).SURFPoints(indexPairs(:, 2));
    fprintf('[seam %d] s%d t%d <-> s%d t%d: %d matches', n, seams{n}(1).sec, seams{n}(1).tile1, seams{n}(2).sec, seams{n}(2).tile1, size(putativePtsI, 1))
    [~, inliers] = estimateFundamentalMatrix(putativePtsI, putativePtsJ, 'Method', 'RANSAC', 'NumTrials', params.NumTrials, 'Confidence', params.Confidence, 'DistanceThreshold', params.DistanceThreshold);
    seams{n}(1).inliers = indexPairs(inliers, 1); seams{n}(2).inliers = indexPairs(inliers, 2);
    fprintf(', %d inliers\n', size(seams{n}(1).inliers, 1))
end
fprintf('Done matching features. [%.2fs]\n\n', toc(matchFeatsTime));

%% ---- Calculate transforms
sections = tikhonovStackOptimization(params, sections);

%showMatchedFeatures(imread(sections(1).path), imread(sections(2).path),
%sections(1).matchedSURFPts{2}, sections(2).matchedSURFPts{1})

% %% ---- Transform and render
% for i = 1:length(sections)
%     fprintf('Transforming section %d...', sections(i).secNum); tic;
%     alignedSection = imwarp(imread(sections(i).path), sections(i).tform);
%     fprintf(' Done. [%.2fs]\n', toc);
%     
%     filename = [waferFolder filesep sections(i).name '.tif'];
%     fprintf(['Writing to file ' strrep(filename, '\', '\\') '...']); tic;
%     imwrite(alignedSection, filename);
%     fprintf(' Done. [%.2fs]\n\', toc);
% end