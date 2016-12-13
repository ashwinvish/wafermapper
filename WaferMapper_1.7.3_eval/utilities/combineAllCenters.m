

SPN1 = 'D:\LGNs1\Processed_SecondRetakes\allCenters\';
SPN2 = 'G:\joshm\LGNs1\Processed\allCenters\';
TPN =  'D:\LGNs1\Processed_SecondRetakes\allCenters_combined\'

if ~exist(TPN,'dir')
    mkdir(TPN)
end

%%
iList = dir([SPN1 '*.tif']);
i = 0;
for notI = 1:length(iList);
    
    nam = iList(notI).name;
    if length(regexp(nam,'_'))==3
        i = i + 1;
    
    newName = [TPN nam];
        compName = nam;
        
        
        wP = regexp(nam,'_w0');
        w = nam(wP+3:wP+4);
        rP = regexp(nam,'_r');
        r = nam(rP+2:rP+2);
        cP = regexp(nam,'-c');
        c = nam(cP+2:cP+2);
        sP = regexp(nam,'_sec');
        s = nam(sP+4:sP+6);
        
        crapName = sprintf('w0%s_s%s_r%s_c%s.tif',w,s,r,c);
        N2{i} = crapName;
        N1{i} = compName;
        orderNum(i) = str2num(sprintf('%s%s%s%s',w,s,r,c));
        secNum(i) = str2num(sprintf('%s%s',w,s));
    end
end
%% sort

[sorted idx] = sort(orderNum);


%%
oldSec = 0;
c = 0;
for i = 1:length(idx);
    c = c+1;
    
    
    targ = idx(i);
    
    newSec = secNum(targ);
    
    if newSec ~= oldSec
        IC = uint8(rand(1024,1024)*255);
        imwrite(IC,[TPN sprintf('%07.0f_spacer.tif',c)],'Compression','none')
        c = c+1;
    end
    oldSec = newSec;
        
        
    crapName = N2{targ};
    compName = N1{targ};
    newName = sprintf('%07.0f_%s',c,crapName);

    if ~exist([TPN newName],'file')
        
        I1 = imread([SPN1 compName]);
                try  I2 = imread([SPN2 crapName]);
                catch err
                    I2 = I1*0;
                end
        
        IC = cat(1,256-I1,I2);
        imwrite(IC,[TPN newName],'Compression','none')
        if ~mod(i,100),disp(sprintf('%d of %d',i,length(iList))), end
    end
    
end
       

