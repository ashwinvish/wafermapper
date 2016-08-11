function[] = AlignWafers_Automatic()

global GuiGlobalsStruct


GuiGlobalsStruct.IsUserCancelWaitBar = false;
GuiGlobalsStruct.h_waitbar = waitbar(0,'Aligning sections...',  'WindowStyle' , 'modal', 'CreateCancelBtn', 'UserCancelWaitBar();');

autoScale = 0; %1 to run auto scale on each wafer
WaferList = GuiGlobalsStruct.ListOfWaferNames;
listImages = [];
disp('Reading all wafer averages')
for w = 1:length(WaferList)
    
    averageOverviewAlignment = [GuiGlobalsStruct.UTSLDirectory '\' WaferList{w} ...
        '\' 'SectionOverviewTemplateDirectory\averageAlignedOverviews.tif'] ;
    waferAlignedAverageOverview = [GuiGlobalsStruct.UTSLDirectory '\' WaferList{w} ...
        '\' 'SectionOverviewTemplateDirectory\waferAlignedAverageOverview.tif'] ;
    Inams{w} = averageOverviewAlignment;
    newInams{w} = waferAlignedAverageOverview;
    
    if exist(averageOverviewAlignment,'file') 
        
        allI{w} = imread(averageOverviewAlignment);
        dummyI = allI{w};
%         unShiftName = [GuiGlobalsStruct.UTSLDirectory '\' WaferList{w} ...
%         '\' 'SectionOverviewTemplateDirectory\averageAlignedOverviewsUnshifted.tif'];
%         if ~exist(unShiftName,'file')
%             imwrite(allI{w},[GuiGlobalsStruct.UTSLDirectory '\' WaferList{w} ...
%             '\' 'SectionOverviewTemplateDirectory\averageAlignedOverviewsUnshifted.tif'],'Compression','none');
%         end
        listImages(length(listImages)+1) = w;
    else
        allI{w} = dummyI*.1;
        disp(['MISSING SECTION ' averageOverviewAlignment])
    end

end %run all wafers


%choose reference wafer
startWafer = listImages(fix(length(listImages)/2)+1);
useRef = [startWafer : length(listImages)-1 startWafer: -1:2];
useMove = [startWafer + 1 : length(listImages) startWafer - 1 :-1: 1];

WaferAlignment.r_offset = 0;
WaferAlignment.c_offset = 0;
WaferAlignment.AngleOffsetInDegrees = 0;
afterAlignI{startWafer} = allI{startWafer};

OverviewAlignedDataFileNameStr=[GuiGlobalsStruct.UTSLDirectory '\' WaferList{listImages(startWafer)} ...
    '\' 'SectionOverviewTemplateDirectory\WaferAlignment.mat']
save(OverviewAlignedDataFileNameStr, 'WaferAlignment');

for i = 1:length(useRef)
    refID = useRef(i);
    moveID = useMove(i);
    alignImage = allI{moveID};
    refImage = afterAlignI{refID};      
    
    UpdatedMessageStr = sprintf('aligning wafer %d of %d', i , length(listImages));
        waitbar(i/length(listImages),GuiGlobalsStruct.h_waitbar, UpdatedMessageStr);
    if GuiGlobalsStruct.IsUserCancelWaitBar
        return;
    end
    StartTimeOfThisSection = tic
    
    [TempWidth, dummy] = size(alignImage);
    disp([' Max res = ' num2str(GuiGlobalsStruct.SectionOverviewProcessingParameters.MaxRes)])
    DSFactor = ceil(TempWidth/GuiGlobalsStruct.SectionOverviewProcessingParameters.MaxRes); %ceil(TempWidth/256);%ceil(TempWidth/512);%Note: this will always make sure that the max image size to the alignment routine is 512x512
    
      
    %%
    OriginalImageDS = imresize(refImage,1/DSFactor,'bilinear'); %Must down sample by 8x to prevent out of memory error on fibics computer
    ReImagedImageDS = imresize(alignImage,1/DSFactor,'bilinear');
    
    %%Filter Downsampled images
    OriginalImageDS = mexHatSection(OriginalImageDS);
    ReImagedImageDS = mexHatSection(ReImagedImageDS);
    %Determine angle and offset
    
    
    %% Find scale difference
    if autoScale
    
        refObjectSize = sum(OriginalImageDS(:)<250);
        alignObjectSize = sum(ReImagedImageDS(:)<250);
        scaleDif = refObjectSize/alignObjectSize;
            [oldys oldxs] = size(alignImage);
        scaleDif = 1;
        alignImage_reScale = imresize(alignImage,scaleDif);
        [newys newxs] = size(alignImage_reScale);
        if scaleDif>1
            shiftY = fix((newys-oldys)/2);
            shiftX = fix((newxs-oldxs)/2);
            alignImage_reScale2 = alignImage * 0;
            alignImage_reScale2 = alignImage_reScale(shiftY + 1:shiftY+oldys,shiftX+1:shiftX + oldxs);
        elseif  scaleDif <= 1
            shiftY = -fix((newys-oldys)/2);
            shiftX = -fix((newxs-oldxs)/2);
            alignImage_reScale2 = alignImage * 0 + median(alignImage(:));
            alignImage_reScale2(shiftY + 1:shiftY+newys,shiftX+1:shiftX + newxs) =  alignImage_reScale;

        end
     %% reprocess reScaled image
        ReImagedImageDS = imresize(alignImage_reScale2,1/DSFactor,'bilinear');
    ReImagedImageDS = mexHatSection(ReImagedImageDS);    
        
    else
        scaleDif = 1;
    end
        
    CenterAngle = GuiGlobalsStruct.SectionOverviewProcessingParameters.CenterAngle;
    AngleIncrement = GuiGlobalsStruct.SectionOverviewProcessingParameters.AngleIncrement;
    NumMultiResSteps = GuiGlobalsStruct.SectionOverviewProcessingParameters.NumMultiResSteps;
    
    [XOffsetOfNewInPixels, YOffsetOfNewInPixels, AngleOffsetOfNewInDegrees] =...
        CalcPixelOffsetAndAngleBetweenTwoImagesMultiScale(255-OriginalImageDS, 255-ReImagedImageDS,...
        CenterAngle, AngleIncrement, NumMultiResSteps);
    
    AngleOffsetInDegrees = -AngleOffsetOfNewInDegrees;
    
    ReImagedImageDS(ReImagedImageDS==0) = 1;
    %END: KH Make background average value code 9_17_2011
    
    OverviewImage_rotated = imrotate(alignImage,AngleOffsetInDegrees,'crop'); %note negative on angle
    
    %Start: handle coord transform reordering
    AngleOffsetInRadians = AngleOffsetInDegrees*(pi/180);
    XOffsetOfNewInPixels_Transformed = XOffsetOfNewInPixels*cos(AngleOffsetInRadians) - YOffsetOfNewInPixels*sin(AngleOffsetInRadians);
    YOffsetOfNewInPixels_Transformed = XOffsetOfNewInPixels*sin(AngleOffsetInRadians) + YOffsetOfNewInPixels*cos(AngleOffsetInRadians);
    %End: handle coord transform reordering 
     
    
    %% New shift
    r_offset = YOffsetOfNewInPixels_Transformed*DSFactor; %Note: Here is where the reversed Y-Axis sign change is fixed
    c_offset = - XOffsetOfNewInPixels_Transformed*DSFactor;
    OverviewImage_rotated_shifted = 0*OverviewImage_rotated;
    [MaxR, MaxC] = size(OverviewImage_rotated);
    
    [r c] = find(OverviewImage_rotated_shifted == 0);
    New_r = round(r + r_offset);
    New_c = round(c + c_offset);
    goodShift = (New_r > 0) & (New_r <=MaxR) & (New_c > 0) & (New_c <=MaxC);
    shiftInds = sub2ind(size(OverviewImage_rotated_shifted),New_r(goodShift),New_c(goodShift)); 
    OverviewImage_rotated_shifted(shiftInds) = OverviewImage_rotated(goodShift);
    
    OverviewImage_rotated_shifted(OverviewImage_rotated_shifted==0) = median(alignImage(:));
    
    color1 = 255 - refImage;
    color1(:,:,2) = 255 - alignImage;
    color1(:,:,3) = 255 - OverviewImage_rotated_shifted;
    image(uint8(color1)),pause(1)
    
    
    afterAlignI{moveID}=OverviewImage_rotated_shifted;    
    imwrite(OverviewImage_rotated_shifted,newInams{moveID},'Compression','none');
    
     OverviewAlignedDataFileNameStr=[GuiGlobalsStruct.UTSLDirectory '\' WaferList{listImages(moveID)} ...
        '\' 'SectionOverviewTemplateDirectory\WaferAlignment.mat']
    WaferAlignment.r_offset = r_offset;
    WaferAlignment.c_offset = c_offset;
    WaferAlignment.AngleOffsetInDegrees = AngleOffsetInDegrees;
    WaferAlignment.scaleDif = scaleDif;
    save(OverviewAlignedDataFileNameStr, 'WaferAlignment');
    
end

if ishandle(GuiGlobalsStruct.h_waitbar)
     delete(GuiGlobalsStruct.h_waitbar);
end
