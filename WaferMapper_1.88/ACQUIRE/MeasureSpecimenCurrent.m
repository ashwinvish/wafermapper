function [specimenCurrent] = MeasureSpecimenCurrent(time)
%Measures the specimen current for duration of time at spot of interest
% time is the duration of time in seconds
global GuiGlobalsStruct
figure;
for i = 1:1:time
 scm(i) = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_SCM');
 plot(i,scm(i),'ro');
 hold on;
 pause(1);
end
specimenCurrent = scm;

% save('F:\TestMerlin\ConductivityMeasure\2nA\MI4SpotAg.mat','MI4SpotAg');
% clear scm;
