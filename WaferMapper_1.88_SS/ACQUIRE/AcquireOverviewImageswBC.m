%AcquireOverviewImages
global GuiGlobalsStruct;

%IsDoAutoFocus = true; %true; %KH CHANGE BACK TO TRUE

disp('Turning stage backlash ON in X and Y');
GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeString('DP_X_BACKLASH','+ -');
GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeString('DP_Y_BACKLASH','+ -');
GuiGlobalsStruct.MyCZEMAPIClass.Set_PassedTypeString('DP_STAGE_BACKLASH', GuiGlobalsStruct.backlashState);

GuiGlobalsStruct.IsDisplayCurrentStagePosition = false;
set(handles.DisplaySectionCrosshairs_ToolbarButton,'state','on');
UpdateFullWaferDisplay(handles);

uiwait(msgbox('Section locations to be imaged are displayed. Check stig and focus (will perform focus on every section) and contrast, then press OK to proceed.'));

start = tic;

%uiwait(msgbox('WARNING CODE WAS MODIFIED TO TAKE EVERY 10th SECTION!!!'));

for i = 1:length(GuiGlobalsStruct.CoarseSectionList)
    
    if(~GuiGlobalsStruct.CoarseSectionList(i).IsDeleted)
        ImageFileNameStr = sprintf('%s\\SectionOverviewwBC_%s.tif',GuiGlobalsStruct.SectionOverviewsDirectory,GuiGlobalsStruct.CoarseSectionList(i).Label);
        %DataFileNameStr = sprintf('%s\\SectionOverview_%s.mat',GuiGlobalsStruct.SectionOverviewsDirectory,GuiGlobalsStruct.CoarseSectionList(i).Label);
        
        if exist(ImageFileNameStr,'file') %This allows for simple retakes - just delete the bad image and run again
            MyStr = sprintf('%s exists. SKIPPING.', ImageFileNameStr);
            disp(MyStr);
        else
            cpeak = GuiGlobalsStruct.CoarseSectionList(i).cpeak;
            rpeak = GuiGlobalsStruct.CoarseSectionList(i).rpeak;
            
            NativePixelWidth_mm = (GuiGlobalsStruct.FullMapData.TileFOV_microns/1000)/GuiGlobalsStruct.FullMapData.ImageWidthInPixels;
            NativePixelHeight_mm = (GuiGlobalsStruct.FullMapData.TileFOV_microns/1000)/GuiGlobalsStruct.FullMapData.ImageHeightInPixels;
            
            DownSamplePixelWidth_mm = NativePixelWidth_mm*GuiGlobalsStruct.FullMapData.DownsampleFactor;
            DownSamplePixelHeight_mm = NativePixelHeight_mm*GuiGlobalsStruct.FullMapData.DownsampleFactor;
            
            X_Stage_mm = GuiGlobalsStruct.FullMapData.LeftStageX_mm + 0.5*(GuiGlobalsStruct.FullMapData.TileFOV_microns/1000) - cpeak*DownSamplePixelWidth_mm
            Y_Stage_mm = GuiGlobalsStruct.FullMapData.TopStageY_mm - 0.5*(GuiGlobalsStruct.FullMapData.TileFOV_microns/1000) + rpeak*DownSamplePixelHeight_mm
            '!!added ane to stage target'
            
            StageX_Meters = X_Stage_mm/1000;
            StageY_Meters = Y_Stage_mm/1000;
            
            disp('Getting stage position');
            stage_x = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_X');
            stage_y = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Y');
            stage_z = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_Z');
            stage_t = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_T');
            stage_r = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_R');
            stage_m = GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeSingle('AP_STAGE_AT_M');
            MyStr = sprintf('Stage Position(x,y,z,t,r,m) = (%0.7g, %0.7g, %0.7g, %0.7g, %0.7g, %0.7g, )'...
                ,stage_x,stage_y,stage_z,stage_t,stage_r, stage_m);
            disp(MyStr);
            disp(' ');
            
            MyStr = sprintf('Moving stage to(%0.5g, %0.5g)',StageX_Meters,StageY_Meters);
            disp(MyStr);
            GuiGlobalsStruct.MyCZEMAPIClass.MoveStage(StageX_Meters,StageY_Meters,stage_z,stage_t,stage_r,stage_m);
            while(strcmp(GuiGlobalsStruct.MyCZEMAPIClass.Get_ReturnTypeString('DP_STAGE_IS'),'Busy'))
                pause(.02)
            end
            wmBackLash
            %Acquire image
            if GuiGlobalsStruct.WaferParameters.PerformAutofocus
                PerformAutoFocus; %PerformAutoFocusStigFocus;
                pause(2);
            end
            %             pause(1);
            %             GuiGlobalsStruct.MyCZEMAPIClass.Fibics_WriteFOV(SectionOveriewFOV_microns);
            
            %%%---BC part start
            
            MyCZEMAPIClass = GuiGlobalsStruct.MyCZEMAPIClass;
            tic
            %% Set up Variables
            %DwellTimeInMicroseconds = GuiGlobalsStruct.MontageParameters.TileDwellTime_microseconds;
            MyCZEMAPIClass.Set_PassedTypeSingle('AP_BRIGHTNESS',53);
            MyCZEMAPIClass.Set_PassedTypeSingle('AP_CONTRAST',25);
            DwellTimeInMicroseconds = .05;
            FOV_microns = 2667;
            FileName = 'C:\temp\tempBC.tif';
            MyCZEMAPIClass.Fibics_WriteFOV(FOV_microns); %Always set the FOV even if you are overriding with mag (might be used in some way inside Fibics)
            pause(0.1); %1
            
            %% Get first brigh/con
            firstBrightness =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_BRIGHTNESS');
            firstContrast =  MyCZEMAPIClass.Get_ReturnTypeSingle('AP_CONTRAST');
            newBright = firstBrightness;
            newCon = firstContrast;
            imagePix = 1024;
            lowThresh = .001; %percent allowed to saturate
            highThresh = .001; %percent allowed to saturate
            changeBright = .5;
            changeCon = .5;
            lastChangeCon = 0;
            lastChangeBright = 0;
            
            %% Start checking contrast
            for r = 1:1000
                
                
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
                
                numLow = histI(1);
                numHigh = histI(end);
                numGoodLow = sum(histI(1:10));
                numGoodHigh = sum(histI(end-9:end));
                medI = median(I(:));
                stdI = std(I(:));
                
                tooLow = (numLow/imagePix^2) > (lowThresh/100);
                tooHigh = (numHigh/imagePix^2) > (highThresh/100);
                
                
                
                
                if tooLow & tooHigh %reduceContrast
                    
                    if lastChangeCon == 1
                        changeCon = changeCon/2
                    end
                    disp('dropContrast')
                    newCon = newCon-changeCon;
                    newBright = newBright + changeCon;
                    lastChangeCon = -1;
                    %lastChangeBright = 0;
                elseif tooLow
                    if lastChangeBright == -1
                        changeBright = changeBright;
                    end
                    disp('brighten')
                    newBright = newBright + changeBright;
                    lastChangeBright = 1;
                    %lastChangeCon = 0;
                elseif tooHigh
                    if lastChangeBright == 1
                        changeBright = changeBright/2;
                    end
                    disp('darken')
                    newBright = newBright - changeBright;
                    lastChangeBright = -1;
                    %lastChangeCon = 0;
                else
                    if lastChangeCon == -1
                        changeCon = changeCon/2;
                    end
                    passLow = (numGoodLow/imagePix^2) > (lowThresh/100)
                    passHigh = (numGoodHigh/imagePix^2)> (highThresh/100)
                    if passLow & passHigh
                        'passed'
                        GuiGlobalsStruct.AutoBCOverviewB(i) = newBright;
                        GuiGlobalsStruct.AutoBCOverviewC(i) = newCon;
                        break
                    end
                    
                    disp('Increase Contrast')
                    newCon = newCon+changeCon;
                    newBright = newBright + changeCon/2;
                    lastChangeCon = 1;
                    %lastChangeBright = 0;
                end
                
                
                
                MyCZEMAPIClass.Set_PassedTypeSingle('AP_BRIGHTNESS',newBright);
                MyCZEMAPIClass.Set_PassedTypeSingle('AP_CONTRAST',newCon);
            end %image againg
            
            %%%---BC part end
            
            FOV_microns = GuiGlobalsStruct.WaferParameters.SectionOverviewFOV_microns; %4096; % 4096;
            %GuiGlobalsStruct.MyCZEMAPIClass.Fibics_WriteFOV(SectionOveriewFOV_microns);
            ImageWidthInPixels = GuiGlobalsStruct.WaferParameters.SectionOverviewWidth_pixels; %4096; %4096;
            ImageHeightInPixels = GuiGlobalsStruct.WaferParameters.SectionOverviewWidth_pixels; %4096; %4096;
            DwellTimeInMicroseconds = GuiGlobalsStruct.WaferParameters.SectionOverviewDwellTime_microseconds; %1; %KH CHANGE BACK TO 1
            
            MyStr = sprintf('Acquiring %s, Please wait...',ImageFileNameStr);
            h_msgbox = msgbox(MyStr,'modal');
            
            StartTimeOfImageAcquire = tic;
            %             Fibics_AcquireImage_WithAutoRetakes(SectionOveriewImageWidthInPixels,SectionOveriewImageHeightInPixels,...
            %                 SectionOveriewDwellTimeInMicroseconds,ImageFileNameStr);
            
            %Fibics_AcquireImage(ImageWidthInPixels, ImageHeightInPixels, DwellTimeInMicroseconds, FileNameStr,...
            %     FOV_microns, IsDoAutoRetakeIfNeeded, IsMagOverride, MagForOverride,  WaferNameStr, LabelStr)
            IsDoAutoRetakeIfNeeded = true; %retake if full white or black image
            IsMagOverride = false;
            MagForOverride = -1;
            WaferNameStr = '';
            LabelStr = GuiGlobalsStruct.CoarseSectionList(i).Label;
            Fibics_AcquireImage(ImageWidthInPixels, ImageHeightInPixels, DwellTimeInMicroseconds, ImageFileNameStr,...
                FOV_microns, IsDoAutoRetakeIfNeeded, IsMagOverride, MagForOverride,  WaferNameStr, LabelStr);
            
            disp(sprintf('Image Acquire Duration = %0.7g seconds',toc(StartTimeOfImageAcquire)));
            
            
            
            
            close(h_msgbox);
            
            axes(handles.Axes_FullWaferDisplay);
            %Mark on display as completed
            h1 = line([cpeak-40, cpeak+40],[rpeak, rpeak]);
            h2 = line([cpeak, cpeak],[rpeak-40, rpeak+40]);
            set(h1,'Color',[0 0 1]);
            set(h2,'Color',[0 0 1]);
        end
        
    end
    toc(start)
end


