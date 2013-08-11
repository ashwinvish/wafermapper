function [ x_i, x_j ] = getMatches( sections, varargin )
%GETMATCHES Returns matching point pairs.

x_i = []; x_j = [];
if length(varargin) == 2 % two sections, all tiles
    s_i = varargin{1};
    s_j = varargin{2};
    
    for i = 1:length(sections(s_i).tiles)
        for j = 1:length(sections(s_i).tiles(i).pts(s_j, :))
            if ~isempty(sections(s_i).tiles(i).pts{s_j, j})
                x_i = [x_i; sections(s_i).tiles(i).pts{s_j, j}];
                x_j = [x_j; sections(s_j).tiles(j).pts{s_i, i}];
            end
        end
    end
    
elseif length(varargin) == 3 % one section, two tiles
    s = varargin{1};
    i = varargin{2};
    j = varargin{3};
    
    x_i = sections(s).tiles(i).pts{s, j};
    x_j = sections(s).tiles(j).pts{s, i};
    
elseif length(varargin) == 4 % two sections, two tiles
    s_i = varargin{1};
    i = varargin{2};
    s_j = varargin{3};
    j = varargin{4};
    
    x_i = sections(s_i).tiles(i).pts{s_j, j};
    x_j = sections(s_j).tiles(j).pts{s_i, i};
end


end

