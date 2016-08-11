

%% Get tile information
sectionIDs = [1 2];  %fake input
tileIDs = [3 1];
wif = GetMyWafer;

for i = 1:length(sectionIDs)
    
    xnam = wif.sec(sectionIDs(i)).xml; 
    [tree, rootname, dom]=xml_read(xnam); 
    tile(i) = tree.Tiles.Tile(tileIDs(i));  %must use correct tile ID
   
end