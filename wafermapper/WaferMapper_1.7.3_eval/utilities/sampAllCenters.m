

SPN = 'G:\joshm\LGNs1\rawMontages_SecondRetake\';
TPN = 'D:\LGNs1\Processed_SecondRetakes\allCenters\';
if ~exist(TPN,'dir')
    mkdir(TPN)
end


iRange = {[12545 13056],[12289 13312]};

dSPN = dir(SPN); dSPN = dSPN(3:end);

WaferNum = 'w0';
folderList = {};
for i = 1:length(dSPN)
    nam = dSPN(i).name;
    if sum(regexp(nam,WaferNum))&& dSPN(i).isdir
        folderList{length(folderList)+1} = nam;
    end
end

pass = ones(length(folderList));
parfor i= 1:length(folderList)
    dMon = dir([SPN folderList{i}]); dMon = dMon(3:end);
    
    for t = 1:length(dMon);
        nam = dMon(t).name;
        if sum(regexp(nam, 'Tile_'))& sum(regexp(nam,'.tif'));
            newName = [TPN '\' nam];
            if ~exist(newName,'file')
                    disp(sprintf('%d of %d',i,length(folderList)))

                try
                    I = imread([SPN folderList{i} '\' nam],'PixelRegion',iRange);
                catch err
                    'failed to read'
                    pause
                    pass(i) = 0;
                end
                if pass(i)
                    imwrite(I,newName,'Compression','none');
                end
            end
        end
    end
end

