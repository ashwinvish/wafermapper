%function[] = autoBrightCon()

fprintf('AutoBC for Focus...');
global GuiGlobalsStruct
MyCZEMAPIClass = GuiGlobalsStruct.MyCZEMAPIClass;
%% Set up Variables
%DwellTimeInMicroseconds = GuiGlobalsStruct.MontageParameters.TileDwellTime_microseconds;
DwellTimeInMicroseconds = .1;
FileName = 'C:\temp\tempBC.tif';
MyCZEMAPIClass.Fibics_WriteFOV(FOV_microns); %Always set the FOV even if you are overriding with mag (might be used in some way inside Fibics)
pause(0.1); %1

%% Get first brigh/con
firstBrightness =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_BRIGHTNESS');
firstContrast =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_CONTRAST');
NewBrightnessForFocus = firstBrightness;
NewContrastForFocus = firstContrast;
imagePix = 1024;
lowThresh = .1; %percent allowed to saturate
highThresh = .1; %percent allowed to saturate
changeBright = 2;
changeCon = 2;
lastChangeCon = 0;
lastChangeBright = 0;

GuiGlobalsStruct.MyCZEMAPIClass.Fibics_AcquireImage(imagePix,imagePix,DwellTimeInMicroseconds,FileName);
while(MyCZEMAPIClass.Fibics_IsBusy)
    pause(.1); %1
end

try
    I = double(imread(FileName));
catch err
end

%%Analyze Pic
histI = hist(I(:),0:1:254);

%bar(histI),pause(.01)
histI2 = histI/max(histI);
[val,loc] = max(histI2);

%% Start checking contrast
while loc > 5;
    
    if loc<75
        changeCon=1;
    elseif loc<30
        changeCon=.5;
    elseif loc<15
        changeCon=.25;
    end
        
    NewContrastForFocus=NewContrastForFocus+changeCon;
    NewBrightnessForFocus=NewBrightnessForFocus+changeCon/8;
    
    MyCZEMAPIClass.Set_PassedTypeSingle('AP_BRIGHTNESS',NewBrightnessForFocus);
    MyCZEMAPIClass.Set_PassedTypeSingle('AP_CONTRAST',NewContrastForFocus);
    
    %%Get Pic
    GuiGlobalsStruct.MyCZEMAPIClass.Fibics_AcquireImage(imagePix,imagePix,DwellTimeInMicroseconds,FileName);
    while(MyCZEMAPIClass.Fibics_IsBusy)
        pause(.1); %1
    end
    
    try
        I = double(imread(FileName));
    catch err
    end
    
    %%Analyze Pic
    histI = hist(I(:),0:1:254);    
    histI2 = histI/max(histI);
    [val,loc] = max(histI2(5:251));
end %image again
fprintf(' done.\n\n');