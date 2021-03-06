%% Turn mosaics from waffer into viewable (centers and downsample) mosaics

%% Get Waffer folder information
wif = GetMyWafer;


lnam = wif.log{end};
logF = textscan(lnam, '%s')

F=fopen(lnam,'r')
scanLog = textscan(F, '%s','Delimiter',';')
logF = scanLog{1};



A = fread(F, inf, 'char') 


%% View stitched

%% Parse XML
[tree, rootname, dom]=xml_read(wif.xml{end});
overlap = tree.MosaicSetup.TileOverlapXum;
xs = tree.MosaicSetup.TileWidth;
ys = tree.MosaicSetup.TileHeight;
res = tree.MosaicSetup.PixelSize;
pixelOverlap = fix(overlap / res * 1000);

%% Target Dir 
TPN = wif.dir; TPN = [TPN(1:end-1) 'shaped\'];
TPNdown = [TPN 'downsamp\'];
if ~exist(TPNdown),mkdir(TPNdown);end

%% stitch downSampled
colormap gray(256)
dSamp = 10;
csize = length(dSamp:dSamp:xs-pixelOverlap);
esize = length(1:dSamp:xs);

for s = 1 : length(wif.sec) % run sections
    sprintf('reading tile %d of %d',s,length(wif.sec))
    rc = wif.sec(s).rc;
    mosDim = max(rc,[],1);
    %[tree, rootname, dom]=xml_read(wif.sec(s).xml);
    mos = zeros((mosDim-1)*csize+esize,'uint8');
    for t = 1:length(wif.sec(s).tile)

        ystart = (rc(t,1)-1)*csize+1;
        xstart = (rc(t,2)-1)*csize+1;
        if rc(t,1)==mosDim(1),yLap = 0; ysize = esize; else yLap = pixelOverlap; ysize = csize; end
        if rc(t,2)==mosDim(2),xLap = 0; xsize = esize; else xLap = pixelOverlap; xsize = csize; end
        I = imread(wif.sec(s).tile{t},'PixelRegion',{[1 dSamp ys-yLap],[1 dSamp xs-xLap]});
        mos(ystart:ystart+size(I,1)-1,xstart:xstart+size(I,2)-1) = 255-I;
    
    end
    image(mos),pause(.1)
    imwrite(mos,[TPNdown wif.secNam{s} '.tif'],'Compression','none')
end










