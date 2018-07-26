global GuiGlobalsStruct; % WaferMapper global variable
sm = GuiGlobalsStruct.MyCZEMAPIClass; %To shorten calls to global API variables in this function


%get starting WD and Stig
currentWorkingDistance = sm.Get_ReturnTypeSingle('AP_WD');
currentStigX = sm.Get_ReturnTypeSingle('AP_STIG_X');
currentStigY = sm.Get_ReturnTypeSingle('AP_STIG_Y');

disp(['starting values: ' num2str(10^6*currentWorkingDistance) 'um, ' num2str(currentStigX) '%, ' num2str(currentStigY) '%']);

% image paramaters

imageWidthInPixels = 1024; % in pixels
imageHeightInPixels = 728; % in pixels
dwellTimeInMicroseconds = 0.5; % in us
FOV = 29 ; % in mm
frametime=1; % in seconds
imageDirectory = 'F:\PNI-Images\Ashwin\FocTest';
focusRange = -2:0.25:2;
workingRange = zeros(1,length(focusRange));

%acquire image

for i= 1:length(focusRange)  
newWorkingDistance  = currentWorkingDistance+10^-6*focusRange(i);
sm.Set_PassedTypeSingle('AP_WD',newWorkingDistance); %apply first test aberration
pause(frametime);
% T1WD=sm.Get_ReturnTypeSingle('AP_WD');
% if verbosity
%     disp(['first image WD: ' num2str(10^6*T1WD) 'um']);
% end
sm.Fibics_WriteFOV(FOV);
fileName = fullfile(imageDirectory,sprintf('TestImage%d.tif',i));
workingRange(1,i) = newWorkingDistance;
%Wait for image to be acquired
sm.Fibics_AcquireImage(imageWidthInPixels,imageHeightInPixels,dwellTimeInMicroseconds,fileName);
while(sm.Fibics_IsBusy)
    pause(.01); %1
end

%Wait for file to be written
IsReadOK = false;
while ~IsReadOK
    IsReadOK = true;
    try
        I1 = imread(fileName);
    catch MyException
        IsReadOK = false;
        pause(0.1);
    end
end

%delete(fileName); % for some reason, deleting image seemed to be necessary

end

save(fullfile(imageDirectory,'workingDistanceRange.mat'),'workingRange');
save(fullfile(imageDirectory,'currentParamaters.mat'),'currentWorkingDistance','currentStigX','currentStigY','FOV');


