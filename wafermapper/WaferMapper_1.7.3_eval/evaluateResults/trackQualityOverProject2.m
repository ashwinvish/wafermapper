% clear all
% 
% %
% SPN = 'D:\LGNs1\rawMontages_folder2\logBooks\'
% measureString = 'qual';
% dSPN = dir(SPN); dSPN(3:end);
% logBookNams = {};
% for i = 1:length(dSPN)
%     
%    nam = dSPN(i).name;
%    if sum(regexp(nam, 'LogBook_w'))
%        logBookNams{length(logBookNams)+1} = nam;
%    end
% end
%%
for wafNum = 39:length(logBookNams)
    
%%
%logFile = 'O:\joshm\LGNs1\rawMontages\logBooks\LogBook_w013.mat'
tic
logFile = [SPN logBookNams{wafNum}]
load(logFile);
'loading'
toc
tic
'parsing'
%% collect data

qual.Names = cat(1,logBook.sheets.quality.data(:,1));
qual.Vals = cat(1,logBook.sheets.quality.data{:,3});

WD.Names = cat(1,logBook.sheets.imageConditions.data(:,1)); %image names
WD.Vals = cat(1,logBook.sheets.imageConditions.data{:,5})*1000000; %working distance

itime.Names = WD.Names;
times = cat(1,logBook.sheets.imageConditions.data(:,32));
itime.Vals = datenum(times);

current.Names = cat(1,logBook.sheets.specimenCurrent.data(:,1));
clear topCurrent bottomCurrent
% for i = 1:size(logBook.sheets.specimenCurrent.data,1)
%     curVals = cat(1,logBook.sheets.specimenCurrent.data{i,2:end})*-1000000000;
%     curVals  = curVals(curVals~=0);
%     curVals = sort(curVals,'ascend');
%     topCurrent(i) = median(curVals(end-round(length(curVals)/3):end));
%     bottomCurrent(i) = median(curVals(1:round(length(curVals)/3)));
% end
% 
% current.Vals = topCurrent;%(topCurrent-bottomCurrent)./topCurrent
% %scatter(topCurrent,current.Vals)

%% choose measure
useMeasure = eval(measureString);
measureNames = useMeasure.Names;
measureVals = useMeasure.Vals;


%% sort sections
clear sec row col take lastTake
for i = 1:length(measureNames)
    nam = measureNames{i};
    secExp = regexp(nam,'_sec');
    rowExp = regexp(nam,'_r');
    colExp = regexp(nam,'-c');
    wafExp = regexp(nam,'_w');
    sec(i) = str2num(nam(secExp+4:secExp+7));
    row(i) = str2num(nam(rowExp +2: colExp -1));
    col(i) = str2num(nam(colExp + 2: wafExp -1));
    allTakes = find(strcmp(measureNames,nam));
    take(i) = find(allTakes==i);
    lastTake(i) = take(i) == length(allTakes);
end

%% Select tiles to analyize

useTiles = lastTake;%(row == 1) & (col ==1)
measureNames = measureNames(useTiles);
measureVals = measureVals(useTiles);

relativeVals = (measureVals-mean(measureVals));
absDif = sort(abs(relativeVals),'ascend');
thresh90 = absDif(round(length(absDif)*.90));

%% Collect wafer info
qualMeans(wafNum) = mean(measureVals);
qual90(wafNum) = thresh90;
percentRetakes(wafNum) = sum(take>1)/length(take)*100;
toc
end
% 

%%
plot(fliplr(percentRetakes))
hold on
plot(fliplr(qualMeans))

