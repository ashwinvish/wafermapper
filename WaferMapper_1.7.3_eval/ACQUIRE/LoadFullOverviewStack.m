%LoadFullOverviewStack


ListOfWaferNames = GuiGlobalsStruct.ListOfWaferNames;

n=1;
for i = 1:length(ListOfWaferNames)
    WaferName = ListOfWaferNames{i};
    disp(sprintf('Wafer %d, Name = %s',i,WaferName));
    
    CoarseSectionListFileNameStr = sprintf('%s\\%s\\FullWaferTileImages\\CoarseSectionList.mat',...
        GuiGlobalsStruct.UTSLDirectory, WaferName);
    
    load(CoarseSectionListFileNameStr,'CoarseSectionList');
    
    
    for j = 1:length(CoarseSectionList)
        %disp(sprintf('   Section %d, Label = %s', j, CoarseSectionList(j).Label));
        
        LabelStr = CoarseSectionList(j).Label;
        ImageFileNameStr = sprintf('%s\\%s\\SectionOverviewsAlignedWithTemplateDirectory\\SectionOverviewAligned_%s.tif',...
            GuiGlobalsStruct.UTSLDirectory, WaferName, LabelStr);
        
        disp(sprintf('Loading %s',ImageFileNameStr));
        
        %Only once do we load a full res image to determine its size
        if ~isfield(GuiGlobalsStruct,'SectionOverviewImageWidthInPixels')
            MyImage = imread(ImageFileNameStr, 'tif');
            [MaxR, MaxC] = size(MyImage);
            GuiGlobalsStruct.SectionOverviewImageWidthInPixels = MaxC;
            GuiGlobalsStruct.SectionOverviewImageHeightInPixels = MaxR;
        end
        
        DownSampleFactor = 8;
        GuiGlobalsStruct.ArrayOfImages(n).Image = imread(ImageFileNameStr, 'PixelRegion',...
            {[1 DownSampleFactor GuiGlobalsStruct.SectionOverviewImageWidthInPixels], ...
            [1 DownSampleFactor GuiGlobalsStruct.SectionOverviewImageHeightInPixels]});
        
        n=n+1;
        
    end
    
    
    
    
end

