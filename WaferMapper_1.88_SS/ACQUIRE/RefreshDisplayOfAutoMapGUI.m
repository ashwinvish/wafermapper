function RefreshDisplayOfAutoMapGUI(HandleToDisplayAxes, IsDisplayCrosshairsAndLabels)
global GuiGlobalsStruct;
global AutoMapGUIGlobals;

%clear CoarseSectionList and FullMapDisplay
axes(HandleToDisplayAxes);
cla;
imshow(GuiGlobalsStruct.FullMapImage,[0,255]);
%This maintains zoom across different sections displayed
if isfield(AutoMapGUIGlobals, 'axes_FullMapDisplay_xlim')
    set(HandleToDisplayAxes, 'xlim', AutoMapGUIGlobals.axes_FullMapDisplay_xlim);
    set(HandleToDisplayAxes, 'ylim',AutoMapGUIGlobals.axes_FullMapDisplay_ylim);
end

if isfield(GuiGlobalsStruct, 'CoarseSectionList')

    for i =1:length(GuiGlobalsStruct.CoarseSectionList)
        
        if(~GuiGlobalsStruct.CoarseSectionList(i).IsDeleted)
            ColorArray = [1 0 0];
            if isfield(GuiGlobalsStruct.CoarseSectionList(i), 'StripNum')
                if mod(GuiGlobalsStruct.CoarseSectionList(i).StripNum,2) == 0 %if even
                    ColorArray = [1 0 0];
                else
                    ColorArray = [0 0 1];
                end
            end
            
            
            rpeak = GuiGlobalsStruct.CoarseSectionList(i).rpeak;
            cpeak = GuiGlobalsStruct.CoarseSectionList(i).cpeak;
            
            if(IsDisplayCrosshairsAndLabels)
                h1 = line([cpeak-20, cpeak+20],[rpeak, rpeak]);
                h2 = line([cpeak, cpeak],[rpeak-20, rpeak+20]);
                set(h1,'Color',ColorArray);
                set(h2,'Color',ColorArray);
                
                TextStr = GuiGlobalsStruct.CoarseSectionList(i).Label;
                h3 = text(cpeak, rpeak, TextStr);
                set(h3,'Color',ColorArray);
            end
            
        end
        
    end
end