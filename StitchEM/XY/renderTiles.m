function tiles = renderTiles(params, tiles)
% RENDERTILES Given a tiles structure, renders the individual tiles and
% montages them into a single image.

logmsg('------- Rendering tiles...\n'); renderTime = tic;

% Apply the transforms to the tiles in parallel
logmsg('Transforming tiles...'); tic;
timgs = cell(length(tiles), 1);
parfor i = 1:length(tiles)
    [timgs{i}, tiles(i).tR] = imwarp(tiles(i).img, tiles(i).R, tiles(i).tform);
end
logmsg(sprintf(' Done. [%.2fs]\n', toc));

% Save the transformed images back to the tiles structure
if params.saveTImgs
    for i = 1:length(tiles); tiles(i).timg = timgs{i}; end
end

% Interpolate the images onto a composite montage and render them in place
% before saving to disk
if params.render
    % Calculate final (global) spatial reference for the full section
    Rs = [tiles(:).tR];
    finalXLims = [min([Rs(:).XWorldLimits]) max([Rs(:).XWorldLimits])];
    finalYLims = [min([Rs(:).YWorldLimits]) max([Rs(:).YWorldLimits])];
    finalSize = [ceil(diff(finalYLims)) ceil(diff(finalXLims))];
    finalR = imref2d(finalSize, finalXLims, finalYLims);

    % Pre-compute world coordinates of section image pixels
    logmsg('Calculating pixel-coordinate grids...'); tic;
    [finalWorldCoordsX, finalWorldCoordsY] = meshgrid(1:finalR.ImageSize(2),1:finalR.ImageSize(1));
    % Cast to single precision to save memory
    finalWorldCoordsX = single(finalWorldCoordsX); finalWorldCoordsY = single(finalWorldCoordsY);
    % Convert from intrinsic to world coords
    [finalWorldCoordsX, finalWorldCoordsY] = finalR.intrinsicToWorld(finalWorldCoordsX, finalWorldCoordsY);
    logmsg(sprintf(' Done. [%.2fs]\n', toc))

    % Pre-allocate memory for final image
    montage = zeros(finalSize, 'uint8');

    for i = 1:length(tiles)
        logmsg(sprintf('Rendering tile %d...', i)); tic;
        % Possible optimization: compute finalWorldCoordsX and Y subset
        % here instead of precomputing to save memory
        
        % Calculate subset of the final image we are replacing
        [i1, j1] = finalR.worldToSubscript(tiles(i).tR.XWorldLimits(1), tiles(i).tR.YWorldLimits(1));
        [i2, j2] = finalR.worldToSubscript(tiles(i).tR.XWorldLimits(2), tiles(i).tR.YWorldLimits(2));

        % Get the intrinsic coords on the tile of the world coords of the subset we're working with
        [tileXIntrinsic, tileYIntrinsic] = tiles(i).tR.worldToIntrinsic(finalWorldCoordsX(i1:i2, j1:j2), finalWorldCoordsY(i1:i2, j1:j2));

        % Interpolate the transformed tile to the final image subset and 
        % blend the pixels with the subset of pixels in the final image
        % TODO: Switch to interp2 (we're not really using the main changes
        % in interp2d and it is internal and subject to change)
        montage(i1:i2, j1:j2) = max(montage(i1:i2, j1:j2), ...
            cast(images.internal.interp2d(single(timgs{i}), tileXIntrinsic, tileYIntrinsic, 'bilinear', 0), 'uint8'));
        logmsg(sprintf(' Done. [%.2fs]\n', toc))
    end

    % Save to file
    logmsg('Writing to disk...'); tic;
    imwrite(montage, params.montageFilename);
    logmsg(sprintf(' Saved montage to %s. [%.2fs]\n', params.montageFilename, toc))
end
logmsg(sprintf('Done rendering tiles. [%.2fs]\n\n', toc(renderTime)))
end