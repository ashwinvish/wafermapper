clear
close all
for SectionNo=1:220
    if SectionNo<10
        p=imread(sprintf('Z:\sstroeh\Microscopes\EM\Retina_Tests\W001_20180626\HighResImages_W001_20180626_004nm\W001_20180626_Sec00%g_Montage\Tile_r1-c1_W001_20180626_sec00%g.tif',SectionNo),'PixelRegion',{[1 500],[1 500]});
    elseif SectionNo<100
        p=imread(sprintf('Z:\sstroeh\Microscopes\EM\Retina_Tests\W001_20180626\HighResImages_W001_20180626_004nm\W001_20180626_Sec0%g_Montage\Tile_r1-c1_W001_20180626_sec0%g.tif',SectionNo),'PixelRegion',{[1 500],[1 500]});
    else
        p=imread(sprintf('Z:\sstroeh\Microscopes\EM\Retina_Tests\W001_20180626\HighResImages_W001_20180626_004nm\W001_20180626_Sec%g_Montage\Tile_r1-c1_W001_20180626_sec%g.tif',SectionNo),'PixelRegion',{[1 500],[1 500]});
    end
end
figure(1)
imshow(p);
Focus(SectionNo,1)=input('1/0? ');
