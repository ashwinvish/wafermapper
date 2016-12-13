%%Compare qualities of multiply taken tiles to identify best.


SPN = GetMyDir

%% Make list based on logBooks
%if ~exist([SPN 'BadRetakeFromLogBookList.mat'],'file')
    
    logDir = ['D:\LGNs1\rawMontages_folder2\logBooks']
    dLogDir = dir(logDir); dLogDir = dLogDir(3:end);
    
    logList = {};
    for i = 1:length(dLogDir)
        nam = dLogDir(i).name;
        if sum(regexp(nam,'LogBook_'))
           logList{length(logList)+1} = nam; 
        end
    end
    
        gotWorse = {};
        badImages = {};
    for i = 1:length(logList)
        sprintf('running %s, wafer %d of %d',logList{i},i,length(logList))
       load([logDir '\' logList{i}]); 
      
        tileNames = cat(1,logBook.sheets.quality.data(:,1));
        qualities = cat(1,logBook.sheets.quality.data{:,3});
            
            %%parse logbook to find failed final tiles
            
            %%find all retakes
            [uTiles ia ic] = unique(tileNames);
            for t = 1:length(uTiles)
                quals = qualities(ic == t) ;
                if max(quals) > (quals(end)+quals(end)/20) %last image is not the best
                    gotWorse{length(gotWorse)+1} = uTiles{t};
                    worseQuals{length(gotWorse)} = quals;
                    quals
                end
                if quals(end)<100
                    badImages{length(badImages)+1} = uTiles{t};
                end
            end
       
        
    end  %run all logbook files
    
    BadImagesFromLog.badImages = badImages;
    BadImagesFromLog.gotWorse = gotWorse;
    BadImagesFromLog.worseQuals = worseQuals;
    save([SPN 'BadImagesFromLog.mat'],'BadImagesFromLog')
%     
%     
    %save([SPN 'BadRetakeFromLogBookList.mat'],'gotWorse')
%     
% else
%     load([SPN 'BadRetakeFromLogBookList.mat'])
% end

%%
for i = 1:length(gotWorse)
    
end


%%
%{
missingTile = {};
for t = 1:length(gotWorse)
    tNam = gotWorse{t};
    slashes = regexp(tNam,'\');
    secNam = tNam(slashes(2)+1:slashes(3)-1);
    tileNam = tNam(slashes(3)+1:end-4);
    waf = str2num(secNam(2:4));
    if sum(find(allWafs == waf))
        
        
        if exist([SPN secNam],'dir')
            dSec = dir([SPN secNam])
            tilesToCheck = {};
            for f = 1:length(dSec)
                nam = dSec(f).name;
                if sum(regexp(nam,tileNam)) & sum(regexp(nam,'.tif'))
                    tilesToCheck{length(tilesToCheck)+1} = nam;
                end
            end
            
            if ~isempty(tilesToCheck)
                qualChecked = [];
                for tc = 1:length(tilesToCheck)
                    qualVal = checkFileQual([SPN secNam '\' tilesToCheck{tc}])
                    qualChecked(tc) = qualVal.quality;
                end
                bestQual{t} = tilesToCheck{find(qualChecked == max(qualChecked),1,'last')}
                
                
            else
                missingTile{length(missingTile)+1,1} = tileNam;
            end
            
            
        else
            
            
            
        end
    end
end

save([SPN 'BadRetakeFromQualityCheck.mat'],'bestQual')
%}