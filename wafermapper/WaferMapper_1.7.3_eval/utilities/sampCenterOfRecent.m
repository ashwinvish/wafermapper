
WaferNum = 'w002';
SPN = 'D:\LGNs1\rawMontages_folder2\';
TPN = 'D:\LGNs1\Processed\lastCenterSamples\';

wTPN = [TPN WaferNum];
if ~exist(wTPN,'dir');
    mkdir(wTPN)
end

iRange = [13000 13500];

dSPN = dir(SPN); dSPN = dSPN(3:end);

folderList = {};
for i = 1:length(dSPN)
    nam = dSPN(i).name;
    if sum(regexp(nam,WaferNum))&& dSPN(i).isdir
       folderList{length(folderList)+1} = nam;
    end   
end

for i = 1:length(folderList)
    
    dMon = dir([SPN folderList{i}]); dMon = dMon(3:end);
    
    tileNam = {}; tileTime = [];
    for t = 1:length(dMon);
        nam = dMon(t).name;
        if sum(regexp(nam, 'Tile_'))& sum(regexp(nam,'.tif'));
            %if ~exist(newName,'file') 
                tileNam{length(tileNam)+1} = nam;
                tileTime(length(tileNam)) = dMon(t).datenum;
                
           % end
        end
    end
    
    targ = find(tileTime == max(tileTime));
    newName = [wTPN '\' tileNam{targ}];

    I = imread([SPN folderList{i} '\' tileNam{targ}],'PixelRegion',{iRange,iRange});
                imwrite(I,newName);
end


    

    