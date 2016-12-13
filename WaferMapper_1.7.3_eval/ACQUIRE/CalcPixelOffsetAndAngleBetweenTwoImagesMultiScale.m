function [XOffsetOfNewInPixels, YOffsetOfNewInPixels, AngleOffsetOfNewInDegrees, FigureOfMerit] = ...
    CalcPixelOffsetAndAngleBetweenTwoImagesMultiScale(OriginalImage, NewImage, CenterAngle, AngleIncrement, NumMultiResSteps)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

%[XOffsetOfNewInPixels, YOffsetOfNewInPixels, AngleOffsetOfNewInDegrees] = DetermineAlignmentUsingSIFT(OriginalImage, NewImage);

%fill in default parameters if not supplied by calling function
if nargin < 5
    CenterAngle = 0; %always start at 0 deg
    AngleIncrement = .5;%4; %degrees    
    NumMultiResSteps = 3;   %Example [-4 0 +4] -> [-2 0 +2] -> [-3 -2 -1] -> [-2.5 -2 -1.5] -> found angle = -1.5deg
end


[HeightImage, WidthImage] = size(OriginalImage);
[HeightImageNew, WidthImageNew] = size(NewImage);
if (HeightImageNew ~= HeightImage) || (WidthImageNew ~= WidthImage) || (HeightImage ~= WidthImage)
   disp('Images must be the same size and be square. Quiting...');
end

ScaleFactor = 1/(2^(NumMultiResSteps-1)); %(1/8), (1/4), (1/2), (1)



    
for MultiResStepIndex = 1:NumMultiResSteps
    %B = IMRESIZE(A, [NUMROWS NUMCOLS])
    
    ScaleFactor = 1/(2^(NumMultiResSteps+-MultiResStepIndex)); 
    UseAngleIncrement = AngleIncrement * 2^(NumMultiResSteps - MultiResStepIndex);
    
    OriginalImageDownsampled =...
        imresize(OriginalImage,[HeightImage*ScaleFactor, WidthImage*ScaleFactor],'bilinear');
    NewImageDownsampled =...
        imresize(NewImage,[HeightImage*ScaleFactor, WidthImage*ScaleFactor],'bilinear');
  
    if MultiResStepIndex == 1
         AnglesInDegreesToTryArray = [UseAngleIncrement:UseAngleIncrement:360];
    else 
        AnglesInDegreesToTryArray = UseAngleIncrement * [-4:1:4] + CenterAngle;
    end
    
    disp(sprintf('Increment = %2.2f, Range = %3.2f to %3.2f',UseAngleIncrement,AnglesInDegreesToTryArray(1),AnglesInDegreesToTryArray(end)))
    [XOffsetOfNewInPixels, YOffsetOfNewInPixels, AngleOffsetOfNewInDegrees, FigureOfMerit] =...
        CalcPixelOffsetAndAngleBetweenTwoImages_UsingOriginal(OriginalImageDownsampled, NewImageDownsampled, AnglesInDegreesToTryArray); %NOTE: just take FIgureOfMerit of last
   
    
    %Prepare for next cycle centered on the found angle
    CenterAngle = AngleOffsetOfNewInDegrees;
end






%Note: Returns [XOffsetOfNewInPixels, YOffsetOfNewInPixels,
%AngleOffsetOfNewInDegrees] from last iteration of above loop


end

