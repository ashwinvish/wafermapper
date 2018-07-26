%function[] = autoBrightCon()

global GuiGlobalsStruct
MyCZEMAPIClass = GuiGlobalsStruct.MyCZEMAPIClass;
tic
%% Set up Variables
%DwellTimeInMicroseconds = GuiGlobalsStruct.MontageParameters.TileDwellTime_microseconds;
MyCZEMAPIClass.Set_PassedTypeSingle('AP_BRIGHTNESS',53);
MyCZEMAPIClass.Set_PassedTypeSingle('AP_CONTRAST',25);
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
fprintf('AutoBC before Focus\n');
%% Start checking contrast
for r = 1:75
    
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
    numLow = sum(histI(1:3));
    numHigh = sum(histI(end-2:end));
    numGoodLow = sum(histI(4:10));
    numGoodHigh = sum(histI(end-9:end-3));
    medI = median(I(:));
    stdI = std(I(:));
    
    tooLow = numLow > 5;
    tooHigh = numHigh > 5;
       
    if tooLow & tooHigh %reduceContrast
        
        if lastChangeCon == 1
            changeCon = changeCon/2;
        end
        fprintf('C-|');
        newCon = newCon-changeCon;
        newBright = newBright - changeCon;
        lastChangeCon = -1;
        %lastChangeBright = 0;
    elseif tooLow
        if lastChangeBright == -1
            changeBright = changeBright;
        end
        fprintf('B+|');
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

if r==75
    fprintf('AutoBC reached 75 iterations.');
end
fprintf('\n');
toc;
fprintf('\n');