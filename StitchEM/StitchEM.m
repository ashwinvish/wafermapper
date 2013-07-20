function StitchEM
% StitchEM This program provides a GUI for stitching electron microscopy
% images as well as alignment. See the documentation or other script files
% for more information.

    %#ok<*NASGU>
    %#ok<*INUSD>
    % Create window
    f = figure('Visible', 'off', 'MenuBar', 'none', 'Position', [1, 1, 701, 551], ...
        'Color', get(0,'defaultUicontrolBackgroundColor'), 'Resize', 'off', ...
        'NumberTitle', 'off', 'Name', 'StitchEM - Gotta stitch ''em all!');
    
    % Move the GUI to the center of the screen.
    movegui(f,'center');
    
    % Set units to characters since the window is not resizable for better
    % cross-platform compatibility and unity
    set([f], 'Units', 'characters');

    hTabGroup = uitabgroup; drawnow;
    
    % ---- Section tab ----------------------------------------------------
    sectionTab = uitab(hTabGroup, 'title', 'Stitch Sections');
    % Wafer folder selection
    uicontrol('String', '1. Select the folder that contains the sections (the wafer folder):', 'Units', 'characters', 'Position', [0 39 65 1], 'Parent', sectionTab, 'Style', 'text');
    txbSectionFolder = uicontrol('HorizontalAlignment', 'left', 'BackgroundColor', 'white', 'Units', 'characters', 'Position', [66 38.8 60 1.6], 'Parent', sectionTab, 'Style', 'edit');
    btnBrowseForSectionFolder = uicontrol('String', 'Browse...', 'Units', 'characters', 'Position', [127 38.8 13 2], 'Parent', sectionTab, 'Style', 'pushbutton', 'Callback', @btnBrowseForSectionFolder_Callback);
    
    % Section table
    uicontrol('String', '2. Select the sections to stitch:', 'Units', 'characters', 'Position', [0 37 33 1], 'Parent', sectionTab, 'Style', 'text');
    columnname = {' ', 'Section', 'Rendered', 'Tiles', 'Resolution', 'Path'}; columnformat = {'logical', 'char', 'char', 'numeric', 'char', 'char'}; columneditable = [true, false, false, false, false, false]; columnwidth = {20 250 60 40 80 250};
    tblSections = uitable('Units', 'characters', 'Position', [0 16.5 140 20], 'Parent', sectionTab, 'ColumnName', columnname, 'ColumnFormat', columnformat, 'ColumnEditable', columneditable, 'ColumnWidth', columnwidth, 'RowName',[]);
    btnSelectAll = uicontrol('String', 'Select All', 'Units', 'characters', 'Position', [0 14 16 2], 'Parent', sectionTab, 'Style', 'pushbutton', 'Callback', @btnSelectAll_Callback);
    btnSelectNone = uicontrol('String', 'Select None', 'Units', 'characters', 'Position', [16 14 16 2], 'Parent', sectionTab, 'Style', 'pushbutton', 'Callback', @btnSelectNone_Callback);
    btnSelectUnrendered = uicontrol('String', 'Select Unrendered', 'Units', 'characters', 'Position', [32 14 20 2], 'Parent', sectionTab, 'Style', 'pushbutton', 'Callback', @btnSelectUnrendered_Callback);
    btnSelectRendered = uicontrol('String', 'Select Rendered', 'Units', 'characters', 'Position', [52 14 18 2], 'Parent', sectionTab, 'Style', 'pushbutton', 'Callback', @btnSelectRendered_Callback);
    btnRefresh = uicontrol('String', 'Refresh', 'Units', 'characters', 'Position', [70 14 16 2], 'Parent', sectionTab, 'Style', 'pushbutton', 'Callback', @btnRefresh_Callback);
    
    % TODO: remember last folder selected
    
    % ---- Wafer tab ------------------------------------------------------
    waferTab = uitab(hTabGroup, 'title', 'Stitch Wafer (Stack)');
    uicontrol('Parent', waferTab, 'Style', 'text', 'String', 'Wafer');
    
    % Display the GUI
    set(f, 'Visible', 'on');

    % ---- Callbacks ------------------------------------------------------
    function btnBrowseForSectionFolder_Callback(hObject, eventdata)
        curFolder = get(txbSectionFolder, 'String');
        if ~isempty(curFolder)
            newFolder = uigetdir(curFolder);
        else
            newFolder = uigetdir(pwd);
        end
        
        if length(newFolder) > 1 && ~strcmp(newFolder, curFolder)
            set(txbSectionFolder, 'String', newFolder);
            loadSections;
        end
    end
    function btnSelectAll_Callback(hObject, eventdata)
        tblData = get(tblSections, 'Data');
        if ~isempty(tblData)
            for row = 1:size(tblData, 1)
                tblData{row, 1} = true;
            end
        end
        set(tblSections, 'Data', tblData);
    end
    function btnSelectNone_Callback(hObject, eventdata)
        tblData = get(tblSections, 'Data');
        if ~isempty(tblData)
            for row = 1:size(tblData, 1)
                tblData{row, 1} = false;
            end
        end
        set(tblSections, 'Data', tblData);
    end
    function btnSelectUnrendered_Callback(hObject, eventdata)
        tblData = get(tblSections, 'Data');
        if ~isempty(tblData)
            for row = 1:size(tblData, 1)
                tblData{row, 1} = strcmp('No', tblData{row, 3});
            end
        end
        set(tblSections, 'Data', tblData);
    end
    function btnSelectRendered_Callback(hObject, eventdata)
        tblData = get(tblSections, 'Data');
        if ~isempty(tblData)
            for row = 1:size(tblData, 1)
                tblData{row, 1} = strcmp('Yes', tblData{row, 3});
            end
        end
        set(tblSections, 'Data', tblData);
    end
    function btnRefresh_Callback(hObject, eventdata)
        loadSections;
    end
    
    % ---- Helper functions
    function loadSections
        curFolder = get(txbSectionFolder, 'String');
        directory = dir(curFolder);
        folders = {directory([directory.isdir]).name}';
        sectionIndices = ~cellfun(@isempty, regexp(folders, '_Sec[0-9]*_'));
        sectionNames = folders(sectionIndices);
        sectionFolders = strcat(curFolder, filesep, sectionNames);
        tableData = {};
        for n = 1:length(sectionFolders)
            curDir = dir(sectionFolders{n});
            files = {curDir(~[curDir.isdir]).name}';
            tileIndices = ~cellfun(@isempty, regexp(files, '^Tile_.*\.tif'));
            filenames = strcat(sectionFolders{n}, filesep, files(tileIndices));
            renderedAlready = exist([sectionFolders{n} filesep sectionNames{n} '.tif'], 'file');
            if ~isempty(filenames); info = imfinfo(filenames{1}); end
            tableData{n, 1} = ~renderedAlready;
            tableData{n, 2} = sectionNames{n};
            if renderedAlready; tableData{n, 3} = 'Yes'; else tableData{n, 3} = 'No'; end;
            tableData{n, 4} = length(filenames);
            if ~isempty(filenames); tableData{n, 5} = sprintf('%dx%d', info(1).Width, info(1).Height); else tableData{n, 5} = 'N/A'; end
            tableData{n, 6} = sectionFolders{n};
        end
        set(tblSections, 'Data', tableData);
    end
end 