
waferName = 'w033\'

SPN = 'D:\MasterUTSL\UTSL_lgns1\'

checkCurrentFileName = [SPN waferName 'checkCurrentValues.mat'];

load(checkCurrentFileName);
%% 
vals = checkCurrentValues.vals;
sec = checkCurrentValues.sec;

medVals = median(vals(:,5:end),2) * 10^9;

plot(medVals)
ylim([median(medVals)-.02 median(medVals)+.02])


pool = mean(vals,1);
plot(vals')
plot(pool)





