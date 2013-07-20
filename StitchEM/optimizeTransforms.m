function tiles = optimizeTransforms(params, tiles)
logmsg('------- Finding optimal transformations...\n'); tformTime = tic;

done = false; % flag to simulate 'do-while' control structure
iteration = 0; % iteration counter
distances = []; deltas = [];

[totalDist, numPointMatches] = tilesDist(tiles);
avgPtDist = totalDist / numPointMatches;
logmsg(sprintf('Iteration 0: total distance = %.2fpx, dist/pt = %.5fpx, delta = n/a\n', totalDist, avgPtDist));
while ~done
    iteration = iteration + 1;
    
    % Leave first tile fixed (it will keep the identity transform)
    for i = 2:length(tiles)
        % Get local and neighboring points
        xy = []; uv = [];
        for n = 1:length(tiles(i).neighbors)
            j = tiles(i).neighbors(n);
            
            seamXY = tiles(i).pts{j};
            seamUV = [tiles(j).pts{i} ones(size(tiles(j).pts{i}, 1), 1)] * tiles(j).T(:, 1:2);
            xy = [xy; seamXY];
            uv = [uv; seamUV];
        end
        
        % Fit transform
        tiles(i).T = [[xy ones(size(xy, 1), 1)] \ uv [0 0 1]'];
    end
    
    % Reset point distances
    for i = 1:length(tiles)
        tiles(i).dist = cell(length(tiles), 1);
    end
    
    % Calculate new point distances
    [totalDist, numPointMatches] = tilesDist(tiles);
    
    % Calculate average displacement and change since last iteration
    newAvgPtDist = totalDist / numPointMatches;
    delta = abs(newAvgPtDist - avgPtDist);
    avgPtDist = newAvgPtDist;
    if mod(iteration, params.iterVerbosity) == 0 || iteration == 1
        logmsg(sprintf('Iteration %d: total distance = %.2fpx, dist/pt = %.5fpx, delta = %.5fpx\n', iteration, totalDist, avgPtDist, delta));
    end
    distances = [distances; avgPtDist]; deltas = [deltas; delta];
    
    % End iterative process when the average displacement has converged
    done = delta < params.deltaThreshold && iteration >= params.minIterations;
end

% Convert tranforms matrices to MATLAB data structures
for i = 1:length(tiles)
    tiles(i).tform = affine2d(tiles(i).T);
end
logmsg(sprintf('Converged at iteration %d (total dist = %.3fpx, dist/pt = %.5fpx, delta = %.5f).\nDone. [%.2fs]\n\n', iteration, totalDist, avgPtDist, delta, toc(tformTime)));
end