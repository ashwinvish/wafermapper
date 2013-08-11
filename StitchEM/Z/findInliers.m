function inliers = findInliers( pts1, pts2 )
%FINDINLIERS Summary of this function goes here
%   Detailed explanation goes here

%showMatches(pts1, pts2);

% Distance between each pair of points
dists = sqrt(sum((pts1 - pts2) .^ 2, 2));

% Change in dist threshold
distIdx = sortrows([dists [1:length(dists)]']);
cutoff = find((diff(distIdx(:, 1)) < 40) == 0, 1);
inliers = distIdx(1:cutoff, 2);


%showMatches(pts1(inliers, :), pts2(inliers, :));

% Mean + standard deviation threshold
% knob = 0.001;
% %lowerBound = mean(dists) - knob * std(dists);
% lowerBound = 0;
% upperBound = mean(dists) + knob * std(dists);
% inliers = find(dists > lowerBound & dists < upperBound);
% showMatches(pts1(inliers, :), pts2(inliers, :));
% 
% figure, plot(dists, '-x'), hold on
% plot([1 length(dists)], [lowerBound lowerBound], 'r-')
% plot([1 length(dists)], [upperBound upperBound], 'r-')
% hold off
% 
% % Empirical cumulative distribution function
% [fX, x] = ecdf(dists);
% figure, plot(x, fX, '-x')



% figure
% diffs = vertcat(ZPts{:, 1}) - vertcat(ZPts{:, 2});
% [fX, x] = ecdf(diffs(:, 1));
% [fY, y] = ecdf(diffs(:, 2));
% plot(x, fX, 'r-x', y, fY, 'b-x')
% 
% i_x = find(diffs == x(find(fX > 0.95, 1)));
% i_y = find(diffs == y(find(fY > 0.95, 1)));
%showMatches(ZMatches(1:min(i_x, i_y), :))
end

