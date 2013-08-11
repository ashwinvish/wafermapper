params.MetricThreshold = 15000;
fprintf('SURF Metric Threshold = %d\n\n', params.MetricThreshold);

%% 1. Does SURF detect different features for normalized images?
%secs = extractCenterFeats(sections, params, false);
%normSecs = extractCenterFeats(sections, params, true);

% Merge the feature vectors
secsFeats = cell(length(secs)); for s=1:length(secs); for i=1:length(secs(s).tiles); secsFeats{s}=vertcat(secsFeats{s}, secs(s).tiles(i).centerFeats.feats); end; end
normSecsFeats = cell(length(normSecs)); for s=1:length(normSecs); for i=1:length(normSecs(s).tiles); normSecsFeats{s}=vertcat(normSecsFeats{s}, normSecs(s).tiles(i).centerFeats.feats); end; end

% Merge the point locations
secsPoints = cell(length(secs)); for s=1:length(secs); for i=1:length(secs(s).tiles); secsPoints{s}=vertcat(secsPoints{s}, secs(s).tiles(i).centerFeats.points.Location); end; end
normSecsPoints = cell(length(normSecs)); for s=1:length(normSecs); for i=1:length(normSecs(s).tiles); normSecsPoints{s}=vertcat(normSecsPoints{s}, normSecs(s).tiles(i).centerFeats.points.Location); end; end

% Find matches between original and normalized sections
matches = {}; metric = {};
for s = 1:min(length(secs), length(normSecs))
    tic;fprintf('Finding matches in section %d... ', s); [matches{s}, metric{s}] = matchFeatures(secsFeats{s}, normSecsFeats{s}, 'Method', 'NearestNeighborRatio'); fprintf('Done. [%.2fs]\n', toc)
end

% Find matches based on distance instead of feature descriptor
distMatches = {}; distMetric = {}; dists = {}; distInliers = {};
for s = 1:min(length(secs), length(normSecs))
    tic;fprintf('Finding distance matches in section %d... ', s); [distMatches{s}, distMetric{s}] = matchFeatures(secsPoints{s}, normSecsPoints{s}, 'Method', 'NearestNeighborRatio', 'MaxRatio', 1.0); fprintf('Done. [%.2fs]\n', toc)
    dists{s} = sqrt(sum((secsPoints{s}(distMatches{s}(:, 1), :) - normSecsPoints{s}(distMatches{s}(:, 2), :)).^2, 2));
    distInliers{s} = dists{s} < 10;
    dists{s} = dists{s}(dists{s} < 10);
    distMatches{s} = distMatches{s}(distInliers{s}, :);
end

% Output results
fprintf('Center feats\n===========\n')
for s=1:min(length(secs), length(normSecs))
    fprintf('Section %d: Original = %d | Normalized = %d | Matches = %d (metric = %f) | Dist Matches = %d (total dist = %f)\n', s, size(secsFeats{s}, 1), size(normSecsFeats{s}, 1), size(matches{s}, 1), sum(metric{s}), size(distMatches{s}, 1), sum(dists{s}))
end


%% 2. Does this provide a better match between sections?
params.MaxRatio = 0.8;
params.MatchThreshold = 1.0;

fprintf('NNR MaxRatio = %f\nNNR MatchThreshold = %f\n\n', params.MaxRatio, params.MatchThreshold)

fprintf('Finding matches in original sections... '); tic;
[secs, metrics] = matchCenterFeats(secs, params, distMatches, 1);
fprintf('Found %d matches with error of %f (avg/section). [%.2fs]\n', mean(cellfun(@length, metrics)), mean(cellfun(@sum, metrics)), toc)

fprintf('Finding matches in normalized sections... '); tic;
[normSecs, normMetrics] = matchCenterFeats(normSecs, params, distMatches, 2);
fprintf('Found %d matches with error of %f (avg/section). [%.2fs]\n\n', mean(cellfun(@length, normMetrics)), mean(cellfun(@sum, normMetrics)), toc)

% Plot the matches
[X1, Y1] = getMatches(secs, 1, 2); showMatches(X1, Y1); title('Original Sections')
[X2, Y2] = getMatches(normSecs, 1, 2); showMatches(X2, Y2); title('Normalized Sections')

% Get some statistics
dists = sqrt(sum((X1-Y1).^2, 2));
fprintf('Original: min = %f | mean = %f | max = %f | std = %f\n', min(dists), mean(dists), max(dists), std(dists))

normDists = sqrt(sum((X2-Y2).^2, 2));
fprintf('Normalized: min = %f | mean = %f | max = %f | std = %f\n\n', min(normDists), mean(normDists), max(normDists), std(normDists))

% Plot the ECDFs
[f, x] = ecdf(dists); figure, plot(x, f, '-bx'); hold on
[fn, xn] = ecdf(normDists); plot(xn, fn, '-rx');
title('ECDF'), legend('Original', 'Normalized', 'Location', 'SouthEast'), xlabel('Spatial distance between matches (px)'), hold off

% Plot the histograms
figure, subplot(2, 1, 1), hist(sort(dists), 150), title('Original Sections')
subplot(2, 1, 2), hist(sort(normDists), 150), title('Normalized Sections'), xlabel('Spatial distance between matches (px)')