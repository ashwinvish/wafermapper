%% Make manual retake list

%%Enter list
manualRetakeList = ...
    [108 109 158];
manualRetakeList = unique(manualRetakeList);
manualRetakeList = sort(manualRetakeList,'ascend');
TPN = GetMyDir;


save([TPN 'manualRetakeList.mat'],'manualRetakeList');

%{ 
%Check remaining

[TFN TPN] = GetMyFile



%}

