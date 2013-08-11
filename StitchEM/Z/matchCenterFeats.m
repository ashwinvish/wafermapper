function [ secs, metrics ] = matchCenterFeats( secs, params, distInliers, distCol )
%MATCHCENTERFEATS Used with normTest.

metrics = cell(1:length(secs) - 1);
for s1 = 1:length(secs) - 1
    % Get all the features in this section, keeping track of where they
    % came from so we can save them back after matching
    secFeats1 = []; secPts1 = []; secTileIdx1 = [];
    for i = 1:length(secs(s1).tiles)
        % TODO: Sample edges sparsely so matchFeatures doesn't blow up
        %edges = [edges; sections(s).tiles(i).edgeFeats];
        secFeats1 = [secFeats1; secs(s1).tiles(i).centerFeats.feats];
        secPts1 = [secPts1; secs(s1).tiles(i).centerFeats.points.Location];
        secTileIdx1 = [secTileIdx1; repmat(i, length(secs(s1).tiles(i).centerFeats.points), 1)];
    end
    secFeats1 = secFeats1(distInliers{s1}(:, distCol), :);
    secPts1 = secPts1(distInliers{s1}(:, distCol), :);
    secTileIdx1 = secTileIdx1(distInliers{s1}(:, distCol), :);
    
    % Do the same for the next section
    s2 = s1 + 1;
    secFeats2 = []; secPts2 = []; secTileIdx2 = [];
    for i = 1:length(secs(s2).tiles)
        % TODO: Sample edges sparsely so matchFeatures doesn't blow up
        %edges2 = [edges2; sections(s2).tiles(i).edgeFeats];
        secFeats2 = [secFeats2; secs(s2).tiles(i).centerFeats.feats];
        secPts2 = [secPts2 ; secs(s2).tiles(i).centerFeats.points.Location];
        secTileIdx2 = [secTileIdx2; repmat(i, length(secs(s2).tiles(i).centerFeats.points), 1)];
    end
    secFeats2 = secFeats2(distInliers{s2}(:, distCol), :);
    secPts2 = secPts2(distInliers{s2}(:, distCol), :);
    secTileIdx2 = secTileIdx2(distInliers{s2}(:, distCol), :);
    
    % Match them! (watch your RAM, max ~25k pts @ 8gb memory)
    [indexPairs, metrics{s1}] = matchFeatures(secFeats1, secFeats2, 'MatchThreshold', params.MatchThreshold, 'Method', 'NearestNeighborRatio', 'Metric', 'SSD', 'MaxRatio', params.MaxRatio);

    pts1 = secPts1(indexPairs(:, 1), :);
    pts2 = secPts2(indexPairs(:, 2), :);
    tileIdx1 = secTileIdx1(indexPairs(:, 1), :);
	tileIdx2 = secTileIdx2(indexPairs(:, 2), :);
    % Filter our matches to get rid of outliers (see findInliers)
%     inliers = findInliers(secPts1(indexPairs(:, 1), :), secPts2(indexPairs(:, 2), :));
%     pts1 = secPts1(indexPairs(inliers, 1), :);
%     pts2 = secPts2(indexPairs(inliers, 2), :);
%     tileIdx1 = secTileIdx1(indexPairs(inliers, 1), :);
%     tileIdx2 = secTileIdx2(indexPairs(inliers, 2), :);

    % Save the matches back to the sections structure
    for i1 = 1:length(secs(s1).tiles); secs(s1).tiles(i1).pts(s2, :) = cell(1, length(secs(s2).tiles)); end
    for i2 = 1:length(secs(s2).tiles); secs(s2).tiles(i2).pts(s1, :) = cell(1, length(secs(s1).tiles)); end
    for m = 1:size(pts1, 1)
        secs(s1).tiles(tileIdx1(m)).pts{s2, tileIdx2(m)} = ...
            [secs(s1).tiles(tileIdx1(m)).pts{s2, tileIdx2(m)}; pts1(m, :)];
        secs(s2).tiles(tileIdx2(m)).pts{s1, tileIdx1(m)} = ...
            [secs(s2).tiles(tileIdx2(m)).pts{s1, tileIdx1(m)}; pts2(m, :)];
    end
end

end

