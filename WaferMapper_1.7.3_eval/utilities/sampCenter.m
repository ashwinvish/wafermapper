

SPN = 'G:\joshm\LGNs1\rawMontages_Retakes\';
TPN = 'G:\joshm\LGNs1\Processed_Retakes\';

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
    
    for t = 1:length(dMon);
        nam = dMon(t).name;
        if sum(regexp(nam, 'Tile_'))& sum(regexp(nam,'.tif'));
            newName = [wTPN '\' nam];
            %if ~exist(newName,'file') 
                I = imread([SPN folderList{i} '\' nam],'PixelRegion',{iRange,iRange});
                imwrite(I,newName);
            %end
        end
    end
end
    
    