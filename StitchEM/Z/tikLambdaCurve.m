function [ lambdas, dists, costs ] = tikLambdaCurve(sections, params)
%TIKHONOVLAMBDACURVE Generates a curve for the lambda parameter of the
%Tikhonov regularization algorithm.

if nargin < 3
    figTitle = 'lambda curve';
end

% Initialize some basics
A = []; b = []; gamma = []; numTiles = arrayfun(@(x) length(x.tiles), sections);

% Construct data matrices from the point correspondencies
for s1 = 1:length(sections)
    for s2 = s1:length(sections)
        for i1 = 1:length(sections(s1).tiles)
            for i2 = i1:length(sections(s2).tiles)
                % Get matching points
                pts1 = sections(s1).tiles(i1).pts{s2, i2};
                pts2 = sections(s2).tiles(i2).pts{s1, i1};
                
                % Use appropriate parameters (for weighing)
                if s1 == s2
                    prms{s1} = sections(s1).params;
                    prms{s2} = sections(s2).params;
                else
                    prms{s1} = params;
                    prms{s2} = params;
                end
                
                if ~isempty(pts1) && ~isempty(pts2)
                    %fprintf('s%d t%d <-> s%d t%d: %d matches\n', s1, i1, s2, i2, size(pts1, 1))
                    % Pre-allocate block row in A and gamma
                    blockRow = zeros(size(pts1, 1), 3 * sum(numTiles));
                    
                    % Pad points with 1's
                    pts1 = [pts1 ones(size(pts1, 1), 1)];
                    pts2 = [pts2 ones(size(pts2, 1), 1)];
                    
                    % Weigh the points
                    pts1 = pts1 * prms{s1}.weight;
                    pts2 = pts2 * prms{s2}.weight;
                    
                    % Calculate correct columns to place the points into
                    col1 = (sum(numTiles(1:s1)) - numTiles(s1) + i1 - 1) * 3 + 1;
                    col2 = (sum(numTiles(1:s2)) - numTiles(s2) + i2 - 1) * 3 + 1;
                    
                    % Place first set of points into block row
                    blockRow(:, col1:col1+2) = pts1;
                    
                    % This is the row that A will contain...
                    A = [A; blockRow];
                    
                    % ... which matches with b (rigidity term, A * x = b)
                    b = [b; pts1];
                    
                    % Place second set of points into block row
                    blockRow(:, col2:col2+2) = -pts2;
                    
                    % And concatenate into gamma such that gamma * x = 0
                    gamma = [gamma; blockRow];
                end
            end
        end
    end
end

testSecs = sections;
lambdas = []; distsXY = []; distsZ = []; costs = [];
for lambda = [0.000001:0.0000005:0.00001 0.00001:0.000005:0.0001 0.0001:0.00005:0.001 0.001:0.0005:0.01 0.01:0.005:0.1 0.1:0.05:1.0 1.0:0.5:10.0 10.0:5.0:100.0]
    x_hat = (lambda .^ 2 * (A' * A) + gamma' * gamma) \ (lambda .^ 2 * A' * b);
    x_hat = x_hat(:, 1:2); % drop the last column ([0 0 1]')
    
    % Splice x_hat into discrete T matrices and save to sections structure
    startRow = 1;
    for s = 1:length(testSecs)
        for idx = startRow:3:startRow + length(testSecs(s).tiles) * 3 - 1
            i = (idx - startRow) / 3 + 1;
            testSecs(s).tiles(i).T = [x_hat(idx:idx+2, :) [0 0 1]'];
            testSecs(s).tiles(i).tform = affine2d(testSecs(s).tiles(i).T);
        end
        startRow = startRow + length(testSecs(s).tiles) * 3;
    end
    
    [totalDistXY, totalDistZ, ~, ~] = matchesDist(testSecs); % total euclidean distance
    cost = [sum(sum(abs(gamma * x_hat))) sum(sum(abs(A * x_hat - b(:, 1:2))))]; % cost function terms
    %fprintf('lambda = %.4f, total dist = %.2fpx, dist/px = %.5fpx, rigidity = %.2f, fit = %.2f\n', lambda, totalDist, totalDist/numMatches, cost(1), cost(2))
    
    lambdas = [lambdas; lambda];
    distsXY = [distsXY; totalDistXY];
    distsZ = [distsZ; totalDistZ];
    costs = [costs; cost];
end

figure('NumberTitle', 'off', 'Name', figTitle);

subplot(2,2,1), loglog(lambdas, costs(:, 2), '-x')
ylabel('||A * x - b||')
xlabel('lambda')
title('Rigidity term')

subplot(2,2,3), loglog(lambdas, costs(:, 1), '-x')
ylabel('||gamma * x||')
xlabel('lambda')
title('Fit term')

subplot(2,2,2), loglog(lambdas, distsXY, '-x')
ylabel('norm-1')
xlabel('lambda')
title('Sum of distances (XY)')

subplot(2,2,4), loglog(lambdas, distsZ, '-x')
ylabel('norm-1')
xlabel('lambda')
title('Sum of distances (Z)')
end

