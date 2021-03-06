function [  ] = PerformPixelToStageCalibration_YDirOnly(handles)
global GuiGlobalsStruct;

disp('Turning stage backlash ON in X and Y');
GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeString('DP_X_BACKLASH','+ -');
GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeString('DP_Y_BACKLASH','+ -');
GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeString('DP_STAGE_BACKLASH', GuiGlobalsStruct.backlashState);

%to do: actual calibration stuff




ImageFileNameStr = sprintf('%s\\PixelToStageCalibrationImage.tif',GuiGlobalsStruct.PixelToStageCalibrationDirectory);
disp(sprintf('Loading file: %s', ImageFileNameStr));
%BaseImage = imread(ImageFileNameStr, 'tif');
ImageInfoFileNameStr = [ImageFileNameStr(1:end-4), '.mat'];
disp(sprintf('Loading file: %s', ImageInfoFileNameStr));
load(ImageInfoFileNameStr, 'Info');
% Info = 
%                 FOV_microns: 4096
%             ReadFOV_microns: 4.0460e+003
%          ImageWidthInPixels: 4096
%               StageX_Meters: 0.0596
%               StageY_Meters: 0.0598
BaseImage_StageX_Meters = Info.StageX_Meters;
BaseImage_StageY_Meters = Info.StageY_Meters;
%ReadFOV_microns = 2000;
%ImageWidthInPixels = 2048;
 ReadFOV_microns = Info.ReadFOV_microns;
 ImageWidthInPixels = Info.ImageWidthInPixels;

% BaseImage = uint8(zeros(ImageWidthInPixels,ImageWidthInPixels));
% BaseImage_ShiftedInY =uint8(zeros(ImageWidthInPixels,ImageWidthInPixels));
BaseImage = imread(ImageFileNameStr, 'tif');


%%%%
 [MaxR, MaxC] = size(BaseImage);
% ScaleFactorC=4;
 %ScaleFactorR=4;
 LHS =floor(MaxC/2-MaxC/(8));
 RHS =floor(MaxC/2+MaxC/(8));
% Top =floor(MaxR/2-MaxR/(2*ScaleFactorR));
% Bottom =floor(MaxR/2+MaxR/(2*ScaleFactorR));
 WidthImage=RHS-LHS;
% Height=Bottom-Top; 
% 
% 
 BaseImage1=imcrop(BaseImage,[LHS 1 WidthImage-1 MaxR-1]);
 clearvars BaseImage
% 
 figure
 imshow(BaseImage1);
%%%%

% figure
% imshow(BaseImage);

ImageFileNameStr_ShiftedInY = [ImageFileNameStr(1:end-4), '_ShiftedInY.tif'];
disp(sprintf('Loading file: %s', ImageFileNameStr_ShiftedInY));
BaseImage_ShiftedInY = imread(ImageFileNameStr_ShiftedInY, 'tif'); 

%%%%
 %[MaxR, MaxC] = size(BaseImage_ShiftedInY);
% ScaleFactorC=4;
% ScaleFactorR=4;
 LHS =floor(MaxC/2-MaxC/(8));
 RHS =floor(MaxC/2+MaxC/(8));
% Top =floor(MaxR/2-MaxR/(2*ScaleFactorR));
% Bottom =floor(MaxR/2+MaxR/(2*ScaleFactorR));
 WidthImage=RHS-LHS;
% Height=Bottom-Top; 
% 
% 
 BaseImage_ShiftedInY1=imcrop(BaseImage_ShiftedInY,[LHS 1 WidthImage-1 MaxR-1]);
 clearvars BaseImage_ShiftedInY
%%%%


 figure
 imshow(BaseImage_ShiftedInY1);

% figure
% imshow(BaseImage_ShiftedInY);

ImageInfoFileNameStr = [ImageFileNameStr_ShiftedInY(1:end-4), '.mat'];
disp(sprintf('Loading file: %s', ImageInfoFileNameStr));
load(ImageInfoFileNameStr, 'Info');
BaseImage_ShiftedInY_StageX_Meters = Info.StageX_Meters;
BaseImage_ShiftedInY_StageY_Meters = Info.StageY_Meters;

h_fig = figure;
%[MaxR, MaxC] = size(BaseImage);
QuarterImageHeightPixels = floor(MaxR/4);
YPixelShiftArray = QuarterImageHeightPixels + (-95:95); %KH changed from: QuaterImageWidthPixels + (-50:50);
for i = 1:length(YPixelShiftArray)
    
    
    Im(:,:,1) = BaseImage1(1:2*QuarterImageHeightPixels, :);
    Im(:,:,2) = BaseImage_ShiftedInY1((YPixelShiftArray(i)+1):(YPixelShiftArray(i)+2*QuarterImageHeightPixels), :);
    Im(:,:,3) = 0*Im(:,:,1);
    
    Im1 = double(Im(:,:,1));
    clearvars Im(:,:,1);
    Im2= double(Im(:,:,2));
    clearvars Im(:,:,2);
    
    
    
    subplot(1,2,1);
    imshow(Im);
    
    
    ImageDifference(i) = sum(sum(abs(Im1 - Im2)));
    
    subplot(1,2,2);
    plot(ImageDifference);
    drawnow;
    pause(.1);
end

[dummy, IndexOfMin] = min(ImageDifference)

YPixelShift = YPixelShiftArray(IndexOfMin)
YStageShift_Microns = (BaseImage_ShiftedInY_StageY_Meters - BaseImage_StageY_Meters)*1000000

MicronsPerPixel_FromCalibration = -YStageShift_Microns/YPixelShift; %Note negative sign
disp(sprintf('MicronsPerPixel_FromCalibration = %0.5g', MicronsPerPixel_FromCalibration));
MicronsPerPixel_FromFibicsReadFOV = ReadFOV_microns/ImageWidthInPixels;
disp(sprintf('MicronsPerPixel_FromFibicsReadFOV = %0.5g', MicronsPerPixel_FromFibicsReadFOV));
PercentDifference = 100*((MicronsPerPixel_FromCalibration/MicronsPerPixel_FromFibicsReadFOV)-1);
disp(sprintf('PercentDifference = %0.5g', PercentDifference));

CalibrationFileNameStr = sprintf('%s\\CalibrationFile.mat',GuiGlobalsStruct.PixelToStageCalibrationDirectory);
save(CalibrationFileNameStr, 'MicronsPerPixel_FromCalibration', 'MicronsPerPixel_FromFibicsReadFOV');


MyStr = sprintf('Calibration Results: \n  um/pix (from calibration) = %0.5g\n  um/pix (from Fibics) = %0.5g\n  Percent difference = %0.5g%%',...
    MicronsPerPixel_FromCalibration, MicronsPerPixel_FromFibicsReadFOV, PercentDifference);
uiwait(msgbox(MyStr,'modal'));

if ishandle(h_fig)
    close(h_fig);
end

end

