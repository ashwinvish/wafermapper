
SPN = 'D:\LGNs1\Overviews\PSCoverviewAlignment2\'
TPN = 'D:\LGNs1\Overviews\AnalyzedOverviews\'

processedFolder = 'mexHat1';
PPN = [TPN processedFolder '\'];
if ~exist(PPN,'dir')
    mkdir(PPN)
end

colormap gray(256)
dSPN = dir(SPN); dSPN = dSPN(3:end);

mexHatVar.kernSize = [200 200];
mexHatVar.cent = 2;
mexHatVar.surround = 20;
mexHatVar.clipEdge = 0;


for i = 1:length(dSPN)
    nam = dSPN(i).name;
     
   if regexp(nam,'.jpg')
      if ~exist([PPN nam],'file')
      disp(nam)
      
      I = imread([SPN nam]);
      fI = mexHatFlex(I,mexHatVar);
      tI = (fI - mean(fI(fI>0)))>0;
      lI = bwlabel(tI,8);
      edgeObjects = unique(cat(1,lI(:,1), lI(:,end),...
          lI(end,:)', lI(1,:)'));
      mI = fI;
      for eO = 1:length(edgeObjects);
          mI(lI == edgeObjects(eO)) = 0;
      end
      
%       propI = regionprops(lI,'Area');
%       Areas = cat(1,propI.Area);
%       tooBig = find(Areas>50000);
%       mI = fI;
%       for tB = 1:length(tooBig)
%           mI(lI == tooBig(tB)) = 0;
%       end
      imwrite(uint8(mI),[PPN nam])
%       
%       subplot(1,2,1)
%       image(I)
%       subplot(1,2,2)
%       image(mI* 256/max(fI(:)))
%       pause(.01)
       end % if image does not already exist
   end %if jpg
      
    
    
end