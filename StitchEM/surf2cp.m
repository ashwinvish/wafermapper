function [cp1, cp2] = surf2cp( img1, img2, overlapDirection, overlapAmount, params )
%SURF2CP Returns matching control points in the overlap region for the two
% images.
% A lower threshold for pair matching means less matches.

% Process args
if (nargin < 4)
    overlapDirection = 'right';
    overlapAmount = 1.0;
end
if (nargin < 5)
    params.MetricThreshold = 4000;
    params.NumOctaves = 3;
    params.NumScaleLevels = 4;
    params.SURFSize = 64;
    params.MatchThreshold = 0.1;
end

% Crop the images to overlap region and account for offset
size1 = size(img1); size2 = size(img2); offset1 = [0, 0]; offset2 = [0, 0];
switch overlapDirection
    case 'right'
        img1 = img1(:, 1 + round(size1(2) * (1.0 - overlapAmount)):size1(2));
        img2 = img2(:, 1:round(size2(2) * overlapAmount));
        offset1 = [round(size1(2) * (1.0 - overlapAmount)), 0];
    case 'left'
        img1 = img1(:, 1:round(size1(2) * overlapAmount));
        img2 = img2(:, 1 + round(size2(2) * (1.0 - overlapAmount)):size2(2));
        offset2 = [size2(2) * (1.0 - overlapAmount), 0];
    case 'bottom'
        img1 = img1(1 + round(size1(1) * (1.0 - overlapAmount)):size1(1), :);
        img2 = img2(1:round(size2(1) * overlapAmount), :);
        offset1 = [0, round(size1(1) * (1.0 - overlapAmount))];
    case 'top'
        img1 = img1(1:round(size1(1) * overlapAmount), :);
        img2 = img2(1 + round(size2(1) * (1.0 - overlapAmount)):size2(1), :);
        offset2 = [0, round(size2(1) * (1.0 - overlapAmount))];
end

% Get SURF features
points1 = detectSURFFeatures(img1, 'MetricThreshold', params.MetricThreshold, 'NumOctaves', params.NumOctaves, 'NumScaleLevels', params.NumScaleLevels);
points2 = detectSURFFeatures(img2, 'MetricThreshold', params.MetricThreshold, 'NumOctaves', params.NumOctaves, 'NumScaleLevels', params.NumScaleLevels);
%fprintf('\nFound %d features in image 1.', size(points1, 1))
%fprintf(' Found %d features in image 2.\n', size(points2, 1))

% Get feature vectors (descriptors)
[f1, vpts1] = extractFeatures(img1, points1, 'SURFSize', params.SURFSize);
[f2, vpts2] = extractFeatures(img2, points2, 'SURFSize', params.SURFSize);

% Match feature pairs
index_pairs = matchFeatures(f1, f2, 'MatchThreshold', params.MatchThreshold, 'Metric', 'SSD');
matched_pts1 = vpts1(index_pairs(:, 1));
matched_pts2 = vpts2(index_pairs(:, 2));

% Get just the pixel locations
cp1 = double(matched_pts1.Location);
cp2 = double(matched_pts2.Location);

% Adjust for offset due to overlap region crop
cp1(:,1) = cp1(:,1) + offset1(1); cp1(:,2) = cp1(:,2) + offset1(2);
cp2(:,1) = cp2(:,1) + offset2(1); cp2(:,2) = cp2(:,2) + offset2(2);
end

