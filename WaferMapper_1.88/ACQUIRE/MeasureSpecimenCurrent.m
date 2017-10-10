global GuiGlobalsStruct
figure;
for i = 1:1:120
 scm(i) = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_SCM');
 plot(i,scm(i),'ro');
 hold on;
 pause(1);
end
MI4SpotAg = scm;

save('F:\TestMerlin\ConductivityMeasure\2nA\MI4SpotAg.mat','MI4SpotAg');
clear scm;
