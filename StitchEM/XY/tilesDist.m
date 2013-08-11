function [totalDist, numPointPairs] = tilesDist(tiles)
% TILESDIST Returns the first norm of the distance between all point pairs 
% in the set of tiles. This is the sum of the Euclidean distances between 
% all point pairs.

XY = []; UV = [];
for i = 1:length(tiles)
    for j = i:length(tiles)
        if any(j == tiles(i).neighbors)
            % Get the local transformed points
            xy = tiles(i).pts{j};
            xy = [xy ones(size(xy, 1), 1)] * tiles(i).T(:, 1:2);
            XY = [XY; xy];
            
            % Get the target transformed points
            uv = tiles(j).pts{i};
            uv = [uv ones(size(uv, 1), 1)] * tiles(j).T(:, 1:2);
            UV = [UV; uv];
        end
    end
end

% Same as sum(sum(abs(XY - UV)))
totalDist = norm(XY - UV, 1);
numPointPairs = size(XY, 1);
end

