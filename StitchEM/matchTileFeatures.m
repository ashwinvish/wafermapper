function tiles = matchTileFeatures(params, tiles)
% MATCHTILEFEATURES Finds features and matches them in all tiles.
% Access matched pairs by doing tiles(i).pts{j} for the points in tile i
% that match with tile j and tiles(j).pts{i} for the reverse.
logmsg('------- Finding matching features...\n'); findFeaturesTime = tic;

cols = max([tiles(:).col]);
totalPts = 0;
for i = 1:length(tiles)
    if ~isempty(tiles(i).img)
        %fprintf('Processing tile %d/%d...\n', i, length(tiles));
        
        % Get list of neighbor tiles indices
        neighbors = [(tiles(i).row - 2) * cols + tiles(i).col;      % top
                     (tiles(i).row - 0) * cols + tiles(i).col;      % bottom
                     (tiles(i).row - 1) * cols + tiles(i).col - 1;  % left
                     (tiles(i).row - 1) * cols + tiles(i).col + 1]; % right
        directions = {'top', 'bottom', 'left', 'right'};
        
        for n = 1:length(neighbors)
            j = neighbors(n);
            
            % Check if the neighbor exists, has an image loaded, and both
            % the neighbor and the current tile do not already have
            % matching points
            if j > 0 && j <= length(tiles) && ~isempty(tiles(j).img) && ...
                     (params.overwriteSURF || (isempty(tiles(i).pts{j}) && ...
                     isempty(tiles(j).pts{i}))) && ...
                     (tiles(i).row == tiles(j).row || ...
                     tiles(i).col == tiles(j).col)
                %logmsg(sprintf('Finding matches with %s tile... ', directions{n}));
                
                % Obtain matching points from SURF
                tic; [ptsIJ, ptsJI] = surf2cp( ...
                tiles(i).img, tiles(j).img, directions{n}, ...
                params.overlapRatio, params);
                
                % Save the points to their respective tiles
                tiles(i).localPts{j} = ptsIJ;
                tiles(j).localPts{i} = ptsJI;
                
                % Save the points as global coordinates
                [gX, gY] = tiles(i).R.intrinsicToWorld(ptsIJ(:, 1), ptsIJ(:, 2));
                tiles(i).pts{j} = [gX + 0.5, gY + 0.5];
                [gX, gY] = tiles(j).R.intrinsicToWorld(ptsJI(:, 1), ptsJI(:, 2));
                tiles(j).pts{i} = [gX + 0.5, gY + 0.5];
                
                % Keep track of neighbors for each tile
                tiles(i).neighbors = [tiles(i).neighbors; j];
                tiles(j).neighbors = [tiles(j).neighbors; i];
                
                % Accumulate number of points statistic
                totalPts = totalPts + size(tiles(i).pts{j}, 1);
                
                %logmsg(sprintf('Found %d matching points. [%.2fs]\n', ...
                %    size(tiles(i).pts{j}, 1), toc));
            end
        end
    end
end

% Average pairs of points per tile
avgPts = totalPts / length(tiles);

logmsg(sprintf('Done finding features (average %.2f points per tile, %d total). [%.2fs]\n\n', avgPts, totalPts, toc(findFeaturesTime)));
end