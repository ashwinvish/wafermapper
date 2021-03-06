clear all
logFile = 'C:\Users\joshm\GoogleDriveJMDataWatcher\Google Drive\logBooks\LogBook_w042.mat'
%logFile = 'C:\Users\joshm\Documents\MyWork\logBooks\LogBook_w042.mat'
load(logFile);
pause(1)    

% itime current qual WD bCurrent tCurrent
measureString = 'qual'


fsize = 200;
field = zeros(fsize);

%% collect data

stageX = cat(1,logBook.sheets.imageConditions.data{:,23});
stageY = cat(1,logBook.sheets.imageConditions.data{:,24});
stageName = cat(1,logBook.sheets.imageConditions.data(:,1));

for i = 1:length(stageName)
    nam = stageName{i};
   secNam =  regexp(nam,'_Sec');
   monNam = regexp(nam,'_Mon');
   stageSec(i) = str2num(nam(secNam(end)+4:monNam(end)-1));
end

qual.Names = cat(1,logBook.sheets.quality.data(:,1));
qual.Vals = cat(1,logBook.sheets.quality.data{:,3});

WD.Names = cat(1,logBook.sheets.imageConditions.data(:,1)); %image names
WD.Vals = cat(1,logBook.sheets.imageConditions.data{:,5})*1000000; %working distance

itime.Names = WD.Names;
times = cat(1,logBook.sheets.imageConditions.data(:,32));
itime.Vals = datenum(times);

current.Names = cat(1,logBook.sheets.specimenCurrent.data(:,1));
for i = 1:size(logBook.sheets.specimenCurrent.data,1)
    
    curVals = cat(1,logBook.sheets.specimenCurrent.data{i,2:end})*-1000000000;
    curVals  = curVals(curVals~=0);
    curVals = sort(curVals,'ascend');
    topCurrent(i) = median(curVals(end-round(length(curVals)/3):end));
    bottomCurrent(i) = median(curVals(1:round(length(curVals)/3)));
end

current.Vals = topCurrent;
tCurrent.Vals = topCurrent;%(topCurrent-bottomCurrent)./topCurrent
bCurrent.Vals = bottomCurrent
tCurrent.Names = current.Names;
bCurrent.Names = current.Names;
%scatter(topCurrent,current.Vals)


if isfield(logBook.sheets,'planeFit')
    tempSec = stageSec;
    for i = 1:length(logBook.planeFit)
        planeWDdif(i,:) = logBook.planeFit(i).planeFitInfo.WDdif;
        planeSec = str2num(logBook.planeFit(i).planeFitInfo.section);
        secTarg = find(tempSec == planeSec,1);
        planeName{i} = stageName{secTarg};
        tempSec(secTarg) = 0;
    end
    slope = max(abs(planeWDdif(:,1)-planeWDdif(:,2)),abs(planeWDdif(:,2)-planeWDdif(:,3)));
    
    
    plane.Names = planeName;
    plane.Vals = slope;

end
%% choose measure
useMeasure = eval(measureString);
measureNames = useMeasure.Names;
measureVals = useMeasure.Vals;


%% sort sections

for i = 1:length(measureNames)
    nam = measureNames{i};
    secExp = regexp(nam,'_sec');
    rowExp = regexp(nam,'_r');
    colExp = regexp(nam,'-c');
    wafExp = regexp(nam,'_w');
    sec(i) = str2num(nam(secExp+4:secExp+7));
    row(i) = str2num(nam(rowExp +2: colExp -1));
    col(i) = str2num(nam(colExp + 2: wafExp -1));
end

%% Select tiles to analyize

useTiles = row>0;%(row == 1) & (col ==1);
measureNames = measureNames(useTiles);
measureVals = measureVals(useTiles);
sec = sec(useTiles);
row = row(useTiles);
col = col(useTiles);

secList = unique(sec);

%% Find quality names in stage names
for i = 1:length(measureVals)
    nam = measureNames{i};
    stageInd = find(strcmp(nam,stageName),1,'first');
    stageName{stageInd} = 'used';
    stageInds(i) = stageInd;
    
    currentInd = find(strcmp(nam,current.Names),1,'first');
    current.Names{currentInd} = 'used';
    currentInds(i) = currentInd;  
    
    qualInd = find(strcmp(nam,qual.Names),1,'first');
    qual.Names{qualInd} = 'used';
    qualInds(i) = qualInd;  
end



measureX = stageX(stageInds);
measureY = stageY(stageInds);


%% find positions

for s = 1:length(secList)
   secTiles = sec == secList(s);
   secX(secTiles) = mean(measureX(secTiles));
   secY(secTiles) = mean(measureY(secTiles));
   secXdif(secTiles) = measureX(secTiles) - secX(secTiles)';
   secYdif(secTiles) = measureY(secTiles) - secY(secTiles)';
end

stageCenterX = 0.0751
stageCenterY =     0.0667

central = sqrt((secX - stageCenterX).^2 + (secY - stageCenterY).^2) * 1000;

%% Scale
difScale = 15000;

secX = secX - min(secX);
secY = secY - min(secY);
secX = secX/max(secX)*.8+.1;
secY = secY/max(secY)*.8+.1;
secX =(secX*fsize);
secY = (secY*fsize);

secY = secY + secYdif * difScale;
secX = secX + secXdif * difScale;

secY = round(secY);
secX = round(secX);

secInd = sub2ind(size(field),secY,secX);

field = zeros(fsize);
cmap = hsv(256);
cmap = cmap(57:end,:);
cmap(1,:) = 0;
colormap(cmap);
%%
relativeVals = (measureVals-mean(measureVals));
absDif = sort(abs(relativeVals),'ascend');
thresh90 = absDif(round(length(absDif)*.90));

stdWD = std(relativeVals(:));

relativeVals = (relativeVals/thresh90)*95+100;
field(secInd) = (relativeVals);

%% plot
subplot(8,12,[1 79])
image(fliplr(field))
text(10,10,sprintf('Mean = %.3f \n95%% range = %.3f',mean(measureVals),thresh90),...
    'Color','w','EdgeColor','w')

subplot(8,12,[8 80])
image([200:-1:1]')
text(0.75,100,num2str((([200:-9:0]-100)/100*thresh90+mean(measureVals))'))


subplot(8,12,[85 92])
plot(measureVals./measureVals,'r')
hold on
plot(measureVals/mean(measureVals))
hold off
ylim([.8 1.2])


subplot(8,12, [9 96])
scatter(measureVals,qual.Vals(qualInds))
%% Other plots
%{
figure
plot(bottomCurrent,'g')
hold on
plot(topCurrent,'r')
hold off
%}


%% Plot gradient
%{
subplot(1,1,1)
scatter(central,measureVals)
ylim([mean(measureVals)-.1 mean(measureVals)+.1])
%}
%% 



% %% expand
% [y x] = find(field == 0);
% for i = 1:length(y)
%    dists = sqrt((qualX - x(i)).^2 + (qualY - y(i)).^2); 
%    targ = find(dists == min(dists),1);
%    field(y,x) = qualVals(targ);
%     if ~(mod(i,fsize))
%         disp([ num2str(i/length(y)*100) '% finished'])
%     end
%     
% end
% 
