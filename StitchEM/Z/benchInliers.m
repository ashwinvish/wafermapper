% Benchmarking for inlier detection

s1 = 1;

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

indexPairs = matchFeatures(secFeats1, secFeats2, 'MatchThreshold', params.MatchThreshold, 'Metric', 'SSD', 'MaxRatio', 0.9);


dists = sqrt(sum((secPts1(indexPairs(:, 1), :)-secPts2(indexPairs(:, 2), :)).^2, 2));
[fX, x] = ecdf(dists);
figure, plot(x, fX, '-x')

naiveTime = tic; trials = 10000;
for i = 1:trials; inliers = findInliers(secPts1(indexPairs(:, 1), :), secPts2(indexPairs(:, 2), :)); end
fprintf('Naive method: %fs avg | inliers: %d/%d\n', toc(naiveTime) / trials, size(inliers, 1), size(indexPairs, 1))

pts1 = secPts1(indexPairs(inliers, 1), :);
pts2 = secPts2(indexPairs(inliers, 2), :);
showMatches(pts1, pts2)
max(sqrt(sum((pts1-pts2).^2, 2)))
median(sqrt(sum((pts1-pts2).^2, 2)))
min(sqrt(sum((pts1-pts2).^2, 2)))
std(sqrt(sum((pts1-pts2).^2, 2)))

ransacTime = tic;
[~, inliers] = estimateFundamentalMatrix(secPts1(indexPairs(:, 1), :), secPts2(indexPairs(:, 2), :), 'Method', 'RANSAC', 'NumTrials', 8000, 'Confidence', 99.0, 'DistanceThreshold', 0.1);
fprintf('RANSAC: %fs | inliers: %d/%d\n', toc(ransacTime), sum(inliers), size(indexPairs, 1))

pts1 = secPts1(indexPairs(inliers, 1), :);
pts2 = secPts2(indexPairs(inliers, 2), :);
showMatches(pts1, pts2)
max(sqrt(sum((pts1-pts2).^2, 2)))
median(sqrt(sum((pts1-pts2).^2, 2)))
min(sqrt(sum((pts1-pts2).^2, 2)))
std(sqrt(sum((pts1-pts2).^2, 2)))