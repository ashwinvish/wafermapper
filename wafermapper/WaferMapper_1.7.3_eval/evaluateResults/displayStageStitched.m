%function[] = displayStageStitched()
%% display most recent stage stitched quality image
%% move stage stitched images to processed folder (TPN stage stitched)

SPN =  'D:\LGNs1\rawMontages_folderRetake\'
TPN = 'D:\LGNs1\Processed_Retakes\'
VPN = 'V:\RawMontages\'; %scope directory

while 1
   
    dSPN = dir(SPN); dSPN = dSPN(3:end);
    times = [dSPN.datenum];
    names = {dSPN.name};
    check = find([dSPN.isdir]);
    times = times(check);
    names = names(check);
    
    [sortTimes dirOrder] = sort(times,'descend');
    targ = check(find(times == max(times),1));
    for i = 1:length(dirOrder)
        nam = names{dirOrder(i)};
        if ~isempty(regexp(nam,'_Montage'));
            secNam = [SPN nam];
            und = regexp(nam,'_');
            waferName = nam(1:und(1)-1);
            
            break
        end
    end
    stitchedName = ['StageStitched_' lower(nam(1:und(2)-1)) '_WithQualVals.fig'];
   
    disp(sprintf('Last directory found is %s ',secNam))
    
    if exist([VPN nam '\' stitchedName],'file')
        stitchedFile = [VPN nam '\' stitchedName];
    elseif exist([SPN nam '\' stitchedName],'file')
        stitchedFile = [SPN nam '\' stitchedName];
    end
    
    stitchedFileInfo = dir(stitchedFile)
        if length(stitchedFileInfo) == 1
        close(gcf)
            try
                open(stitchedFile);
            catch err
                err
            end
        text(-100,-10,sprintf('%s    written at    %s',dSPN(targ).name,datestr(stitchedFileInfo.datenum)))
        else
           disp('No figure found') 
        end
        
        checkWaferQuality(SPN,TPN,waferName)

        
        pause(30)
        
    
    
end