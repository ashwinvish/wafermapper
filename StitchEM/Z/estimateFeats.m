function estimateFeats(sections, params)
%ESTIMATEFEATS Outputs the number of features found per tile with a given
%parameter set.

for s = 1:length(sections)
    fprintf('Extracting features from section %d\n-----------------\n', s)
    % Splice out data
    cols = sections(s).cols;
    sectionTiles = sections(s).tiles;
    sectionParams = sections(s).params;
    
    for i = 1:length(sections(s).tiles)
        fprintf('Tile %d | ', i)
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
        numEdgeFeats = length(vertcat(edgeFeats.points));
        fprintf('Edge features: %d | ', numEdgeFeats)
        
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
        numCenterFeats = length(vertcat(sectionTiles(i).centerFeats.points));
        fprintf('Center features: %d | ', numCenterFeats)
        fprintf('Total features: %d\n', numEdgeFeats + numCenterFeats)
    end
    
end

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
