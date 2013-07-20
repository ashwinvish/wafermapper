totalTime = tic;

% 1. Load parameters
params = defaultParameters('/path/to/section/folder');
logmsg(sprintf('------- Loaded parameters.\nTile folder: %s\ndeltaThreshold = %f\nmatchThreshold = %f\nMetricThreshold = %f\n\n', strrep(params.tileFolder, '\', '\\'), params.deltaThreshold, params.MatchThreshold, params.MetricThreshold));

% 2. Process files
tiles = processFiles(params);

% 3. Find matching features
tiles = matchTileFeatures(params, tiles);

% 4. Optimize transformations
tilesIter = optimizeTransforms(params, tiles);
tilesTik = tikhonovOptimization(params, tiles);

% 5. Transform and render the tiles
params.montageFilename = sprintf('%s_iter.tif', params.baseName);
tilerIter = renderTiles(params, tilesIter);

params.montageFilename = sprintf('%s_tikhonov.tif', params.baseName);
tilesTik = renderTiles(params, tilesTik);

logmsg(sprintf('Done stitching section. [%.2fs]\n\n', toc(totalTime)))