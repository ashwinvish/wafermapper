%function[allGood] = shortPush(SPN,TPN,delaySecCheckDays,lastCheckTime)
%%Make sure all files in SPN are present and updated in TPN.
%%maxCheckTime in minutes of time allowed for this function



if ~exist('delaySecCheckDays','var')
    delaySecCheckDays = 1000000; %1000 minutes
end


if ~exist(TPN,'dir') | ~exist(SPN,'dir')
    disp(error('missing directory'))
end




%% invarient Variables
delayCopySeconds = 120;  %Seconds between reading directories and starting file copy
delayCopyDays = delayCopySeconds/60/60/24;

%secondsBetweenFullCheck = 120;
%daysBetweenFullCheck = secondsBetweenFullCheck/60/60/24;




%% Read source folder

startFoldName = length(SPN) + 1;
startCheckTime =  datenum(clock);%record time at first read

%Update after first run through
currentCheckTime =  datenum(clock);
allGood = 1;
noNew = 1;

%% Read source folder
dirAnalysisStart = datenum(clock);
disp('Finding folders')
APN = findFolders(SPN); % find all folders in source directory
allNams =  {}; allTimes = []; allFolders = {}; allSizes = [];  %initialize empty lists
disp(APN)
disp('Gathering File information')
for f = 1: length(APN)  %run through every found folder
    
    dAPN = dir(APN{f}); dAPN = dAPN(3:end);
    noDir = ~[dAPN.isdir];
    aFiles = dAPN(noDir);
    
    allNams = [allNams; {aFiles.name}'];
    allTimes = [allTimes; [aFiles.datenum]'];
    allSizes = [allSizes; [aFiles.bytes]'];
    fID = ones(length(aFiles),1) * f;
    allFolders = cat(1,allFolders,APN(fID));
end

L = length(allNams);
dirAnalysisStop = datenum(clock);
dirAnalysisTime = (dirAnalysisStop - dirAnalysisStart) * 24 * 60 * 60;
disp(['Analysis of ' SPN ' took ' num2str(dirAnalysisTime) ' seconds.'])

%% Record newPush structure
newPush.startCheckTime = startCheckTime;
newPush.sourceDirectory = SPN;
newPush.targetDirectory = TPN;
newPush.allNams = allNams;
newPush.allTimes = allTimes;
newPush.allSizes = allSizes;
newPush.allFolders = allFolders;
newPush.finished = ones(length(allNams),1);


%%
if (length(allTimes)==L) & ( length(allSizes)==L) & ( length(allFolders)==L)
    
    
    
    %% Run full check
    
    disp('Running full check for directory match')
    
    for i = 1:length(allNams)
        
        %%Make sure file is not too recent
        if (datenum(clock)-startCheckTime)>delaySecCheckDays
            disp(sprintf('Timed out with %d of %d files copied.',i,length(allNams)))
            break , end %return to looking for new sections
        
        
        
        
        
        
        
        
        %%Prepare directory for copying
        source = [allFolders{i} '\' allNams{i}];
        dest = [TPN source(startFoldName:end)];
        targetFold = allFolders{i};
        targetFold = [TPN targetFold(startFoldName:end)];
        if ~exist(targetFold,'dir')
            mkdir(targetFold)
        end
        
        %%Check destination to see if shouldCopy
        shouldCopy = 0;
        if ~exist(dest,'file')
            shouldCopy = 1;
            disp(sprintf('create new file %s', dest))
        else  %if file exists
            fileInfo = dir(dest);
            fileInfo = fileInfo(end);
            
            %%%%ERROR%%%
            if fileInfo.datenum<allTimes(i) %replace old file
                shouldCopy = 1;
                disp(sprintf('replace old file %s', dest))
            elseif (fileInfo.datenum == allTimes(i) ) & ...
                    (fileInfo.bytes < allSizes(i)); %replace partial file
                disp(sprintf('replaced partial file %s', dest))
            else % if overwrite
                %disp(sprintf('%s exists', dest))
            end
        end %whether dest file exists
        
        if shouldCopy %copy if you should
            status = 0;
            noNew = 0;
            startCopy = datenum(clock);
            for c = 1:3
                status = copyfile(source,dest); %copy the file
                if status ~= 0  %make sure copy succeded
                    break
                end
                pause(1)
            end %i status is bad
            stopCopy = datenum(clock);
            copySeconds = (stopCopy-startCopy)*24*60*60;
            
            if status ==0
                disp('Failed to copy')
                allGood = 0;
            elseif (allSizes(i)/1000000)<1
                disp('Copy succeded')
            else
                disp(sprintf('%.1f MB copied at %.1f MB/sec',...
                    allSizes(i)/1000000,allSizes(i)/1000000/copySeconds))
            end
        end
    end       %run all file names
    disp('Full recheck finished')
    if noNew
        disp(sprintf('No new files found after full check at %s', datestr(clock)))
    else
        disp(sprintf('New files found after full check at %s', datestr(clock)))
    end
    
    
    
end %if all information is same length


