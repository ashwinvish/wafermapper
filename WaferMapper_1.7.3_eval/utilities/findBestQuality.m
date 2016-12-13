%%Compare qualities of multiply taken tiles to identify best.

SPN = 'D:\LGNs1\rawMontages_folder2\'; %source

dSPN = dir(SPN); dSPN = dSPN(3:end);

%% find wafers
c = 0;
clear wafNum sectionList
for i = 1:length(dSPN)
    nam = dSPN(i).name;
    secExp = regexp(nam,'_Sec');
    if secExp == 5
        c = c + 1;
        wafNum(c)= str2num(nam(2:4));
        sectionList{c} = nam;
    end
end

allWafs = sort(unique(wafNum),'descend')
%%


%% Make list based on logBooks
if ~exist([SPN 'BadRetakeFromLogBookList.mat'],'file')
    
    logDir = ['D:\LGNs1\rawMontages_folder2\logBooks']
    gotWorse = {};
    for i = 1:length(allWafs)  %check all wafers
        w = allWafs(i);
        disp(sprintf('checking wafer %d of %d',i,length(allWafs)))
        
        bookName = sprintf('LogBook_w%03d.mat',w);
        if exist([logDir '\' bookName]) %if book exists
            load([logDir '\' bookName])
            
            tileNames = cat(1,logBook.sheets.quality.data(:,1));
            qualities = cat(1,logBook.sheets.quality.data{:,3});
            
            %%parse logbook to find failed final tiles
            
            %%find all retakes
            [uTiles ia ic] = unique(tileNames);
            for t = 1:length(uTiles)
                quals = qualities(ic == t) ;
                if max(quals) ~= quals(end) %last image is not the best
                    
                    gotWorse{length(gotWorse)+1} = uTiles{t};
                    quals
                end
                
            end
            
        end
    end
    
    
    save([SPN 'BadRetakeFromLogBookList.mat'],'gotWorse')
    
else
    load([SPN 'BadRetakeFromLogBookList.mat'])
end

%%
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
