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

origTiles = tiles;
tikTiles = origTiles;
lambdas = []; dists = []; costs = []; stepsize = 0.0001;
for lambda = [0.000001:0.0000005:0.00001 0.00001:0.000005:0.0001 0.0001:0.00005:0.001 0.001:0.0005:0.01 0.01:0.005:0.1 0.1:0.05:1.0 1.0:0.5:10.0 10.0:5.0:100.0]
    x_hat = (lambda .^ 2 * (A' * A) + gamma' * gamma) \ (lambda .^ 2 * A' * b);
    x_hat = x_hat(:, 1:2); % drop the last column ([0 0 1]')
    
    for i = 1:length(tikTiles)
        tikTiles(i).T = [x_hat((i - 1) * 3 + 1:i * 3, :) [0 0 1]'];
    end
    
    [totalDist, numMatches] = tilesDist(tikTiles); % total euclidean distance
    cost = [sum(sum(abs(gamma * x_hat))) sum(sum(abs(A * x_hat - b(:, 1:2))))]; % cost function terms
    fprintf('lambda = %.4f, total dist = %.2fpx, dist/px = %.5fpx, rigidity = %.2f, fit = %.2f\n', lambda, totalDist, totalDist/numMatches, cost(1), cost(2))
    
    lambdas = [lambdas; lambda];
    dists = [dists; totalDist];
    costs = [costs; cost];
end

% Get the error statistics for the transforms in 'tiles' struct (for
% comparison)
[totalDist, numMatches] = tilesDist(tilesIter);
t = vertcat(tilesIter(:).T); t = t(:, 1:2);
cost = [sum(sum(abs(gamma * t))) sum(sum(abs(A * t - b(:, 1:2))))];
fprintf('\nreference error: total dist = %.2fpx, dist/px = %.5fpx, rigidity = %.2f, fit = %.2f\n', totalDist, totalDist/numMatches, cost(1), cost(2))

figure('NumberTitle', 'off', 'Name', params.baseName);

subplot(2,2,1), loglog(lambdas, costs(:, 2), '-x', [min(lambdas) max(lambdas)], [cost(2) cost(2)])
ylabel('||A * x - b||')
xlabel('lambda')
title('Rigidity term')

subplot(2,2,3), loglog(lambdas, costs(:, 1), '-x', [min(lambdas) max(lambdas)], [cost(1) cost(1)])
ylabel('||gamma * x||')
xlabel('lambda')
title('Fit term')

subplot(2,2,[2 4]), loglog(lambdas, dists, '-x', [min(lambdas) max(lambdas)], [totalDist totalDist])
ylabel('norm-1')
xlabel('lambda')
legend('tikhonov', 'iter')
title('Sum of distances')
