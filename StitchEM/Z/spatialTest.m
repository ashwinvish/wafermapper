sections = processFiles('E:\EMdata');

params.MetricThreshold = 10000;
params.SURFSize = 128;
params.MaxRatio = 0.6;
params.MatchThreshold = 1.0;
params.GaussianHSize = 9;
params.GaussianSigma = 0.5;
fprintf('SURF Metric Threshold = %d\n', params.MetricThreshold);
fprintf('SURF Size = %d\n', params.SURFSize);
fprintf('NNR Max Ratio = %.2f\n', params.MaxRatio);
fprintf('NNR Match Threshold = %.2f\n', params.MatchThreshold);
fprintf('Gaussian HSize = %d\n', params.GaussianHSize);
fprintf('Gaussian Sigma = %.2f\n\n', params.GaussianSigma);

% Get center features
secs = extractCenterFeats(sections, params, true);

% Simple spatial constraint: only look for matches in the tile above and below
for s1 = 1:(length(secs) - 1)
    s2 = s1 + 1;
    if s2 > 0 && s2 <= length(secs)
        % Clear out any pre-existing matches in our pts structure
        for i1 = 1:length(secs(s1).tiles); secs(s1).tiles(i1).pts(s2, :) = cell(1, length(secs(s2).tiles)); end
        for i2 = 1:length(secs(s2).tiles); secs(s2).tiles(i2).pts(s1, :) = cell(1, length(secs(s1).tiles)); end

        % Find matches in every tile
        for i = 1:min(length(secs(s1).tiles), length(secs(s2).tiles))
            feats1 = secs(s1).tiles(i).centerFeats.feats;
            feats2 = secs(s2).tiles(i).centerFeats.feats;
            points1 = secs(s1).tiles(i).centerFeats.points.Location;
            points2 = secs(s2).tiles(i).centerFeats.points.Location;

            [indexPairs, metric] = matchFeatures(feats1, feats2, 'MatchThreshold', params.MatchThreshold, 'Method', 'NearestNeighborRatio', 'Metric', 'SSD', 'MaxRatio', params.MaxRatio);

            pts1 = points1(indexPairs(:, 1), :);
            pts2 = points2(indexPairs(:, 2), :);

            % Save the matches back to the sections structure
            secs(s1).tiles(i).pts{s2, i} = pts1;
            secs(s2).tiles(i).pts{s1, i} = pts2;
        end
    end
end
%%
% Plot the matches
[X1, Y1] = getMatches(secs, 1, 2); showMatches(X1, Y1);

idx = findInliers(X1, Y1); X1i = X1(idx, :); Y1i = Y1(idx, :); showMatches(X1i, Y1i);

% Get some statistics
dists = sqrt(sum((X1-Y1).^2, 2));
fprintf('min = %f | mean = %f | max = %f | std = %f\n', min(dists), mean(dists), max(dists), std(dists))

% Plot the ECDF
%[f, x] = ecdf(dists); figure, plot(x, f, '-bx'); title('ECDF'), xlabel('Spatial distance between matches (px)')

% Plot the histogram
%figure,hist(sort(dists), 150), xlabel('Spatial distance between matches (px)')