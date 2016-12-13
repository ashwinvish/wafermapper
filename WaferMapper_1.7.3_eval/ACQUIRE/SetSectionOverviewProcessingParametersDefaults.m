function SetSectionOverviewProcessingParametersDefaults()
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
global GuiGlobalsStruct;

%default Wafer Parameters
GuiGlobalsStruct.SectionOverviewProcessingParameters.CenterAngle = 0;
GuiGlobalsStruct.SectionOverviewProcessingParameters.AngleIncrement = 0.5;
GuiGlobalsStruct.SectionOverviewProcessingParameters.NumMultiResSteps = 3;
GuiGlobalsStruct.SectionOverviewProcessingParameters.MaxRes = 512;

 
end

