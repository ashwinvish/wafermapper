function varargout = AlignWafersGUI(varargin)
% AlignWafersGUI MATLAB code for AlignWafersGUI.fig
%      AlignWafersGUI, by itself, creates a new AlignWafersGUI or raises the existing
%      singleton*.
%
%      H = AlignWafersGUI returns the handle to a new AlignWafersGUI or the handle to
%      the existing singleton*.
%
%      AlignWafersGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AlignWafersGUI.M with the given input arguments.
%
%      AlignWafersGUI('Property','Value',...) creates a new AlignWafersGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AlignWafersGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AlignWafersGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AlignWafersGUI

% Last Modified by GUIDE v2.5 29-Nov-2012 13:56:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AlignWafersGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @AlignWafersGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before AlignWafersGUI is made visible.
function AlignWafersGUI_OpeningFcn(hObject, eventdata, handles, varargin)

% Choose default command line output for AlignWafersGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AlignWafersGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

set(handles.ReferenceWafer_listbox,'String',GuiGlobalsStruct.ListOfWaferNames);
set(handles.WaferNum_listbox,'String',GuiGlobalsStruct.ListOfWaferNames);


AlignWaferGuiGlobalStruct.ColorCombinedImage = [];


AlignWaferGuiGlobalStruct.H_gaussian = fspecial('gaussian',[5 5],1.5);
AlignWaferGuiGlobalStruct.DSFactor = 8; 
AlignWaferGuiGlobalStruct.MaxLabelNum = length(GuiGlobalsStruct.ListOfWaferNames);
AlignWaferGuiGlobalStruct.AdjustMag = 1;

AlignWaferGuiGlobalStruct.RefNum = GuiGlobalsStruct.WaferNameIndex;
AlignWaferGuiGlobalStruct.WaferNum = GuiGlobalsStruct.WaferNameIndex;
LoadReferenceOverviewFromFile(handles)
LoadOverviewFromFile(handles);
DisplayColorCombinedImage(handles);


function  LoadReferenceOverviewFromFile(handles)

global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

refWafer = GuiGlobalsStruct.ListOfWaferNames{AlignWaferGuiGlobalStruct.RefNum};
set(handles.ReferenceWafer_EditBox,'String', refWafer);

