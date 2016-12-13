
SPN = 'D:\LGNs1\Overviews\AnalyzedOverviews\mexHat1\';
TPN = 'D:\LGNs1\Overviews\AnalyzedOverviews\mexHat1_segment\';

dSPN = dir(SPN); dSPN = dSPN(3:end);

iNams = {};
for i = 1:length(dSPN)
   nam = dSPN(i).name;
   if ~isempty(regexp(nam,'.jpg'));
      iNams{length(iNams)+1} = nam;
   end
end
    
%%
Iinfo = imfinfo([SPN iNams{1}]);
I = zeros(Iinfo.Height,Iinfo.Width,length(iNams),'uint8');
for i = 1:length(iNams)
    if ~mod(i,100)
        disp(sprintf('Reading %d of %d',i,length(iNams)))
    end
    I(:,:,i) = imread([SPN iNams{i}]);
end

%%
sI = I(500:600,500:600,500:600);
sI = double(sI);
sumI = sum(sI,3);
image(sumI * 256/max(sumI(:)));

%% Watershed




