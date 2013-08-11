function showMatches( matches, matches2 )
%SHOWMATCHES Plots point matches.

if nargin < 2
    from = matches(:, 1:2);
    to = matches(:, 3:4);
else
    from = matches;
    to = matches2;
end

figure, hold on

plot(from(:,1), from(:,2), 'rx');
plot(to(:,1), to(:,2), 'bx');

res = 8000;
xlim([0 res*0.9*4])
ylim([0 res*0.9*4])
set(gca, 'XTick', [res*0.9 res*0.9*2 res*0.9*3 res*0.9*4]);
set(gca, 'YTick', [res*0.9 res*0.9*2 res*0.9*3 res*0.9*4]);
grid on

lineX = [from(:,1)'; to(:,1)'];
numPts = numel(lineX);
lineX = [lineX; NaN(1,numPts/2)];

lineY = [from(:,2)'; to(:,2)'];
lineY = [lineY; NaN(1,numPts/2)];

plot(lineX(:), lineY(:), 'g');
set(gca,'YDir','reverse');
hold off

end