FileNameStr = [GuiGlobalsStruct.UTSLDirectory '\' refWafer '\' 'SectionOverviewTemplateDirectory\waferManualAlignedAverageOverview.tif'] ;
if ~exist(FileNameStr,'file')
    FileNameStr = [GuiGlobalsStruct.UTSLDirectory '\' refWafer '\' 'SectionOverviewTemplateDirectory\waferAlignedAverageOverview.tif'] ;
end

AlignWaferGuiGlobalStruct.SectionOverviewTemplateCroppedFilled = imread(FileNameStr,'tif');
AlignWaferGuiGlobalStruct.CenteredTemplateImage = ...
    imfilter(AlignWaferGuiGlobalStruct.SectionOverviewTemplateCroppedFilled,AlignWaferGuiGlobalStruct.H_gaussian);    
AlignWaferGuiGlobalStruct.CenteredTemplateImageDS = ...
    imresize(AlignWaferGuiGlobalStruct.CenteredTemplateImage,1/AlignWaferGuiGlobalStruct.DSFactor,'bilinear');    
 set(handles.ReferenceWafer_listbox,'Value',AlignWaferGuiGlobalStruct.RefNum);



function LoadOverviewFromFile(handles)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

moveWafer  =  GuiGlobalsStruct.ListOfWaferNames{AlignWaferGuiGlobalStruct.WaferNum};
set(handles.WaferNumber_EditBox,'String', moveWafer);

%Load these THREE files:
TimeBeforeLoad = tic;

OverviewImageAlignedFileNameStr = [GuiGlobalsStruct.UTSLDirectory '\' moveWafer '\' 'SectionOverviewTemplateDirectory\averageAlignedOverviews.tif'] ;
OverviewAlignedDataFileNameStr = [GuiGlobalsStruct.UTSLDirectory '\' moveWafer '\' 'SectionOverviewTemplateDirectory\manualWaferAlignment.mat'] ;
if ~exist(OverviewAlignedDataFileNameStr,'file')
    OverviewAlignedDataFileNameStr = [GuiGlobalsStruct.UTSLDirectory '\' moveWafer '\' 'SectionOverviewTemplateDirectory\WaferAlignment.mat'] ;
end

%WaferAlignment Data file
load(OverviewAlignedDataFileNameStr);%, 'WaferAlignment');  
AlignWaferGuiGlobalStruct.r_offset = WaferAlignment.r_offset;
AlignWaferGuiGlobalStruct.c_offset = WaferAlignment.c_offset;
AlignWaferGuiGlobalStruct.AngleOffsetInDegrees = WaferAlignment.AngleOffsetInDegrees;
if ~isfield(WaferAlignment,'waferScale')
    WaferAlignment.scaleDif = 1;
end
AlignWaferGuiGlobalStruct.waferScale = WaferAlignment.scaleDif;

while  1 % force angle between -180 and 180
    if AlignWaferGuiGlobalStruct.AngleOffsetInDegrees < -180
        AlignWaferGuiGlobalStruct.AngleOffsetInDegrees = AlignWaferGuiGlobalStruct.AngleOffsetInDegrees + 360;
    elseif AlignWaferGuiGlobalStruct.AngleOffsetInDegrees > 180 
        AlignWaferGuiGlobalStruct.AngleOffsetInDegrees = AlignWaferGuiGlobalStruct.AngleOffsetInDegrees - 360;
    end
    if (AlignWaferGuiGlobalStruct.AngleOffsetInDegrees>=-18 ) & (AlignWaferGuiGlobalStruct.AngleOffsetInDegrees<= 180.0)
        break
    end
end
set(handles.r_offset_EditBox,'String',num2str(AlignWaferGuiGlobalStruct.r_offset));
set(handles.c_offset_EditBox,'String',num2str(AlignWaferGuiGlobalStruct.c_offset));
set(handles.AngleOffset_EditBox,'String',num2str(AlignWaferGuiGlobalStruct.AngleOffsetInDegrees));
set(handles.r_offset_Slider, 'Value', -AlignWaferGuiGlobalStruct.r_offset); 
set(handles.c_offset_Slider, 'Value', AlignWaferGuiGlobalStruct.c_offset); 
set(handles.AngleOffset_Slider, 'Value', AlignWaferGuiGlobalStruct.AngleOffsetInDegrees); 
set(handles.scale_Slider, 'Value', AlignWaferGuiGlobalStruct.waferScale); 
set(handles.scale_EditBox,'String',num2str(AlignWaferGuiGlobalStruct.waferScale));

%load OverviewImageAligned image and apply light filtering
disp(sprintf('Loading image file: %s',OverviewImageAlignedFileNameStr));
AlignWaferGuiGlobalStruct.OverviewImageAligned = imread(OverviewImageAlignedFileNameStr,'tif');
AlignWaferGuiGlobalStruct.OverviewImageAligned = imfilter(AlignWaferGuiGlobalStruct.OverviewImageAligned,AlignWaferGuiGlobalStruct.H_gaussian);

AlignWaferGuiGlobalStruct.OverviewImage = AlignWaferGuiGlobalStruct.OverviewImageAligned 


TimeForLoad = toc(TimeBeforeLoad);
disp(sprintf('Time to load images: %0.5g seconds', TimeForLoad));

%downsample
AlignWaferGuiGlobalStruct.OverviewImageDS = ...
    imresize(AlignWaferGuiGlobalStruct.OverviewImage,1/AlignWaferGuiGlobalStruct.DSFactor,'bilinear');
AlignWaferGuiGlobalStruct.OverviewImageAlignedDS = ...
    imresize(AlignWaferGuiGlobalStruct.OverviewImageAligned,1/AlignWaferGuiGlobalStruct.DSFactor,'bilinear');

AlignWaferGuiGlobalStruct.OverviewImageTransformedDS = AlignWaferGuiGlobalStruct.OverviewImageDS;

ApplyTransform(handles);
 set(handles.WaferNum_listbox,'Value',AlignWaferGuiGlobalStruct.WaferNum);



function DisplayColorCombinedImage(handles)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;


axes(handles.axes1); %display for OverviewImageAlignedDS
ColorCombinedImage(:,:,1) = double(AlignWaferGuiGlobalStruct.OverviewImageAlignedDS)/255; 
ColorCombinedImage(:,:,2) = double(AlignWaferGuiGlobalStruct.CenteredTemplateImageDS)/255;%NOTE template will 'look' red because section is darker than background
ColorCombinedImage(:,:,3) = 0*ColorCombinedImage(:,:,1);
imshow(ColorCombinedImage, 'InitialMagnification', 'fit');

axes(handles.axes2); %display for OverviewImageDS
ColorCombinedImage(:,:,1) = double(AlignWaferGuiGlobalStruct.OverviewImageTransformedDS)/255;
ColorCombinedImage(:,:,2) = double(AlignWaferGuiGlobalStruct.CenteredTemplateImageDS)/255;%NOTE template will 'look' red because section is darker than background
ColorCombinedImage(:,:,3) = 0*ColorCombinedImage(:,:,1);
imshow(ColorCombinedImage, 'InitialMagnification', 'fit');


% --- Outputs from this function are returned to the command line.
function varargout =  AlignWafersGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called



function OverviewFileName_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to OverviewFileName_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OverviewFileName_EditBox as text
%        str2double(get(hObject,'String')) returns contents of OverviewFileName_EditBox as a double


% --- Executes during object creation, after setting all properties.
function OverviewFileName_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OverviewFileName_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in Next_Button.
function Next_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Next_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

AlignWaferGuiGlobalStruct.WaferNum = 1 + AlignWaferGuiGlobalStruct.WaferNum;

if AlignWaferGuiGlobalStruct.WaferNum > AlignWaferGuiGlobalStruct.MaxLabelNum
    AlignWaferGuiGlobalStruct.WaferNum = AlignWaferGuiGlobalStruct.WaferNum - 1;
    uiwait(msgbox('Already on last Wafer'));
    return;
end

LoadOverviewFromFile(handles);
DisplayColorCombinedImage(handles);

% --- Executes on button press in Next_Button.
function Back_Button_Callback(hObject, eventdata, handles)
% hObject    handle to Back_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

AlignWaferGuiGlobalStruct.WaferNum =  AlignWaferGuiGlobalStruct.WaferNum -1;

if AlignWaferGuiGlobalStruct.WaferNum < 1 
    AlignWaferGuiGlobalStruct.WaferNum = 1;
    uiwait(msgbox('Already on first Wafer'));
    return;
end

LoadOverviewFromFile(handles);
DisplayColorCombinedImage(handles);

function WaferNumber_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to WaferNumber_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of WaferNumber_EditBox as text
%        str2double(get(hObject,'String')) returns contents of WaferNumber_EditBox as a double
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

MyWaferNumberStr = get(handles.WaferNumber_EditBox,'String');

%[X,OK]=STR2NUM(S)
[WaferNum, IsOK] = str2num(MyWaferNumberStr)
if ~IsOK
    LoadOverviewFromFile(handles, 1); %just reload first Wafer and return
    DisplayColorCombinedImage(handles);
    return;
end
if WaferNum<1 || WaferNum>AlignWaferGuiGlobalStruct.MaxLabelNum
    LoadOverviewFromFile(handles, 1);%just reload first Wafer and return
    DisplayColorCombinedImage(handles);
    return;
end

AlignWaferGuiGlobalStruct.WaferNum = WaferNum;
LoadOverviewFromFile(handles);
DisplayColorCombinedImage(handles);


% --- Executes during object creation, after setting all properties.
function WaferNumber_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to WaferNumber_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;
OriginalImage = AlignWaferGuiGlobalStruct.OverviewImageDS;
NewImage = AlignWaferGuiGlobalStruct.CenteredTemplateImageDS;
AnglesInDegreesToTryArray = linspace(-6,6,5); %-6    -3     0     3     6
[XOffsetOfNewInPixels, YOffsetOfNewInPixels, AngleOffsetOfNewInDegrees] = ...
    CalcPixelOffsetAndAngleBetweenTwoImages_CenterRestricted(OriginalImage, NewImage, AnglesInDegreesToTryArray)






function r_offset_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to r_offset_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of r_offset_EditBox as text
%        str2double(get(hObject,'String')) returns contents of r_offset_EditBox as a double
r_offset = str2num(get(handles.r_offset_EditBox,'String'));
set(handles.r_offset_Slider, 'Value',-r_offset); %note minus sign
ApplyTransform(handles);



% --- Executes during object creation, after setting all properties.
function r_offset_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to r_offset_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function c_offset_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to c_offset_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of c_offset_EditBox as text
%        str2double(get(hObject,'String')) returns contents of c_offset_EditBox as a double
c_offset = str2num(get(handles.c_offset_EditBox,'String'));
set(handles.c_offset_Slider, 'Value',c_offset); %note minus sign
ApplyTransform(handles);

% --- Executes during object creation, after setting all properties.
function c_offset_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to c_offset_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AngleOffset_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to AngleOffset_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AngleOffset_EditBox as text
%        str2double(get(hObject,'String')) returns contents of AngleOffset_EditBox as a double
AngleOffset = str2num(get(handles.AngleOffset_EditBox,'String'));
set(handles.AngleOffset_Slider, 'Value',AngleOffset); %note minus sign
ApplyTransform(handles);

% --- Executes during object creation, after setting all properties.
function AngleOffset_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AngleOffset_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ApplyTransform(handles)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;

% AlignWaferGuiGlobalStruct.r_offset = WaferAlignment.r_offset;
% AlignWaferGuiGlobalStruct.c_offset = WaferAlignment.c_offset;
% AlignWaferGuiGlobalStruct.AngleOffsetInDegrees = WaferAlignment.AngleOffsetInDegrees;


r_offset = str2num(get(handles.r_offset_EditBox,'String'));
c_offset = str2num(get(handles.c_offset_EditBox,'String'));
AngleOffsetInDegrees = str2num(get(handles.AngleOffset_EditBox,'String'));
waferScale = str2num(get(handles.scale_EditBox,'String'));

%%Apply Wafer scale if there is one
if waferScale >1
    ODS_scaled = imresize(AlignWaferGuiGlobalStruct.OverviewImageDS,waferScale);
    [ys xs] = size(AlignWaferGuiGlobalStruct.OverviewImageDS);
    ODS_scaled2 = ODS_scaled(round(size(ODS_scaled,1)/2-ys/2)+1:round(size(ODS_scaled,1)/2-ys/2)+ys,...
        round(size(ODS_scaled,2)/2-xs/2)+1:round(size(ODS_scaled,2)/2-xs/2)+xs);
elseif waferScale<1
    ODS_scaled = imresize(AlignWaferGuiGlobalStruct.OverviewImageDS,waferScale);
    [ys xs] = size(AlignWaferGuiGlobalStruct.OverviewImageDS);
    ODS_scaled2 = zeros(ys,xs,'uint8')+ median(ODS_scaled(:));
    ODS_scaled2(round(ys/2-size(ODS_scaled,1)/2)+1:round(ys/2-size(ODS_scaled,1)/2)+size(ODS_scaled,1),...
      round(xs/2-size(ODS_scaled,2)/2)+1:round(xs/2-size(ODS_scaled,2)/2)+size(ODS_scaled,2))  = ODS_scaled; 
else
    ODS_scaled2 = AlignWaferGuiGlobalStruct.OverviewImageDS;
end

OverviewImage_rotated = imrotate(AlignWaferGuiGlobalStruct.OverviewImageDS,'crop'); %note negative on angle
OverviewImage_rotated_shifted = 0*OverviewImage_rotated;
[MaxR, MaxC] = size(OverviewImage_rotated)
for r = 1:MaxR
    for c = 1:MaxC
        New_r = r + floor(r_offset/AlignWaferGuiGlobalStruct.DSFactor);
        New_c = c + floor(c_offset/AlignWaferGuiGlobalStruct.DSFactor);
        if (New_r > 0) && (New_r <=MaxR) && (New_c > 0) && (New_c <=MaxC)
            OverviewImage_rotated_shifted(New_r, New_c) = OverviewImage_rotated(r,c);
        end
    end
end

AlignWaferGuiGlobalStruct.OverviewImageTransformedDS = OverviewImage_rotated_shifted;

DisplayColorCombinedImage(handles);


% --- Executes on button press in OverwritePrevious_Button.
function OverwritePrevious_Button_Callback(hObject, eventdata, handles)
% hObject    handle to OverwritePrevious_Button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global GuiGlobalsStruct;
global AlignWaferGuiGlobalStruct;


h_fig = msgbox('Please wait...');

r_offset = floor(str2num(get(handles.r_offset_EditBox,'String')));
c_offset = floor(str2num(get(handles.c_offset_EditBox,'String')));
AngleOffsetInDegrees = str2num(get(handles.AngleOffset_EditBox,'String'));
waferScale = str2num(get(handles.scale_EditBox,'String'));

%Apply to non-downsampled image
%START: KH Make background average value code 9_17_2011
[MaxR, MaxC] = size(AlignWaferGuiGlobalStruct.OverviewImage);
AverageBorderGrayScale =median(AlignWaferGuiGlobalStruct.OverviewImage(:));

for r = 1:MaxR
  for c = 1:MaxC
    if AlignWaferGuiGlobalStruct.OverviewImage(r,c) == 0;
      AlignWaferGuiGlobalStruct.OverviewImage(r,c) = 1; %Bump all original black pixels up to a 1 value
    end
  end
end
%END: KH Make background average value code 9_17_2011

%%Apply Wafer scale if there is one
if waferScale >1
    ODS_scaled = imresize(AlignWaferGuiGlobalStruct.OverviewImage,waferScale);
    [ys xs] = size(AlignWaferGuiGlobalStruct.OverviewImage);
    ODS_scaled2 = ODS_scaled(round(size(ODS_scaled,1)/2-ys/2)+1:round(size(ODS_scaled,1)/2-ys/2)+ys,round(size(ODS_scaled,2)/2-xs/2)+1:round(size(ODS_scaled,2)/2-xs/2)+xs)   
elseif waferScale<1
    ODS_scaled = imresize(AlignWaferGuiGlobalStruct.OverviewImage,waferScale);
    [ys xs] = size(AlignWaferGuiGlobalStruct.OverviewImage);
    ODS_scaled2 = zeros(ys,xs,'uint8')+ median(ODS_scaled(:));
    ODS_scaled2(round(ys/2-size(ODS_scaled,1)/2)+1:round(ys/2-size(ODS_scaled,1)/2)+size(ODS_scaled,1),...
      round(xs/2-size(ODS_scaled,2)/2)+1:round(xs/2-size(ODS_scaled,2)/2)+size(ODS_scaled,2))  = ODS_scaled; 
else
    ODS_scale2 = AlignWaferGuiGlobalStruct.OverviewImage,waferScale;
end

OverviewImage_rotated = imrotate(ODS_scaled2,AngleOffsetInDegrees,'crop'); %note negative on angle
OverviewImage_rotated_shifted = 0*OverviewImage_rotated;
[MaxR, MaxC] = size(OverviewImage_rotated);
for r = 1:MaxR
    for c = 1:MaxC
        New_r = r + r_offset; %*AlignWaferGuiGlobalStruct.DSFactor;
        New_c = c + c_offset; %*AlignWaferGuiGlobalStruct.DSFactor;
        if (New_r > 0) && (New_r <=MaxR) && (New_c > 0) && (New_c <=MaxC)
            OverviewImage_rotated_shifted(New_r, New_c) = OverviewImage_rotated(r,c);
        end
    end
end

%START: KH Make background average value code 9_17_2011
[MaxR, MaxC] = size(OverviewImage_rotated_shifted)
for r = 1:MaxR
  for c = 1:MaxC
    if OverviewImage_rotated_shifted(r,c) == 0;
      OverviewImage_rotated_shifted(r,c) = AverageBorderGrayScale; %fill in all transform produced border pixels with original background average
    end
  end
end
%END: KH Make background average value code 9_17_2011


Label = get(handles.WaferNumber_EditBox,'String');
OverviewImageAlignedFileNameStr = [GuiGlobalsStruct.UTSLDirectory '\' Label '\' 'SectionOverviewTemplateDirectory\waferManualAlignedAverageOverview.tif'] ;
OverviewAlignedDataFileNameStr =  [GuiGlobalsStruct.UTSLDirectory '\' moveWafer '\' 'SectionOverviewTemplateDirectory\manualWaferAlignment.mat'] ;


imwrite(OverviewImage_rotated_shifted,OverviewImageAlignedFileNameStr,'tif');
WaferAlignment.r_offset = r_offset;
WaferAlignment.c_offset = c_offset;
WaferAlignment.AngleOffsetInDegrees = AngleOffsetInDegrees;
WaferAlignment.scaleDif = waferScale;
save(OverviewAlignedDataFileNameStr, 'WaferAlignment');

%refresh with newly created files
LoadOverviewFromFile(handles);
DisplayColorCombinedImage(handles);

if ishandle(h_fig)
   close(h_fig); 
end

MyStr = sprintf('Overwrote files: %s and %s', OverviewImageAlignedFileNameStr,  OverviewAlignedDataFileNameStr);
uiwait(msgbox(MyStr));

% --- Executes on slider movement.
function r_offset_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to r_offset_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

r_offset = -get(handles.r_offset_Slider, 'Value'); %note minus sign
MyStr = sprintf('r_offset_Slider = %d', r_offset);
disp(MyStr);

set(handles.r_offset_EditBox,'String',num2str(r_offset));

ApplyTransform(handles);



% --- Executes during object creation, after setting all properties.
function r_offset_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to r_offset_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function c_offset_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to c_offset_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
c_offset = get(handles.c_offset_Slider, 'Value'); %note minus sign
MyStr = sprintf('c_offset_Slider = %d', c_offset);
disp(MyStr);

set(handles.c_offset_EditBox,'String',num2str(c_offset));

ApplyTransform(handles);

% --- Executes during object creation, after setting all properties.
function c_offset_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to c_offset_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function AngleOffset_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to AngleOffset_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
AngleOffset = get(handles.AngleOffset_Slider, 'Value'); %note minus sign
MyStr = sprintf('AngleOffset_Slider = %d', AngleOffset);
disp(MyStr);

set(handles.AngleOffset_EditBox,'String',num2str(AngleOffset));

ApplyTransform(handles);

% --- Executes during object creation, after setting all properties.
function AngleOffset_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AngleOffset_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function ReferenceWafer_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to ReferenceWafer_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ReferenceWafer_EditBox as text
%        str2double(get(hObject,'String')) returns contents of ReferenceWafer_EditBox as a double


% --- Executes during object creation, after setting all properties.
function ReferenceWafer_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ReferenceWafer_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ReferenceWafer_NextButton.
function ReferenceWafer_NextButton_Callback(hObject, eventdata, handles)
% hObject    handle to ReferenceWafer_NextButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global AlignWaferGuiGlobalStruct
AlignWaferGuiGlobalStruct.RefNum = 1 + AlignWaferGuiGlobalStruct.RefNum;

if AlignWaferGuiGlobalStruct.RefNum > AlignWaferGuiGlobalStruct.MaxLabelNum
    AlignWaferGuiGlobalStruct.RefNum = AlignWaferGuiGlobalStruct.WaferNum - 1;
    uiwait(msgbox('Already on last Wafer'));
    return;
end

LoadReferenceOverviewFromFile(handles);
DisplayColorCombinedImage(handles);



function scale_EditBox_Callback(hObject, eventdata, handles)
% hObject    handle to scale_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scale_EditBox as text
%        str2double(get(hObject,'String')) returns contents of scale_EditBox as a double


% --- Executes during object creation, after setting all properties.
function scale_EditBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scale_EditBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function scale_Slider_Callback(hObject, eventdata, handles)
% hObject    handle to scale_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider




% --- Executes during object creation, after setting all properties.
function scale_Slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scale_Slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


function ReferenceWafer_listbox_Callback(hObject, eventdata, handles)


global AlignWaferGuiGlobalStruct;
AlignWaferGuiGlobalStruct.RefNum = get(handles.ReferenceWafer_listbox,'Value')
LoadReferenceOverviewFromFile(handles);
DisplayColorCombinedImage(handles);


function ReferenceWafer_listbox_CreateFcn(hObject, eventdata, handles)


% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');

end


function WaferNum_listbox_Callback(hObject, eventdata, handles)

global AlignWaferGuiGlobalStruct;
AlignWaferGuiGlobalStruct.WaferNum = get(handles.WaferNum_listbox,'Value');
LoadOverviewFromFile(handles);
DisplayColorCombinedImage(handles);

function WaferNum_listbox_CreateFcn(hObject, eventdata, handles)

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function CoarseAdjust_pushbutton_Callback(hObject, eventdata, handles)

global AlignWaferGuiGlobalStruct

AlignWaferGuiGlobalStruct.AdjustMag = AlignWaferGuiGlobalStruct.AdjustMag * 3;
AdjustMagString = sprintf('Adjust Mag = %3.3f',AlignWaferGuiGlobalStruct.AdjustMag);
set(handles.AdjustMag_text,'String',AdjustMagString)

angleRange = get(handles.AngleOffset_Slider,'Value')  + [-90   90] * AlignWaferGuiGlobalStruct.AdjustMag;
set(handles.AngleOffset_Slider,'Min',angleRange(1),'Max',angleRange(2))

c_Range = get(handles.c_offset_Slider,'Value')  + [-100   100] * AlignWaferGuiGlobalStruct.AdjustMag
set(handles.c_offset_Slider,'Min',c_Range(1),'Max',c_Range(2))

r_Range = get(handles.r_offset_Slider,'Value')  + [-100   100] * AlignWaferGuiGlobalStruct.AdjustMag
set(handles.r_offset_Slider,'Min',r_Range(1),'Max',r_Range(2))



function FineAdjust_pushbutton_Callback(hObject, eventdata, handles)

global AlignWaferGuiGlobalStruct


AlignWaferGuiGlobalStruct.AdjustMag = AlignWaferGuiGlobalStruct.AdjustMag / 3;

AdjustMagString = sprintf('Adjust Mag = %3.3f',AlignWaferGuiGlobalStruct.AdjustMag)
set(handles.AdjustMag_text,'String',AdjustMagString)

angleRange = get(handles.AngleOffset_Slider,'Value')  + [-90   90] * AlignWaferGuiGlobalStruct.AdjustMag;
set(handles.AngleOffset_Slider,'Min',angleRange(1),'Max',angleRange(2))

c_Range = get(handles.c_offset_Slider,'Value')  + [-100   100] * AlignWaferGuiGlobalStruct.AdjustMag
set(handles.c_offset_Slider,'Min',c_Range(1),'Max',c_Range(2))

r_Range = get(handles.r_offset_Slider,'Value')  + [-100   100] * AlignWaferGuiGlobalStruct.AdjustMag
set(handles.r_offset_Slider,'Min',r_Range(1),'Max',r_Range(2))
