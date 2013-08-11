function sections = tikOptim(sections, params)
% TIKOPTIM Formats point correspondencies into large matrices
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
fprintf('------- Optimizing transformations (Tikhonov regularization)...\n'); optimTime = tic;

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

% Solve!
% x_hat is our approximation to the ideal set of transforms that minimizes
% our cost function
x_hat = (params.lambda .^ 2 * (A' * A) + gamma' * gamma) \ (params.lambda .^ 2 * A' * b);
x_hat = x_hat(:, 1:2); % drop the last column (~[0 0 1]')

% Splice x_hat into discrete T matrices and save to sections structure
startRow = 1;
for s = 1:length(sections)
    for idx = startRow:3:startRow + length(sections(s).tiles) * 3 - 1
        i = (idx - startRow) / 3 + 1;
        sections(s).tiles(i).T = [x_hat(idx:idx+2, :) [0 0 1]'];
        sections(s).tiles(i).tform = affine2d(sections(s).tiles(i).T);
    end
    startRow = startRow + length(sections(s).tiles) * 3;
end

% Get some statistics for the error of our set of transforms
[totalDistXY, totalDistZ, numMatchesXY, numMatchesZ] = matchesDist(sections);
totalDist = totalDistXY + totalDistZ;
numMatches = numMatchesXY + numMatchesZ;

fprintf('Done. Total distance: %.2fpx, Per point: %.5fpx. [%.2fs]\n\n', totalDist, totalDist/numMatches, toc(optimTime))
end