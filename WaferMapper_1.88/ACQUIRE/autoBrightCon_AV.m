global GuiGlobalsStruct
MyCZEMAPIClass = GuiGlobalsStruct.MyCZEMAPIClass;
tic
%% Set up Variables
%DwellTimeInMicroseconds = GuiGlobalsStruct.MontageParameters.TileDwellTime_microseconds;
DwellTimeInMicroseconds = .1;
FOV_microns = GuiGlobalsStruct.MontageParameters.TileFOV_microns;
FileName = 'C:\temp\tempBC.tif';
MyCZEMAPIClass.Fibics_WriteFOV(FOV_microns); %Always set the FOV even if you are overriding with mag (might be used in some way inside Fibics)
pause(0.1); %1

%% Get first brigh/con
firstBrightness =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_BRIGHTNESS');
firstContrast =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_CONTRAST');
newBright = firstBrightness;
newCon = firstContrast;
imagePix = 1024;
lowThresh = .01; %percent allowed to saturate
highThresh = .01; %percent allowed to saturate
changeBright = .5;
changeCon = .5;
lastChangeCon = 0;
lastChangeBright = 0;
