function tiles = processFiles(params)
%PROCESSFILES Processes a folder of EM images into a tiles structure for
%use in StitchEM, provided that the files follow the format:
%   'Tile_r##-c##_{...}.tif' where the ## correspond to the row and column
%   of the tile.
logmsg('------- Processing files...\n'); processFilesTime = tic;

% Get filenames from folder
directory = dir(params.tileFolder);
files = {directory(~[directory.isdir]).name}';
indices = ~cellfun(@isempty, regexp(files, '^Tile_.*\.tif'));
filenames = strcat(params.tileFolder, filesep, files(indices));

% Truncate (for debugging/development)
if params.truncateFiles > 0
    filenames = filenames(1:params.truncateFiles);
end

% Extract the row and column numbers
expr = 'Tile_r(?<row>[0-9]*)-c(?<col>[0-9]*)_';
names = regexp(filenames, expr, 'names');

% Initialize the tiles structure
numTiles = length(filenames);
tiles = struct(...
    'filename', cell(numTiles, 1), ... % image filename (with path)
    'img', cell(numTiles, 1), ...      % the image data (intensity matrix)
    'height', cell(numTiles, 1), ...   % dimensions of the image
    'width', cell(numTiles, 1), ...    %          ^ ^ ^
    'row', cell(numTiles, 1), ...      % coordinates relative to the grid
    'col', cell(numTiles, 1), ...      %  tiles in the section
    'offsetX', cell(numTiles, 1), ...  % pixel offsets based on the overlap
    'offsetY', cell(numTiles, 1), ...  %  and position within the grid
    'R', cell(numTiles, 1), ...        % spatial reference structure (see imref2d)
    'tR', cell(numTiles, 1), ...       % R for the transformed image
    'pts', cell(numTiles, 1), ...      % global point matches for each seam
    'localPts', cell(numTiles, 1), ... % point matches relative to the local image coordinate system
    'T', cell(numTiles, 1), ...        % 3x3 linear transformation matrix
    'tform', cell(numTiles, 1), ...    % transformations saved as MATLAB affine2d structures
    'neighbors', cell(numTiles, 1));   % list of neighboring tiles that share a seam
overlapRatio = params.overlapRatio;

% Get metadata from tile images
parfor i = 1:length(filenames)
    % Image/file data
    tiles(i).filename = filenames{i};
    tiles(i).img = imread(filenames{i});
    tiles(i).height = size(tiles(i).img, 1);
    tiles(i).width = size(tiles(i).img, 2);
    tiles(i).row = str2num(names{i}.row); %#ok<ST2NM>
    tiles(i).col = str2num(names{i}.col); %#ok<ST2NM>

    % Calculate rough global alignment for points
    tiles(i).offsetX = (tiles(i).col - 1) * size(tiles(i).img, 2) * (1 - overlapRatio);
    tiles(i).offsetY = (tiles(i).row - 1) * size(tiles(i).img, 1) * (1 - overlapRatio);
    tiles(i).R = imref2d(size(tiles(i).img), [tiles(i).offsetX + 0.5, tiles(i).offsetX + tiles(i).width + 0.5], [tiles(i).offsetY + 0.5, tiles(i).offsetY + tiles(i).height + 0.5]);

    % Initialize some defaults
    tiles(i).tR = tiles(i).R;
    tiles(i).pts = cell(numTiles, 1);
    tiles(i).localPts = cell(numTiles, 1);
    tiles(i).T = eye(3);
    tiles(i).tform = affine2d(tiles(i).T);
    tiles(i).neighbors = [];
end

logmsg(sprintf('Done processing files. [%.2fs]\n\n', toc(processFilesTime)));
end