

TPN = GetMyDir
writeTPN = GetMyDir


dTPN = dir(TPN); dTPN = dTPN(3:end);

listDir = {};
for i = 1:length(dTPN)
   if dTPN(i).isdir
       listDir{length(listDir)+1} = dTPN(i).name;
   end
end

%%
secSum = 0;
for i = 1:length(listDir)
    wafDir = listDir{i}
    dWaf = dir([TPN wafDir]); dWaf = dWaf(3:end);
    for s = 1:length(dWaf);
        nam = dWaf(s).name;
        if ~isempty(regexp(nam,'.jpeg'))
            secSum = secSum+1;
           [success, message]= copyfile([TPN wafDir '\' nam], [writeTPN 'sec_' zeroBuf(secSum,5) '.jpg']);
        end
    end
end
