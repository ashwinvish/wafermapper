function showMatches( tiles, i, j )
%SHOWMATCHES Shows two tiles and their correspondencies in figure windows
%side by side.

figure; imshow(tiles(i).img); hold on;
pts = tiles(i).localPts{j};
plot(pts(:,1), pts(:,2), 'rx', 'MarkerSize', 8);
hold off;

figure; imshow(tiles(j).img); hold on;
pts = tiles(j).localPts{i};
plot(pts(:,1), pts(:,2), 'rx', 'MarkerSize', 8);
hold off;

end

