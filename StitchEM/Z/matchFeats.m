function sections = matchFeats(sections, params)
%MATCHFEATS Matches features in the sections data structure.
% Make sure the edgeFeats and the centerFeats substructures contain valid
% SURF points for every tile (call extractFeats before this function).

fprintf('------- Matching features...\n'); matchFeatsTime = tic;

% Match features in XY (within the same section)
for s = 1:length(sections)
    % Use section parameters since we're only working with one section
    prms = sections(s).params;
    
    for i = 1:length(sections(s).tiles)
        for e = 1:length(sections(s).tiles(i).edgeFeats)
            if sections(s).tiles(i).edgeFeats(e).seam.index > i && ...
                sections(s).tiles(i).edgeFeats(e).seam.index <= length(sections(s).tiles) && ...
                sections(s).tiles(i).edgeFeats(e).seam.index >= 1
                
                % Indexing information for the putatively overlapping tile
                i2 = sections(s).tiles(i).edgeFeats(e).seam.index;
                e2 = sections(s).tiles(i).edgeFeats(e).seam.oppEdge;
                
                % Nearest neighbor ratio matching
                indexPairs = matchFeatures(sections(s).tiles(i).edgeFeats(e).feats, ...
                    sections(s).tiles(i2).edgeFeats(e2).feats, ...
                    'MatchThreshold', prms.MatchThreshold, 'Metric', 'SSD', 'MaxRatio', prms.MaxRatio);
                
                % Get the coordinates for the matching points (we don't
                % really care about the SURF metadata)
                pts1 = sections(s).tiles(i).edgeFeats(e).points(indexPairs(:, 1), :).Location;
                pts2 = sections(s).tiles(i2).edgeFeats(e2).points(indexPairs(:, 2), :).Location;
                
                % Save matched point pairs back to data structure
                sections(s).tiles(i).pts{s, i2} = pts1;
                sections(s).tiles(i2).pts{s, i} = pts2;
            end
        end
    end
end


if length(sections) > 1
    % Match features in Z (between sections)
    for s1 = 1:length(sections) - 1
        
        % Get all the features in this section, keeping track of where they
        % came from so we can save them back after matching
        secFeats1 = []; secPts1 = []; secTileIdx1 = [];
        for i = 1:length(sections(s1).tiles)
            % TODO: Sample edges sparsely so matchFeatures doesn't blow up
            %edges = [edges; sections(s).tiles(i).edgeFeats];
            secFeats1 = [secFeats1; sections(s1).tiles(i).centerFeats.feats];
            secPts1 = [secPts1; sections(s1).tiles(i).centerFeats.points.Location];
            secTileIdx1 = [secTileIdx1; repmat(i, length(sections(s1).tiles(i).centerFeats.points), 1)];
        end
        
        % Do the same for the next section
        s2 = s1 + 1;
        secFeats2 = []; secPts2 = []; secTileIdx2 = [];
        for i = 1:length(sections(s2).tiles)
            % TODO: Sample edges sparsely so matchFeatures doesn't blow up
            %edges2 = [edges2; sections(s2).tiles(i).edgeFeats];
            secFeats2 = [secFeats2; sections(s2).tiles(i).centerFeats.feats];
            secPts2 = [secPts2 ; sections(s2).tiles(i).centerFeats.points.Location];
            secTileIdx2 = [secTileIdx2; repmat(i, length(sections(s2).tiles(i).centerFeats.points), 1)];
        end
        
        % Match them! (watch your RAM, max ~25k pts @ 8gb memory)
        indexPairs = matchFeatures(secFeats1, secFeats2, 'MatchThreshold', params.MatchThreshold, 'Metric', 'SSD', 'MaxRatio', params.MaxRatio);
        
        % Filter our matches to get rid of outliers (see findInliers)
        inliers = findInliers(secPts1(indexPairs(:, 1), :), secPts2(indexPairs(:, 2), :));
        pts1 = secPts1(indexPairs(inliers, 1), :);
        pts2 = secPts2(indexPairs(inliers, 2), :);
        tileIdx1 = secTileIdx1(indexPairs(inliers, 1), :);
        tileIdx2 = secTileIdx2(indexPairs(inliers, 2), :);
        
        % Save the matches back to the sections structure
        for i1 = 1:length(sections(s1).tiles); sections(s1).tiles(i1).pts(s2, :) = cell(1, length(sections(s2).tiles)); end
        for i2 = 1:length(sections(s2).tiles); sections(s2).tiles(i2).pts(s1, :) = cell(1, length(sections(s1).tiles)); end
        for m = 1:size(pts1, 1)
            sections(s1).tiles(tileIdx1(m)).pts{s2, tileIdx2(m)} = ...
                [sections(s1).tiles(tileIdx1(m)).pts{s2, tileIdx2(m)}; pts1(m, :)];
            sections(s2).tiles(tileIdx2(m)).pts{s1, tileIdx1(m)} = ...
                [sections(s2).tiles(tileIdx2(m)).pts{s1, tileIdx1(m)}; pts2(m, :)];
        end
    end
end

% TODO: Output some basic statistics about features found
fprintf('Done matching features. [%.2fs]\n\n', toc(matchFeatsTime));

end
