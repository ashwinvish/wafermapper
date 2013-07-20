%% ---- Parameters
waferFolder = '/path/to/wafer/folder';

% SURF Feature extraction
params.MetricThreshold = 4500; % default = 1000
params.NumOctaves = 4; % default = 3
params.NumScaleLevels = 6; % default = 4
params.SURFSize = 64; % default = 64

% Feature matching (nearest neighbor symmetric)
params.MatchThreshold = 0.5; % default = 1.0
params.MaxRatio = 0.5; % default = 0.6

% Inlier detection (RANSAC)
params.NumTrials = 8000; % default = 500
params.Confidence = 99.0; % default = 99
params.DistanceThreshold = 0.1; % default = 0.01

params.lambda = 0.005;

%% ---- Process files
fprintf('------- Processing section files...\n'); processSecsTime = tic;
directory = dir(waferFolder);
folders = {directory([directory.isdir]).name}';
sectionIndices = ~cellfun(@isempty, regexp(folders, '_Sec[0-9]*_'));
sectionNames = folders(sectionIndices);
sectionFolders = strcat(waferFolder, filesep, sectionNames);
namedTokens = regexp(sectionFolders, '_Sec(?<sec>[0-9]*)_', 'names');
renderedSecs = {};
for n = 1:length(sectionFolders)
    curDir = dir(sectionFolders{n});
    files = {curDir(~[curDir.isdir]).name}';
    tileIndices = ~cellfun(@isempty, regexp(files, '^Tile_.*\.tif'));
    filenames = strcat(sectionFolders{n}, filesep, files(tileIndices));
    if renderedAlready
        renderedSecs{end + 1} = n;
    else
        % send that section for stitching then add it
    end
end

sections = struct();
for i = 1:length(renderedSecs)
    % Get image file metadata
    n = renderedSecs{i};
    sections(i).path = [sectionFolders{n} filesep sectionNames{n} '.tif'];
    sections(i).folder = sectionFolders{n};
    info = imfinfo(sections(i).path);
    sections(i).filesize = info(1).FileSize;
    sections(i).width = info(1).Width;
    sections(i).height = info(1).Height;
    sections(i).name = sectionNames{n};
    sections(i).secNum = str2num(namedTokens{n}.sec);
    
    % Initialize defaults
    sections(i).pts = cell(length(renderedSecs));
    sections(i).T = eye(3);
    sections(i).tform = affine2d(sections(i).T);
    sections(i).SURFFeats = [];
    sections(i).SURFPoints = [];
    sections(i).neighbors = [];
end
fprintf('Done processing section files. [%.2fs]\n\n', toc(processSecsTime));

%% ---- Find and match features
fprintf('------- Finding and matching features...\n'); matchFeatsTime = tic;
for i = 1:length(sections)
    fprintf('Getting features for section %d...', sections(i).secNum); tic;
    
    % Load image
    img = imread(sections(i).path);
    %img = img(1:round(sections(i).height * 0.25),
    %1:round(sections(i).width * 0.25));
    
    % Get local points
    surfFeats = detectSURFFeatures(img, 'MetricThreshold', params.MetricThreshold, 'NumOctaves', params.NumOctaves, 'NumScaleLevels', params.NumScaleLevels);
    
    % Extract features
    [sections(i).SURFFeats, sections(i).SURFPoints] = extractFeatures(img, surfFeats, 'SURFSize', params.SURFSize);
    img = []; % Clear image from memory since we don't need it anymore
    fprintf(' Done. Found %d features. [%.2fs]\n', length(sections(i).SURFFeats), toc);
    
    % Find matches
    for j = 1:length(sections)
        if ~isempty(sections(j).SURFFeats) && isempty(sections(i).pts{j}) && abs(sections(i).secNum - sections(j).secNum) == 1
            fprintf('Finding matches between sections %d <-> %d...', sections(i).secNum, sections(j).secNum); tic;
            
            % Find matching pairs
            indexPairs = matchFeatures(sections(i).SURFFeats, sections(j).SURFFeats, 'MatchThreshold', params.MatchThreshold, 'Metric', 'SSD', 'MaxRatio', params.MaxRatio);
            putativePtsI = sections(i).SURFPoints(indexPairs(:, 1));
            putativePtsJ = sections(j).SURFPoints(indexPairs(:, 2));
            
            % Refine matches
            [~, inliers] = estimateFundamentalMatrix(putativePtsI, putativePtsJ, 'Method', 'RANSAC', 'NumTrials', params.NumTrials, 'Confidence', params.Confidence, 'DistanceThreshold', params.DistanceThreshold);
            
            % Save the points to their respective structures
            sections(i).matchedSURFPts{j} = putativePtsI(inliers, :);
            sections(j).matchedSURFPts{i} = putativePtsJ(inliers, :);
            sections(i).pts{j} = double(putativePtsI(inliers, :).Location);
            sections(j).pts{i} = double(putativePtsJ(inliers, :).Location);
            
            % Keep track of neighboring tiles
            sections(i).neighbors = [sections(i).neighbors j];
            sections(j).neighbors = [sections(j).neighbors i];
            
            fprintf(' Done. Found %d pairs. [%.2fs]\n', size(sections(i).pts{j}, 1), toc);
            
            if size(indexPairs, 1) < 6
                error('Error: Too few point correspondencies found. Consider raising the matching threshold or tweaking the feature extraction parameters to get better matches.')
            end
        end
    end
end
fprintf('Done finding and matching features. [%.2fs]\n\n', toc(matchFeatsTime));
%% ---- Calculate transforms
sections = tikhonovOptimization(params, sections);

%showMatchedFeatures(imread(sections(1).path), imread(sections(2).path),
%sections(1).matchedSURFPts{2}, sections(2).matchedSURFPts{1})

%% ---- Transform and render
for i = 1:length(sections)
    fprintf('Transforming section %d...', sections(i).secNum); tic;
    alignedSection = imwarp(imread(sections(i).path), sections(i).tform);
    fprintf(' Done. [%.2fs]\n', toc);
    
    filename = [waferFolder filesep sections(i).name '.tif'];
    fprintf(['Writing to file ' strrep(filename, '\', '\\') '...']); tic;
    imwrite(alignedSection, filename);
    fprintf(' Done. [%.2fs]\n\', toc);
end