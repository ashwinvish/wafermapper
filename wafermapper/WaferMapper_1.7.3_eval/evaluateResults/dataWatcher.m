

waferName = 'w008'

SPN =  'D:\LGNs1\rawMontages_SecondRetake\'
TPN = 'D:\LGNs1\Processed_SecondRetakes\'
if ~exist(TPN,'dir'),mkdir(TPN),end
checkWaferQuality(SPN,TPN,waferName)
% 
% 
% SPN =  'L:\joshm\LGNs1\rawMontages\'
% TPN = 'D:\LGNs1\Processed\'
% if ~exist(TPN,'dir'),mkdir(TPN),end
% checkWaferQuality(SPN,TPN,waferName)




%{

SPN = 'Z:\joshm\LGNs1\rawMontages\'
TPN = 'Z:\joshm\LGNs1\Processed\'
bookDir = [SPN 'LogBooks\'];
gDrive = 'C:\Users\View192\Google Drive\logBooks\'

bookName = ['LogBook_' waferName];
%%
while 1

%% Summarize logBook and write to excel    
logSec2Excel(bookDir, bookName);

%% Copy logBook to google drive
success = 0;
while ~success
    [success message] = copyfile([bookDir bookName '.mat'],[gDrive bookName '.mat'])
    pause(.1)
end
pause(3)

success = 0;
while ~success
    [success message] = copyfile([bookDir bookName '.xls'],[gDrive bookName '.xls'])
    pause(.1)
end

%% collect quality images
checkWaferQuality(SPN,TPN,waferName)
checkWaferStitching(SPN,TPN,waferName)


pause(5)
end
%}