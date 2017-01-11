% script to acquire images at multiple dewll times
% used for testing new PulseTor detector

global GuiGlobalsStruct
Directory = uigetdir('F:\PNI-Images\Ashwin\11082016\042616-4-SNRImages');
FOV_microns = 11.99; % 3nm; in microns 325.0
ImageWidthInPixels = 4000; % Images size in pixels
ImageHeightInPixels = 4000;
DwellTimeInMicroseconds = [0.1;0.5;0.8; 1; 1.2;1.5 ; 2]; % range of dewll times
IsDoAutoRetakeIfNeeded = false;
IsMagOverride = false;
MagForOverride = -1;
WaferNameStr = 'PostStained'; 
%LayerThickness = '1nm-Pl-Pd';
LabelStr = '141';
EHT = '5kV-ZeissMerlin-4na-3nm';
WD = '6400'; % in microns
imageno = 1;
%clear imageno ;
%MontageDirName = sprintf('%s\\%s\\%s', Directory,EHT,LayerThickness);
MontageDirName = sprintf('%s\\%s\\', Directory,EHT);
disp(sprintf('Creating directory: %s',MontageDirName));
[success,message,messageid] = mkdir(MontageDirName);
%imageno = length(DwellTimeInMicroseconds);
for imageno = 1:length(DwellTimeInMicroseconds)
    disp(sprintf('Creating File: %s\\%03d_SNRImage_%s_%s_%s.tif', MontageDirName,imageno, EHT, WD ,num2str(DwellTimeInMicroseconds(imageno)*1000 )));
    ImageFileNameStr = sprintf('%s\\%03d_SNRImage_%s_%s_%s.tif', MontageDirName,imageno, EHT, WD ,num2str(DwellTimeInMicroseconds(imageno)*1000));
    Fibics_AcquireImage(ImageWidthInPixels, ImageHeightInPixels, DwellTimeInMicroseconds(imageno), ImageFileNameStr,...
        FOV_microns, IsDoAutoRetakeIfNeeded, IsMagOverride, MagForOverride, WaferNameStr, LabelStr);
    pause(1);
    %imageno = length(DwellTimeInMicroseconds) - temp ;
end