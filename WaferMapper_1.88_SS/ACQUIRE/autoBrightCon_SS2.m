%function[] = autoBrightCon()

global GuiGlobalsStruct
MyCZEMAPIClass = GuiGlobalsStruct.MyCZEMAPIClass;
tic
%% Set up Variables
%DwellTimeInMicroseconds = GuiGlobalsStruct.MontageParameters.TileDwellTime_microseconds;
MyCZEMAPIClass.Set_PassedTypeSingle('AP_BRIGHTNESS',newBright);
MyCZEMAPIClass.Set_PassedTypeSingle('AP_CONTRAST',newCon);
DwellTimeInMicroseconds = .1;
FileName = 'C:\temp\tempBC.tif';
MyCZEMAPIClass.Fibics_WriteFOV(FOV_microns); %Always set the FOV even if you are overriding with mag (might be used in some way inside Fibics)
pause(0.1); %1

%% Get first brigh/con
firstBrightness =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_BRIGHTNESS');
firstContrast =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_CONTRAST');
newBright = firstBrightness;
newCon = firstContrast;
imagePix = 1024;
lowThresh = .1; %percent allowed to saturate
highThresh = .1; %percent allowed to saturate
changeBright = 1;
changeCon = 1;
lastChangeCon = 0;
lastChangeBright = 0;

fprintf('\n');
fprintf('AutoBC on Tiles\n');
%% Start checking contrast
for r = 1:50
    
    if rem(r,10)==0
        fprintf('...\n');
    end
    
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
    
    %bar(histI),pause(.01)
    if r==30
        pause(.1)
    end
    numLow = sum(histI(1:2));
    numHigh = sum(histI(end-1:end));
    numGoodLow = sum(histI(3:10));
    numGoodHigh = sum(histI(end-9:end-2));
    medI = median(I(:));
    stdI = std(I(:));
    
    GuiGlobalsStruct.autoBrightCon_Values{GuiGlobalsStruct.autoBrightCon_SS2Counter2,1}(GuiGlobalsStruct.autoBrightCon_SS2Counter,1) = numLow;
    GuiGlobalsStruct.autoBrightCon_Values{GuiGlobalsStruct.autoBrightCon_SS2Counter2,1}(GuiGlobalsStruct.autoBrightCon_SS2Counter,2) = numHigh;
    GuiGlobalsStruct.autoBrightCon_Values{GuiGlobalsStruct.autoBrightCon_SS2Counter2,1}(GuiGlobalsStruct.autoBrightCon_SS2Counter,3) = numGoodLow;
    GuiGlobalsStruct.autoBrightCon_Values{GuiGlobalsStruct.autoBrightCon_SS2Counter2,1}(GuiGlobalsStruct.autoBrightCon_SS2Counter,4) = numGoodHigh;
    GuiGlobalsStruct.autoBrightCon_SS2Counter = GuiGlobalsStruct.autoBrightCon_SS2Counter+1;
    
    tooLow = numLow > 5;
    tooHigh = numHigh > 5;
       
    if tooLow & tooHigh %reduceContrast
        
        if lastChangeCon == 1
            changeCon = changeCon/2;
        end
        fprintf('C-|');
        newCon = newCon-changeCon;
        newBright = newBright - changeCon/4;
        lastChangeCon = -1;
        %lastChangeBright = 0;
    elseif tooLow
        if lastChangeBright == -1
            changeBright = changeBright/2;
        end
        fprintf('H+|');
        newBright = newBright + changeBright;
        lastChangeBright = 1;
        %lastChangeCon = 0;
    elseif tooHigh
        if lastChangeBright == 1
            changeBright = changeBright/2;
        end
        fprintf('B-|');
        newBright = newBright - changeBright;
        lastChangeBright = -1;
        %lastChangeCon = 0;
    else
        if lastChangeCon == -1
            changeCon = changeCon/2;
        end
        passLow = (numGoodLow) > 5;
        passHigh = (numGoodHigh) > 5;
        if passLow & passHigh & ~tooHigh & ~tooLow
            fprintf('passed');
            GuiGlobalsStruct.autoBrightCon_SS2Counter2 = GuiGlobalsStruct.autoBrightCon_SS2Counter2+1;
            break
        end
        
        fprintf('C+|');
        newCon = newCon+changeCon;
        newBright = newBright + changeCon/4;
        lastChangeCon = 1;
        %lastChangeBright = 0;
    end
    
    MyCZEMAPIClass.Set_PassedTypeSingle('AP_BRIGHTNESS',newBright);
    MyCZEMAPIClass.Set_PassedTypeSingle('AP_CONTRAST',newCon);
end %image again

if r==50
    fprintf('AutoBC reached 50 iterations.');
end
fprintf('\n');
toc;
fprintf('\n');