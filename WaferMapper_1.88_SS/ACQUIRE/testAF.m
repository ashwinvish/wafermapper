% test Autofoucs funciton

sm = GuiGlobalsStruct.MyCZEMAPIClass; %To shorten calls to global API variables in this function


StartingMagForAF = 5000;
IsPerformAutoStig = false;
StartingMagForAS =  5000;
AFscanRate = 4;
AFImageStore = 0;

focOptions.IsDoQualCheck = false; % GuiGlobalsStruct.MontageParameters.IsPerformQualityCheckOnEveryAF;
focOptions.QualityThreshold = [];%GuiGlobalsStruct.MontageParameters.AFQualityThreshold;
CurrentWorkingDistance = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_WD');



IsNeedToReleaseFromFibics = 1;
if IsNeedToReleaseFromFibics
    %*** START: This sequence is designed to release the SEM from Fibics control
    sm.Execute('CMD_AUTO_FOCUS_FINE');
    pause(0.5);
    sm.Execute('CMD_ABORT_AUTO');
    while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
        pause(0.02);
    end
    sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance);
    
    pause(0.1);
    %*** END
end


sm.Set_PassedTypeSingle('AP_Mag',StartingMagForAF);
%%%%Turns off Ext Scan control here
%Temporary hard code settings
sm.Set_PassedTypeSingle('DP_AutoFunction_ScanRate',AFscanRate);
sm.Set_PassedTypeSingle('DP_IMAGE_STORE',AFImageStore);

%%%%
%sm.Set_PassedTypeSingle('DP_BEAM_BLANKED',0);
%%%%
%%LongPauseForStability
%sm.Execute('MCL_jmFocusWoble')%run for 10 sec
pause(3)
%sm.Set_PassedTypeSingle('AP_WD',CurrentWorkingDistance);


sm.Execute('CMD_AUTO_FOCUS_FINE');

pause(0.5);
disp('Auto Focusing...');
while ~strcmp('Idle',sm.Get_ReturnTypeString('DP_AUTO_FUNCTION'))
    pause(0.02);
end
pause(0.01);
ResultWD =sm.Get_ReturnTypeSingle('AP_WD');
ResultWD1 = ResultWD*1000;
