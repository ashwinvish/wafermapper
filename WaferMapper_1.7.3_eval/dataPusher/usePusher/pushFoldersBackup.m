%function[allGood] = pushFolders(SPN,TPN,delaySecCheckDays,lastCheckTime)
%%Make sure all files in SPN are present and updated in TPN.
%%maxCheckTime in minutes of time allowed for this function



if ~exist('delaySecCheckDays','var')
    delaySecCheckDays = 1000000; %1000 minutes
end


if ~exist(TPN,'dir') | ~exist(SPN,'dir')
    disp(error('missing directory'))
end

if ~exist(TPN,'dir')
    mkdir(targetFold)
end

memFileName = [SPN 'recordDataTransfer.mat']

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
disp(APN)
disp('Gathering File information')

pull.sourceDir = SPN;

for f = 1: length(APN)  %run through every found folder
    sourceFolder = APN{f};
    targetFolder = [TPN sourceFolder(startFoldName:end)];
    pull.t(f).Folder = targetFolder;
    pull.f(f).Folder = sourceFolder;
    dAPN = dir(APN{f}); dAPN = dAPN(3:end);
    noDir = ~[dAPN.isdir];
    aFiles = dAPN(noDir);
    
    pull.f(f).Names = {aFiles.name}';
    pull.f(f).Sizes = [aFiles.bytes]';
    pull.f(f).Times = [aFiles.datenum]';
    pull.f(f).lastChange = max([aFiles.datenum]);
end

dirAnalysisStop = datenum(clock);
dirAnalysisTime = (dirAnalysisStop - dirAnalysisStart) * 24 * 60 * 60;
disp(['Analysis of ' SPN ' took ' num2str(dirAnalysisTime) ' seconds.'])

%% Get memory
if 0%exist(memFileName,'file')
    load(memFileName)
else
    mem = pull;
end
numAlreadyCopied = 0;
%%  Start Checking

for f = 1:length(pull.f)
      %%Time out search
                if (datenum(clock)-startCheckTime)>delaySecCheckDays
                    disp(sprintf('Timed out with %d of %d files copied.',i,length(allNams)))
                    break , end %return to looking for new sections
                
    if (length(pull.f(f).Times)) == (length(pull.f(f).Names))
        
        if exist('mem','var')  %if there is a remembered transfer
            memF = find(strcmp({mem.f.Folder}',pull.f(f).Folder)); %get folder id for mem
        else
            memF = []
        end
        
        for i = 1 : length(pull.f(f).Names)
            %%find remembered directory
            
            source = [pull.f(f).Folder '\' pull.f(f).Names{i}];
            dest = [TPN source(startFoldName:end)];
            
            
            %% Check memory to see if file of right size and time has already been copied
            alreadyCopied = 0;
            if ~isempty(memF) % if folder is remembered
                if strcmp(mem.t(memF).Folder,pull.t(f).Folder); %if same target folder
                    memT = find(strcmp(mem.f(memF).Names,pull.f(f).Names(i)));  %find the name
                    if ~isempty(memT) %if file is remembered
                        %% Start selection
                        if isfield(mem.t(memF),'Success')
                        if ~isempty(mem.t(memF).Success)
                            if mem.t(memF).Success(memT) %if previous copy was reported succesful
                                if mem.t(memF).Sizes(memT) == pull.f(f).Sizes(i)
                                    if mem.t(memF).Times(memT) >= pull.f(f).Times(i);
                                        alreadyCopied = 1;
                                    end
                                end
                            end
                        end
                    end
                end
                end
            end
            
            if ~alreadyCopied
                
                
              
                %%Check destination to see if shouldCopy
                shouldCopy = 0;
                if ~exist(dest,'file')
                    shouldCopy = 1;
                    disp(sprintf('create new file %s', dest))
                else  %if file exists
                    fileInfo = dir(dest);
                    fileInfo = fileInfo(end);
                    
                    %%%%ERROR%%%
                    if fileInfo.datenum< pull.f(f).Times(i) %replace old file
                        shouldCopy = 1;
                        disp(sprintf('replace old file %s', dest))
                    elseif (fileInfo.bytes ~= pull.f(f).Sizes(i)); %replace partial file
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
                        
                    else %if copy was a success
                        pull.t(f).Success(i) = 1;%if previous copy was reported succesful
                        pull.t(f).Sizes(i) = pull.f(f).Sizes(i);
                        pull.t(f).Times(i) = pull.f(f).Times(i);
                        
                        if ( pull.f(f).Sizes(i)/1000000)<1
                            disp('Copy succeded')
                        else
                            disp(sprintf('%.1f MB copied at %.1f MB/sec',...
                                 pull.f(f).Sizes(i)/1000000, pull.f(f).Sizes(i)/1000000/copySeconds))
                        end
                    end
                    
                    
                else
                    pull.t(f).Success(i) = 1;%if previous copy was reported succesful
                    pull.t(f).Sizes(i) = fileInfo.bytes;
                    pull.t(f).Times(i) = fileInfo.datenum;
                end
                
            else %if already copied
                numAlreadyCopied = numAlreadyCopied +1;
                if ~mod(numAlreadyCopied,100)
                    disp(sprintf(' %d files were already copied.',numAlreadyCopied))
                end
            end
    end %run all files in folder
    
    
    end %if all information is same length
    
    %% save mem after each folder?
    if isempty(memF)
        mem.f(length(mem.f)+1) = pull.f(f);
        mem.t(length(mem.f)) = pull.t(f);
    else
        mem.f(memF) = pull.f(f); % Remember step.
        mem.t(memF) = pull.t(f);
    end
    safesave(memFileName,'mem');
    
    
    
end %run all folders

disp('Full check finished')
                    disp(sprintf(' %d files were already copied.',numAlreadyCopied))

if noNew
    disp(sprintf('No new files found after full check at %s', datestr(clock)))
else
    disp(sprintf('New files found after full check at %s', datestr(clock)))
end

%% finalize memory if function completes
mem = pull;
safesave(memFileName,'mem');


