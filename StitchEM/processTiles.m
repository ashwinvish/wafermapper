function tiles = processTiles(params, numSecs)
%PROCESSTILES Processes a folder of EM images into a tiles structure for
%use in StitchEM, provided that the files follow the format:
%   'Tile_r##-c##_{...}.tif' where the ## correspond to the row and column
%   of the tile.

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
    'filename', cell(1, numTiles), ... % image filename (with path)
    'filesize', cell(1, numTiles), ... % the size of the image in bytes
    'height', cell(1, numTiles), ...   % dimensions of the image
    'width', cell(1, numTiles), ...    %          ^ ^ ^
    'row', cell(1, numTiles), ...      % coordinates relative to the grid
    'col', cell(1, numTiles), ...      %  tiles in the section
    'offsetX', cell(1, numTiles), ...  % pixel offsets based on the overlap
    'offsetY', cell(1, numTiles), ...  %  and position within the grid
    'R', cell(1, numTiles), ...        % spatial reference structure (see imref2d)
    'tR', cell(1, numTiles), ...       % R for the transformed image
    'SURFFeats', cell(1, numTiles), ...
    'SURFPoints', cell(1, numTiles), ...
    'seams', cell(1, numTiles), ...
    'pts', cell(1, numTiles), ...      % global point matches for each seam
    'localPts', cell(1, numTiles), ... % point matches relative to the local image coordinate system
    'T', cell(1, numTiles), ...        % 3x3 linear transformation matrix
    'tform', cell(1, numTiles), ...    % transformations saved as MATLAB affine2d structures
    'neighbors', cell(1, numTiles));   % list of neighboring tiles that share a seam
overlapRatio = params.overlapRatio;



% Get metadata from tile images
parfor i = 1:length(filenames)
    % Image/file data
    tiles(i).filename = filenames{i};
    info = imfinfo(tiles(i).filename);
    tiles(i).filesize = info(1).FileSize;
    tiles(i).width = info(1).Width;
    tiles(i).height = info(1).Height;
    tiles(i).row = str2num(names{i}.row); %#ok<ST2NM>
    tiles(i).col = str2num(names{i}.col); %#ok<ST2NM>

    % Calculate rough global alignment for points
    tiles(i).offsetX = (tiles(i).col - 1) * tiles(i).width * (1 - overlapRatio);
    tiles(i).offsetY = (tiles(i).row - 1) * tiles(i).height * (1 - overlapRatio);
    tiles(i).R = imref2d([tiles(i).height, tiles(i).width], [tiles(i).offsetX + 0.5, tiles(i).offsetX + tiles(i).width + 0.5], [tiles(i).offsetY + 0.5, tiles(i).offsetY + tiles(i).height + 0.5]);

    % Initialize some defaults
    tiles(i).tR = tiles(i).R;
    tiles(i).SURFFeats = cell(1, numTiles);
    tiles(i).SURFPoints = cell(1, numTiles);
    tiles(i).seams = cell(1, numTiles);
    tiles(i).pts = cell(numSecs, numTiles);
    tiles(i).localPts = cell(numSecs, numTiles); % sections(secIdx).tiles(tileIdx).pts{secIdx2, tileIdx2}
    tiles(i).T = eye(3);
    tiles(i).tform = affine2d(tiles(i).T);
    tiles(i).neighbors = {}; % specified as [secIdx, tileIdx]
end
end