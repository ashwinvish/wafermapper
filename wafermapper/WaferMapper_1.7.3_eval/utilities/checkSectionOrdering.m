%% Check section ordering

%SPN = GetMyDir


%% Find tifs
dSPN = dir(SPN); dSPN = dSPN(3:end);
inam = {};
for i = 1:length(dSPN)
   nam = dSPN(i).name;
   if sum(regexp(nam,'.tif'));
       inam{length(inam)+1,1} = nam;
   end
end


%%



%%



numSec = length(inam);
compTo = [1 2];
allC = zeros(numSec,length(compTo));
for i = 1:numSec;
    
    refI = double(imread([SPN inam{i}]));
    for c = 1:length(compTo)
        checkI = i+compTo(c)
        if (checkI >0 ) && (checkI <= length(inam))
            compI = double(imread([SPN inam{checkI}]));
            crossI = refI.*compI;
            crossI = sum(crossI(:))/(sum(refI(:))*sum(compI(:)));
            allC(i,c) = crossI;
        else
            allC(i,c) = 0;
        end
    end
end
    
%%

for i = 1:size(allC,1)
    maxC(i,:) = allC(i,:) == max(allC(i,:));
end




