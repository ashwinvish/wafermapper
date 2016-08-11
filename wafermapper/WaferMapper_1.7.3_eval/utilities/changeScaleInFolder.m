%% change scale of all images in folder



TPN = GetMyDir;

scaleDif = 4575/4096;


dTPN = dir(TPN); dTPN = dTPN(3:end);

for i = 1:length(dTPN)
    nam = dTPN(i).name;
    if ~isempty(regexp(nam,'.tif'))
        I = imread([TPN nam]);
        
        Iscale = imresize(I,scaleDif);
        [oldys oldxs] = size(I);
        [newys newxs] = size(Iscale);
        if scaleDif>1
            shiftY = fix((newys-oldys)/2);
            shiftX = fix((newxs-oldxs)/2);
            Iscale2 = I * 0;
            Iscale2 = Iscale(shiftY + 1:shiftY+oldys,shiftX+1:shiftX + oldxs);
        elseif  scaleDif <= 1
            shiftY = -fix((newys-oldys)/2);
            shiftX = -fix((newxs-oldxs)/2);
            Iscale2 = I * 0 + median(I(:));
            Iscale2(shiftY + 1:shiftY+newys,shiftX+1:shiftX + newxs) =  Iscale;
            
        end
        
        col = I;
        col(:,:,2) = Iscale2;
        col(:,:,3) = Iscale2;
        image(uint8(col)),pause(.01)
        
        imwrite(Iscale2,[TPN nam],'Compression','none');

    end % if file is a tif
    
    
end


