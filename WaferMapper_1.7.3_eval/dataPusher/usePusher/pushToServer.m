%function[] = moveSectionsThroughBuffer()

%% Set directories
TPN = 'X:\joshm\LGNs1\rawMontages\'; %target
SPN = 'D:\LGNs1\rawMontages_folder2\'; %source
GPN = 'C:\Documents and Settings\Administrator\My Documents\Google Drive\logBooks\'; %google drive

%%  Select actions
ClearScope = 0;  %Copy then delete finished sections
CopyScope = 0;  %Copy all data from scope to buffer
CopyBuffer = 1; %Copy data from buffer to server
CopyLog = 0; %Copy data log to server and gdrive
ignoreMemory = 0;

%% Timing variables
delayBetweenChecksForFinishedSectionsInMinutes = 1000;
delaySecCheckDays = delayBetweenChecksForFinishedSectionsInMinutes/60/24;

%%
while 1
    pause(1)
    disp('Moving files from Buffer to Server')
    ignoreMemory =0;
    pushFolders(SPN,TPN,ignoreMemory);
    
end