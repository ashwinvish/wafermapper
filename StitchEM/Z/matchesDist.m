function [totalDistXY, totalDistZ, numPointPairsXY, numPointPairsZ] = matchesDist(varargin)

if length(varargin) == 1
    sections = varargin{1};
    XY_i = []; XY_j = []; Z_i = []; Z_j = [];
    for s1 = 1:length(sections)
        for s2 = s1:length(sections)
            for i1 = 1:length(sections(s1).tiles)
                for i2 = i1:length(sections(s2).tiles)
                    % Get point pairs
                    x_i = sections(s1).tiles(i1).pts{s2, i2};
                    x_j = sections(s2).tiles(i2).pts{s1, i1};

                    if ~isempty(x_i)
                        % Transform the points
                        x_i = [x_i ones(size(x_i, 1), 1)] * sections(s1).tiles(i1).T(:, 1:2);
                        x_j = [x_j ones(size(x_j, 1), 1)] * sections(s2).tiles(i2).T(:, 1:2);

                        if s1 == s2
                            % Concatenate to global set of point correspondencies
                            XY_i = [XY_i; x_i];
                            XY_j = [XY_j; x_j];
                        else
                            Z_i = [Z_i; x_i];
                            Z_j = [Z_j; x_j];
                        end
                    end
                end
            end
        end
    end
elseif length(varargin) == 2
    XY_i = varargin{1};
    XY_j = varargin{2};
    Z_i = [];
    Z_j = [];
elseif length(varargin) == 4
    XY_i = varargin{1};
    XY_j = varargin{2};
    Z_i = varargin{3};
    Z_j = varargin{4};
end

% Calculate distance (norm-1)
totalDistXY = norm(XY_i - XY_j, 1);
totalDistZ = norm(Z_i - Z_j, 1);
numPointPairsXY = size(XY_i, 1);
numPointPairsZ = size(Z_i, 1);
end