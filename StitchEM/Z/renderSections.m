function renderSections(sections, params)

% Calculate the final global spatial reference for all sections
tileRs = {};
for s = 1:length(sections)
    for i = 1:length(sections(s).tiles)
        tileR = sections(s).tiles(i).R;
        % This routine is copied straight from applyGeometricTransformToSpatialRef (internal)

        [XWorldLimitsOut,YWorldLimitsOut] = outputLimits(sections(s).tiles(i).tform,tileR.XWorldLimits,tileR.YWorldLimits);

        % Fix the output resolution to be the same as the input resolution in
        % each dimension.
        outputResolutionX = tileR.PixelExtentInWorldX;
        outputResolutionY = tileR.PixelExtentInWorldY;

        % Use ceil to provide grid that will accomodate world limits at roughly the
        % target resolution.
        numCols = ceil(diff(XWorldLimitsOut) / outputResolutionX);
        numRows = ceil(diff(YWorldLimitsOut) / outputResolutionY);

        % If the world limits divided by the output resolution are not
        % integrally valued, we adjust the world limits such that we exactly
        % honor the target output resolution. We adjust all four corners such
        % that the center of the image remains fixed in world coordinates.
        xNudge = (numCols*outputResolutionX-diff(XWorldLimitsOut))/2;
        yNudge = (numRows*outputResolutionY-diff(YWorldLimitsOut))/2;
        XWorldLimitsOut = XWorldLimitsOut + [-xNudge xNudge];
        YWorldLimitsOut = YWorldLimitsOut + [-yNudge yNudge];

        % Construct output referencing object with desired outputImageSize and
        % world limits.
        outputImageSize = [numRows numCols];
        tileRs{s, i} = imref2d(double(outputImageSize),XWorldLimitsOut,YWorldLimitsOut);
    end
end

% Calculate final (global) spatial reference for the full section
Rs = [tileRs{:}];
finalXLims = [min([Rs(:).XWorldLimits]) max([Rs(:).XWorldLimits])];
finalYLims = [min([Rs(:).YWorldLimits]) max([Rs(:).YWorldLimits])];
finalSize = [ceil(diff(finalYLims)) ceil(diff(finalXLims))];
finalR = imref2d(finalSize, finalXLims, finalYLims);

if ~params.dontRenderSection
    % Pre-compute world coordinates of section image pixels
    fprintf('Calculating pixel-coordinate grids...'); tic;
    [finalWorldCoordsX, finalWorldCoordsY] = meshgrid(1:finalR.ImageSize(2),1:finalR.ImageSize(1));
    % Cast to single precision to save memory
    finalWorldCoordsX = single(finalWorldCoordsX); finalWorldCoordsY = single(finalWorldCoordsY);
    % Convert from intrinsic to world coords
    [finalWorldCoordsX, finalWorldCoordsY] = finalR.intrinsicToWorld(finalWorldCoordsX, finalWorldCoordsY);
    fprintf(' Done. [%.2fs]\n', toc)
end

% Set up TrakEM2 import text file
if params.exportForTrakEM
    importFile = [params.waferFolder filesep 'Import-TrakEM2.txt'];
    fh = fopen(importFile, 'w');
end

for s = 1:length(sections)
    % Transform tiles in parallel
    fprintf('Transforming tiles in section %d...', sections(s).secNum); tic;
    tileImgs = cell(length(sections(s).tiles), 1);
    tilePaths = {sections(s).tiles(:).filename};
    tileTforms = {sections(s).tiles(:).tform};
    initalRs = {sections(s).tiles(:).R};
    parfor i = 1:length(sections(s).tiles)
        tileImgs{i} = imwarp(imread(tilePaths{i}), initalRs{i}, tileTforms{i});
    end
    fprintf(' Done. [%.2fs]\n', toc);
    
    % Write to disk if necessary
    if params.exportForTrakEM
        renderFolder = [sections(s).path filesep 'render'];
        if ~exist(renderFolder, 'file'); mkdir(renderFolder); end
        
        for i = 1:length(tileImgs)
            [~, name, ext] = fileparts(sections(s).tiles(i).filename);
            tileFile = [renderFolder filesep name ext];
            imwrite(tileImgs{i}, tileFile);
            fprintf(fh, '%s\t%d\t%d\t%d\n', tileFile, round(tileRs{s, i}.XWorldLimits(1)), round(tileRs{s, i}.YWorldLimits(1)), s);
        end
    end
    
    if ~params.dontRenderSection
        % Pre-allocate memory for final image
        alignedSection = zeros(finalSize, 'uint8');

        fprintf('Rendering tiles in section %d...', sections(s).secNum); tic;
        for i = 1:length(tileImgs)
            % Possible optimization: compute finalWorldCoordsX and Y subset
            % here instead of precomputing to save memory

            % Calculate subset of the final image we are replacing
            [i1, j1] = finalR.worldToSubscript(tileRs{s,i}.XWorldLimits(1), tileRs{s,i}.YWorldLimits(1));
            [i2, j2] = finalR.worldToSubscript(tileRs{s,i}.XWorldLimits(2), tileRs{s,i}.YWorldLimits(2));

            % Get the intrinsic coords on the tile of the world coords of the subset we're working with
            [tileXIntrinsic, tileYIntrinsic] = tileRs{s,i}.worldToIntrinsic(finalWorldCoordsX(i1:i2, j1:j2), finalWorldCoordsY(i1:i2, j1:j2));

            % Interpolate the transformed tile to the final image subset and 
            % blend the pixels with the subset of pixels in the final image
            % TODO: Switch to interp2 (we're not really using the main changes
            % in interp2d and it is internal and subject to change)
            alignedSection(i1:i2, j1:j2) = max(alignedSection(i1:i2, j1:j2), ...
                cast(images.internal.interp2d(single(tileImgs{i}), tileXIntrinsic, tileYIntrinsic, 'bilinear', 0), 'uint8'));
        end
        fprintf(' Done. [%.2fs]\n', toc);

        % Write to disk
        fprintf(['Writing to file ' strrep(sections(s).params.montageFilename, '\', '\\') '...']); tic;
        imwrite(alignedSection, sections(s).params.montageFilename);
        fprintf(' Done. [%.2fs]\n', toc)
    end
end

% Close import file handle
if params.exportForTrakEM
    fclose(fh);
end
end