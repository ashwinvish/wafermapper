function sections = extractFeats(sections, params)
%EXTRACTFEATS Extract SURF features from all sections.
% The complexity in this routine comes from the fact that we want to use
% different parameters for finding features in the edges/seams of the tiles
% as opposed to the center of the tile.
%
% The main reason for this is because we will only use the features found
% in the center of the tiles for Z alignment (i.e., between different
% sections), which is not only weighed differently but matched at different
% thresholds as well.
%
% After this function is called, the points detected can be accessed in the
% sections data structure as such:
%     sections(s).tiles(i).edgeFeats(n)
% or: sections(s).tiles(i).centerFeats
% 
% The data structures will look like:
%  >> sections(1).tiles(1).centerFeats
%         feats: [3724x64 single]
%        points: [3724x1 SURFPoints]
%        bounds: [1x1 struct]
% 
% Where the bounds structure will look like:
%  >> sections(1).tiles(1).centerFeats.bounds
%      startRow: 201
%        endRow: 1799
%      startCol: 201
%        endCol: 1799
%
% The edgeFeats structure contains a seam structure instead of bounds:
%  >> sections(1).tiles(1).edgeFeats(1).seam
%        index: 5
%      oppEdge: 2
%     startRow: 1800
%       endRow: 2000
%     startCol: 1
%       endCol: 2000
%      dirName: 'bottom'
% Where the index field refers to which tile it probably overlaps with
% (i.e. in the above output, the points in this structure likely overlap
% with tile 5 (the one in the row immediately below). NOTE: Do not rely on
% this index for matching; it may contain invalid index values.
%
% Notes on the parallelization:
% The MATLAB SURF functions are already decently parallelized so the gains
% here are not necessarily insane. On an Intel i7-3770K @ 3.5GHz (8 cores):
%
% [2 sections with 16 tiles/section, images downsamples to 2000x2000px]
% without parallelization:
% >> tic; extractFeats(sections, params); toc
%   Elapsed time is 21.096360 seconds.
%
% with parallelization:
% >> tic; extractFeats(sections, params); toc
%   Elapsed time is 11.876666 seconds.
%
% Since the parallelization is done on the tiles, the gain scales up as we
% have more cores, up to the number of tiles in a given section.

fprintf('------- Extracting features...\n'); extractFeatsTime = tic;

for s = 1:length(sections)
    % Splice out data for parallelization
    cols = sections(s).cols;
    sectionTiles = sections(s).tiles;
    sectionParams = sections(s).params;
    
    % Parallel magic, go!
    parfor i = 1:length(sections(s).tiles)
        % Load the tile image from disk
        tileImg = imread(sectionTiles(i).filename);
        
        % Use the parameters for specific section
        prms = sectionParams;
        
        % Get the relevant indexing information for the seam regions
        seams = findSeams(sectionTiles(i), prms.overlapRatio, cols);
        
        % Extract features from edges (seams)
        edgeFeats = [];
        for seam = seams
            % Get relevant image data
            img = tileImg(seam.startRow:seam.endRow, seam.startCol:seam.endCol);
            
            % Detect SURF blob features (interest points)
            SURFPoints = detectSURFFeatures(img, 'MetricThreshold', prms.MetricThreshold, 'NumOctaves', prms.NumOctaves, 'NumScaleLevels', prms.NumScaleLevels);
            
            % Adjust for seam offset
            SURFPoints(:).Location = SURFPoints(:).Location + ...
                [repmat(seam.startCol - 1, length(SURFPoints), 1) ...
                repmat(seam.startRow - 1, length(SURFPoints), 1)];
            
            % Calculate descriptors and get valid points
            [SURFFeats, validSURFPoints] = extractFeatures(tileImg, SURFPoints, 'SURFSize', prms.SURFSize);
            
            % Adjust for global offset of the tile within the section
            validSURFPoints(:).Location = validSURFPoints(:).Location + ...
                [repmat(sectionTiles(i).offsetX, length(validSURFPoints), 1) ...
                repmat(sectionTiles(i).offsetY, length(validSURFPoints), 1)];
            
            % Save the points and coordinate data
            edgeFeats = [edgeFeats; struct('feats', SURFFeats, 'points', validSURFPoints, 'seam', seam)];
        end
        sectionTiles(i).edgeFeats = edgeFeats;
        
        
        % Use the the global parameters (relevant to Z alignment)
        prms = params;
        
        % Figure out where the center of the tile is
        startRow = seams(2).endRow + 1; endRow = seams(1).startRow - 1;
        startCol = seams(4).endCol + 1; endCol = seams(3).startCol - 1;
        
        % SURF extraction for the center of the tile
        img = tileImg(startRow:endRow, startCol:endCol);
        SURFPoints = detectSURFFeatures(img, 'MetricThreshold', prms.MetricThreshold, 'NumOctaves', prms.NumOctaves, 'NumScaleLevels', prms.NumScaleLevels);
        SURFPoints(:).Location = SURFPoints(:).Location + ...
            [repmat(startCol - 1, length(SURFPoints), 1) repmat(startRow - 1, length(SURFPoints), 1)];
        [SURFFeats, validSURFPoints] = extractFeatures(tileImg, SURFPoints, 'SURFSize', prms.SURFSize);
        validSURFPoints(:).Location = validSURFPoints(:).Location + ...
            [repmat(sectionTiles(i).offsetX, length(validSURFPoints), 1) ...
            repmat(sectionTiles(i).offsetY, length(validSURFPoints), 1)];
        sectionTiles(i).centerFeats = struct('feats', SURFFeats, 'points', validSURFPoints, ...
            'bounds', struct('startRow', startRow, 'endRow', endRow, 'startCol', startCol, 'endCol', endCol));
    end
    
    % Save results of parallel job back to data structure
    sections(s).tiles = sectionTiles;
end

% TODO: Output some basic statistics about features found
fprintf('Done extracting features. [%.2fs]\n\n', toc(extractFeatsTime));

end

function seams = findSeams(tile, overlapRatio, cols)
    % Some aliases for readability
    oR = overlapRatio;
    w = tile.width;
    h = tile.height;
    r = tile.row;
    c = tile.col;

    % Parameters for calculating putative seams
    % Seams:     bottom               top                 right                   left
    indices =   {r * cols + c         (r - 2) * cols + c  (r - 1) * cols + c + 1  (r - 1) * cols + c - 1 };
    oppEdges =  {2                    1                   4                       3                      };
    startRows = {round(h * (1 - oR))  1                   1                       1                      };
    endRows =   {h                    round(h * oR)       h                       h                      };
    startCols = {1                    1                   round(w * (1 - oR))     1                      };
    endCols =   {w                    w                   w                       round(w * oR)          };
    dirNames =  {'bottom'             'top'               'right'                 'left'                 };
    
    % Return the calculations
    seams = struct('index', indices, 'oppEdge', oppEdges, 'startRow', startRows, 'endRow', endRows, 'startCol', startCols, 'endCol', endCols, 'dirName', dirNames);
end