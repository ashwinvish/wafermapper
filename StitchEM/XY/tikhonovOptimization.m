function tiles = tikhonovOptimization(params, tiles)
% TIKHONOVOPTIMIZATION Formats point correspondencies into large matrices
% before regularizing and fitting the correspondencies to each each other
% by linear transformations.
%
% This algorithm is also known as ridge regression, although the Tikhonov
% matrix utilized is generally identity, whereas we use this form to solve
% for our linear transformations.
%
% We minimize the cost function:
% cost = ||A * x - b|| ^ 2 + ||gamma * x|| ^ 2
% A contains one set of points for one seam per block row
% b contains the same set of points but as a 2 column block vector
% gamma contains two sets of points (correspondencies) for one seam per
%   block row (Tikhonov matrix)
%
% Reference: Tikhonov, A. N. (1963). [Solution of incorrectly formulated problems and the regularization method].
% Doklady Akademii Nauk SSSR 151: 501–504. Translated in Soviet Mathematics 4: 1035–1038.
logmsg('------- Optimizing transformations (Tikhonov regularization)...\n'); optimTime = tic;

% Construct data matrics from the point correspondencies
A = []; b = []; gamma = [];
for i = 1:length(tiles)
    for j = i:length(tiles)
        if any(j == tiles(i).neighbors)
            pts_i = [tiles(i).pts{j} ones(size(tiles(i).pts{j}, 1), 1)];
            pts_j = [tiles(j).pts{i} ones(size(tiles(j).pts{i}, 1), 1)];
            seam = zeros(size(pts_i, 1), length(tiles) * 3);
            seam(:, 3 * (i - 1) + 1:3 * (i - 1) + 3) = pts_i;
            A = [A; seam];
            seam(:, 3 * (j - 1) + 1:3 * (j - 1) + 3) = -pts_j;
            gamma = [gamma; seam];
            b = [b; pts_i];
        end
    end
end

% x_hat is our approximation to the ideal set of transforms that minimizes
% our cost function
x_hat = (params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b);
x_hat = x_hat(:, 1:2); % drop the last column ([0 0 1]')

% Splice x_hat into discrete T matrices and save to tiles structure
for i = 1:length(tiles); tiles(i).T = [x_hat((i - 1) * 3 + 1:i * 3, :) [0 0 1]']; end

% Get some statistics for the error of our set of transforms
[totalDist, numMatches] = tilesDist(tiles);

% Convert tranforms matrices to MATLAB data structures
for i = 1:length(tiles)
    tiles(i).tform = affine2d(tiles(i).T);
end

logmsg(sprintf('Done. Total distance: %.2fpx, Per point: %.5fpx. [%.2fs]\n\n', totalDist, totalDist/numMatches, toc(optimTime)))
end