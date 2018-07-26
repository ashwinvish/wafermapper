

%Extract Image Data out of EM-Images and save under the new name.
%#ok<*SAGROW>
format long
clear

Way = 6;
Res = '008nm';
Datensatz = 'Retina_Tests';
Wafer = 'W001_20180626';
Count = 1;
SectionThickness = 50;
DSF = 2; %DownSamplingFactor DeutschesSportFernsehen

eval(sprintf('load(''/usr/people/sstroeh/seungmount/research/sstroeh/Microscopes/EM/%s/%s/HighResImages_%s_%s/%sProgress.mat'')',Datensatz,Wafer,Wafer,Res,Wafer));
Sections=sum(waferProgress.done);
clear waferProgress

eval(sprintf('load(''/usr/people/sstroeh/seungmount/research/sstroeh/Microscopes/EM/%s/%s/MontageSetup_%s_%s.mat'')',Datensatz,Wafer,Wafer,Res));
OverlapPixel=SavedMontageParameters.TileWidth_pixels*(SavedMontageParameters.PercentTileOverlap/100);
clear waferProgress

eval(sprintf('Files = what(''/usr/people/sstroeh/seungmount/research/sstroeh/Microscopes/EM/%s/%s/HighResImages_%s_%s/%s_Sec001_Montage/'');',Datensatz,Wafer,Wafer,Res,Wafer));
Files = Files.mat;
expression = 'r[0-9]-c[0-9]';

for tmp=1:size(Files,1)
    RCsp{tmp,1} = regexp(Files{tmp,1},expression,'match');
end

expression = '[0-9]';

for tmp=1:size(RCsp,1)
    if isempty(RCsp{tmp,1})==0
        RCs{tmp,1} = regexp(RCsp{tmp,1},expression,'match');
        RC(tmp,1)=str2double(RCs{tmp,1}{1,1}{1,1});
        RC(tmp,2)=str2double(RCs{tmp,1}{1,1}{1,2});
    end
end

for SectionNo = 1:Sections
    
    for R=1:max(RC(:,1))
        
        for C=1:max(RC(:,2))
            
            if SectionNo<10
                eval(sprintf('path=''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec00%g.tif'';',Wafer,Res,C,C,Wafer,SectionNo));
                eval(sprintf('Check = exist(''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec00%g.tif'');',Wafer,Res,C,C,Wafer,SectionNo));
            elseif SectionNo<100
                eval(sprintf('path=''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec0%g.tif'';',Wafer,Res,C,C,Wafer,SectionNo));
                eval(sprintf('Check = exist(''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec0%g.tif'');',Wafer,Res,C,C,Wafer,SectionNo));
            else
                eval(sprintf('path=''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec%g.tif'';',Wafer,Res,C,C,Wafer,SectionNo));
                eval(sprintf('Check = exist(''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec%g.tif'');',Wafer,Res,C,C,Wafer,SectionNo));
            end
            
            if Check == 2
                
                info=imfinfo(path);
                if size(info,1)==2
                    infot=info(1).UnknownTags.Value;
                elseif size(info,1)==1
                    infot=info.UnknownTags.Value;
                end
                infod=info(1).FileModDate;
                
                BracketOpen{1,1} = strfind(infot,'<');
                BracketClose{1,1} = strfind(infot,'>');
                
                for Brackets=1:size(BracketOpen{1,1},2)
                    Fields{Brackets,(SectionNo*2)-1}=infot(BracketOpen{1,1}(Brackets):BracketClose{1,1}(Brackets));
                end
                for Brackets=2:size(BracketOpen{1,1},2)
                    Fields{Brackets-1,SectionNo*2}=infot(BracketClose{1,1}(Brackets-1)+1:BracketOpen{1,1}(Brackets)-1);
                end
                
                ResolutionOpen(SectionNo,1) = strfind(infot,'<Ux>');
                ResolutionClose(SectionNo,1) = strfind(infot,'</Ux>');
                Resolution(SectionNo,1) = str2double(infot(ResolutionOpen(SectionNo,1)+4:ResolutionClose(SectionNo,1)-1));
                ImageSizeOpen(SectionNo,1) = strfind(infot,'<Width>');
                ImageSizeClose(SectionNo,1) = strfind(infot,'</Width>');
                ImageSize(SectionNo,1) = str2double(infot(ImageSizeOpen(SectionNo,1)+7:ImageSizeClose(SectionNo,1)-1));
                StageXOpen(SectionNo,1) = strfind(infot,'<X units="um">');
                StageXClose(SectionNo,1) = strfind(infot,'</X>');
                StageX(SectionNo,1) = str2double(infot(StageXOpen(SectionNo,1)+14:StageXClose(SectionNo,1)-1));
                StageX2{SectionNo,C} = (infot(StageXOpen(SectionNo,1):StageXClose(SectionNo,1)+3)); %Only for test purposes.
                StageX3(SectionNo,C) = str2double(infot(StageXOpen(SectionNo,1)+14:StageXClose(SectionNo,1)-1)); %Only for test purposes.
                StageYOpen(SectionNo,1) = strfind(infot,'<Y units="um">');
                StageYClose(SectionNo,1) = strfind(infot,'</Y>');
                StageY(SectionNo,1) = str2double(infot(StageYOpen(SectionNo,1)+14:StageYClose(SectionNo,1)-1));
                StageY2{SectionNo,C} = (infot(StageYOpen(SectionNo,1):StageYClose(SectionNo,1)+3)); %Only for test purposes.
                StageY3(SectionNo,C) = str2double(infot(StageYOpen(SectionNo,1)+14:StageYClose(SectionNo,1)-1)); %Only for test purposes.
                StageZOpen(SectionNo,1) = strfind(infot,'<Z units="um">');
                StageZClose(SectionNo,1) = strfind(infot,'</Z>');
                StageZ(SectionNo,1) = str2double(infot(StageZOpen(SectionNo,1)+14:StageZClose(SectionNo,1)-1));
                ScanRotOpen(SectionNo,1) = strfind(infot,'<ScanRot units="deg">');
                ScanRotClose(SectionNo,1) = strfind(infot,'</ScanRot>');
                ScanRot(SectionNo,1) = str2double(infot(ScanRotOpen(SectionNo,1)+21:ScanRotClose(SectionNo,1)-1));
                
                DumpX{SectionNo,1}{R,C}(1,1) = StageX(SectionNo,1);
                DumpY{SectionNo,1}{R,C}(1,1) = StageY(SectionNo,1);
                DumpZ{SectionNo,1}{R,C}(1,1) = StageZ(SectionNo,1);
                DumpRot{SectionNo,1}{R,C}(1,1) = ScanRot(SectionNo,1);
                DumpRes{SectionNo,1}{R,C}(1,1) = Resolution(SectionNo,1);
                DumpIS{SectionNo,1}{R,C}(1,1) = ImageSize(SectionNo,1);
                
            else
                
                DumpX{SectionNo,1}{R,C}(1,1) = NaN;
                DumpY{SectionNo,1}{R,C}(1,1) = NaN;
                DumpZ{SectionNo,1}{R,C}(1,1) = NaN;
                DumpRot{SectionNo,1}{R,C}(1,1) = NaN;
                DumpRes{SectionNo,1}{R,C}(1,1) = NaN;
                DumpIS{SectionNo,1}{R,C}(1,1) = NaN;
                
            end
        end
    end
    if isnan(DumpX{SectionNo,1}{R,C}(1,1))==0 %Only for test purposes.
        StageX3(SectionNo,4)=StageX3(SectionNo,2)-StageX3(SectionNo,1); %Only for test purposes.
        StageX3(SectionNo,5)=StageX3(SectionNo,3)-StageX3(SectionNo,2); %Only for test purposes.
        StageY3(SectionNo,4)=StageY3(SectionNo,2)-StageY3(SectionNo,1); %Only for test purposes.
        StageY3(SectionNo,5)=StageY3(SectionNo,3)-StageY3(SectionNo,2); %Only for test purposes.
    end
end

C=1;
R=1;

for Way=Way
    
    filename=sprintf('TrakEM2Import_%s_%s_%s_%g',Datensatz,Wafer,Res,Way);
    fid=fopen(filename,'w');
    
    for SectionNo = 1:Sections
        
        if SectionNo<10
            eval(sprintf('path=''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec00%g.tif'';',Wafer,Res,C,C,Wafer,SectionNo));
            eval(sprintf('Check = exist(''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec00%g.tif'');',Wafer,Res,C,C,Wafer,SectionNo));
        elseif SectionNo<100
            eval(sprintf('path=''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec0%g.tif'';',Wafer,Res,C,C,Wafer,SectionNo));
            eval(sprintf('Check = exist(''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec0%g.tif'');',Wafer,Res,C,C,Wafer,SectionNo));
        else
            eval(sprintf('path=''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec%g.tif'';',Wafer,Res,C,C,Wafer,SectionNo));
            eval(sprintf('Check = exist(''/usr/people/sstroeh/Documents/Datas/%s_%s/r1-c%g/Tile_r1-c%g_%s_sec%g.tif'');',Wafer,Res,C,C,Wafer,SectionNo));
        end
        
        if Check==2
            
            for C=1:max(RC(:,2))
                
                if Way==1 %w/o metadata
                    
                    if C==1 && R==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=0;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=0;
                    end
                    
                    xtranslation{Way,1}{SectionNo,1}(R,C)=((DumpIS{SectionNo,1}{R,C}(1,1)-OverlapPixel)*(C-1))/2;
                    ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpIS{SectionNo,1}{R,C}(1,1)-OverlapPixel)*(R-1))/2;
                    
                elseif Way==2 %Zeiss API metadata
                    
                    if SectionNo<10
                        Meta=sprintf('/usr/people/sstroeh/seungmount/research/sstroeh/Microscopes/EM/%s/%s/HighResImages_%s_%s/%s_Sec00%g_Montage/Tile_r%g-c%g_%s_sec00%g.mat',Datensatz,Wafer,Wafer,Res,Wafer,SectionNo,R,C,Wafer,SectionNo);
                        load(Meta);
                        StageXZeiss{SectionNo,1}{R,C}(1,1)=Info.StageX_Meters*1000000;
                        StageYZeiss{SectionNo,1}{R,C}(1,1)=Info.StageY_Meters*1000000;
                    elseif SectionNo<100
                        Meta=sprintf('/usr/people/sstroeh/seungmount/research/sstroeh/Microscopes/EM/%s/%s/HighResImages_%s_%s/%s_Sec0%g_Montage/Tile_r%g-c%g_%s_sec0%g.mat',Datensatz,Wafer,Wafer,Res,Wafer,SectionNo,R,C,Wafer,SectionNo);
                        load(Meta);
                        StageXZeiss{SectionNo,1}{R,C}(1,1)=Info.StageX_Meters*1000000;
                        StageYZeiss{SectionNo,1}{R,C}(1,1)=Info.StageY_Meters*1000000;
                    else
                        Meta=sprintf('/usr/people/sstroeh/seungmount/research/sstroeh/Microscopes/EM/%s/%s/HighResImages_%s_%s/%s_Sec%g_Montage/Tile_r%g-c%g_%s_sec%g.mat',Datensatz,Wafer,Wafer,Res,Wafer,SectionNo,R,C,Wafer,SectionNo);
                        load(Meta);
                        StageXZeiss{SectionNo,1}{R,C}(1,1)=Info.StageX_Meters*1000000;
                        StageYZeiss{SectionNo,1}{R,C}(1,1)=Info.StageY_Meters*1000000;
                    end
                    
                    if C==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=StageXZeiss{SectionNo,1}{R,C}(1,1)-StageXZeiss{SectionNo,1}{R,C}(1,1);
                        ytranslation{Way,1}{SectionNo,1}(R,C)=StageYZeiss{SectionNo,1}{R,C}(1,1)-StageYZeiss{SectionNo,1}{R,C}(1,1);
                    elseif C>1
                        xDiff=((StageXZeiss{SectionNo,1}{R,C}(1,1)-StageXZeiss{SectionNo,1}{R,C-1}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1));
                        yDiff=((StageYZeiss{SectionNo,1}{R,C}(1,1)-StageYZeiss{SectionNo,1}{R,C-1}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1));
                        xtranslation{Way,1}{SectionNo,1}(R,C)=xtranslation{Way,1}{SectionNo,1}(R,C-1)-xDiff/DSF;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R,C-1)-yDiff/DSF;
                        clear xDiff yDiff
                    end
                    if R==1 && C==1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=StageYZeiss{SectionNo,1}{R,C}(1,1)-StageYZeiss{SectionNo,1}{R,C}(1,1);
                    elseif R>1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=(ytranslation{Way,1}{SectionNo,1}(R,C-1)-((StageYZeiss{SectionNo,1}{R,C}(1,1)-StageYZeiss{SectionNo,1}{R,C-1}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1)))/DSF;
                    end
                    
                    StageX3(SectionNo,C+5)=Info.StageX_Meters*1000000; %Only for test purposes.
                    StageY3(SectionNo,C+5)=Info.StageY_Meters*1000000; %Only for test purposes.
                    
                    clear Info
                    
                elseif Way==3 %Fibics metadata
                    
                    if C==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=((DumpX{SectionNo,1}{R,C}(1,1)-DumpX{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/2;
                    elseif C>1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=xtranslation{Way,1}{SectionNo,1}(R,C-1)+((DumpX{SectionNo,1}{R,C}(1,1)-DumpX{SectionNo,1}{R,C-1}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    end
                    if R==1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/2;
                    elseif R>1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R-1,C)+((DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R-1,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    end
                    
                elseif Way==4 %Fibics metadata corrected
                    
                    if C>1
                        tmpx = DumpX{SectionNo,1}{R,C}(1,1)-DumpX{SectionNo,1}{R,C-1}(1,1);
                        if tmpx>100
                            tmpx = tmpx-100;
                        elseif tmpx<0 && tmpx>=-100
                            tmpx = tmpx+100;
                        elseif tmpx<-100
                            tmpx = tmpx+200;
                        end
                        tmpy = DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C-1}(1,1);
                        if tmpy>100
                            tmpy = tmpy-100;
                        elseif tmpy<0 && tmpy>=-100
                            tmpy = tmpy+100;
                        elseif tmpy<-100
                            tmpy = tmpy+200;
                        end
                    end
                    if R==1 && C==1
                        tmpx=0;
                        tmpy=0;
                    end
                    
                    if C==1 && R==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=((DumpX{SectionNo,1}{R,C}(1,1)-DumpX{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    elseif C>1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=xtranslation{Way,1}{SectionNo,1}(R,C-1)+(tmpx/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R,C-1)+(tmpy/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    end
                    if R==1 && C==1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    elseif R>1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R-1,C)+(tmpy/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    end
                    
                elseif Way==5 %Fibics metadata corrected w/angles
                    
                    %DumpRes{SectionNo,1}{R,C}(1,1)=1;
                    %DSF=1;
                    
                    if C>1
                        tmpx = DumpX{SectionNo,1}{R,C}(1,1)-DumpX{SectionNo,1}{R,C-1}(1,1);
                        if tmpx>100
                            tmpx = tmpx-100;
                        elseif tmpx<0 && tmpx>=-100
                            tmpx = tmpx+100;
                        elseif tmpx<-100
                            tmpx = tmpx+200;
                        end
                        tmpy = DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C-1}(1,1);
                        if tmpy>50
                            tmpy = 100-tmpy;
                        elseif tmpy<-50
                            tmpy = 100+tmpy;
                        end
                    end
                    if R==1 && C==1
                        tmpx=0;
                        tmpy=0;
                    end
                    
                    if C==1 && R==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=((DumpX{SectionNo,1}{R,C}(1,1)-DumpX{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    elseif C>1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=xtranslation{Way,1}{SectionNo,1}(R,C-1)+(tmpx/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R,C-1)+(tmpy/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    end
                    if R==1 && C==1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpY{SectionNo,1}{R,C}(1,1)-DumpY{SectionNo,1}{R,C}(1,1))/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    elseif R>1
                        ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R-1,C)+(tmpy/DumpRes{SectionNo,1}{R,C}(1,1))/DSF;
                    end
                    
                elseif Way==6 %normxcorr
                    
                    if max(RC(:,2))>1 && C>=2
                        
                        close all
                        
                        tic
                        
                        if SectionNo<10
                            eval(sprintf('template = imread(''/usr/people/sstroeh/Documents/Datas/%s_%s/r%g-c%g/Tile_r%g-c%g_%s_sec00%g.tif'');',Wafer,Res,R,C,R,C,Wafer,SectionNo));
                            eval(sprintf('ori = imread(''/usr/people/sstroeh/Documents/Datas/%s_%s/r%g-c%g/Tile_r%g-c%g_%s_sec00%g.tif'');',Wafer,Res,C-1,Wafer,SectionNo));
                        elseif SectionNo<100
                            eval(sprintf('template = imread(''/usr/people/sstroeh/Documents/Datas/%s_%s/r%g-c%g/Tile_r%g-c%g_%s_sec0%g.tif'');',Wafer,Res,C,Wafer,SectionNo));
                            eval(sprintf('ori = imread(''/usr/people/sstroeh/Documents/Datas/%s_%s/r%g-c%g/Tile_r%g-c%g_%s_sec0%g.tif'');',Wafer,Res,C-1,Wafer,SectionNo));
                        else
                            eval(sprintf('template = imread(''/usr/people/sstroeh/Documents/Datas/%s_%s/r%g-c%g/Tile_r%g-c%g_%s_sec%g.tif'');',Wafer,Res,C,Wafer,SectionNo));
                            eval(sprintf('ori = imread(''/usr/people/sstroeh/Documents/Datas/%s_%s/r%g-c%g/Tile_r%g-c%g_%s_sec%g.tif'');',Wafer,Res,C-1,Wafer,SectionNo));
                        end
                        
                        ori = ori(1:end,4145:end);
                        template = template(1:end,1:150);
                        
                        %                             figure(1)
                        %                             imshow(ori)
                        %                             tmpf1 = get(gcf,'OuterPosition');
                        %                             set(gcf,'OuterPosition',[-1870 101 tmpf1(3) tmpf1(4)]);
                        %                             drawnow
                        %
                        %                             figure(2)
                        %                             imshow(template)
                        %                             tmpf2 = get(gcf,'OuterPosition');
                        %                             set(gcf,'OuterPosition',[-1370 101 tmpf2(3) tmpf2(4)]);
                        %                             drawnow
                        
                        c = normxcorr2(template,ori);
                        csave{SectionNo}(R,C) = max(c(:));
                        
                        %                                 figure(3)
                        %                                 set(gcf,'Visible','off')
                        %                                 surf(c(1:10:end,1:10:end)), shading flat
                        %                                 imagesc(c);
                        %                                 hold on
                        %                                 tmpf3 = get(gcf,'OuterPosition');
                        %                                 set(gcf,'OuterPosition',[-1070 301 tmpf3(3) tmpf3(4)]);
                        
                        [ypeak, xpeak] = find(c==max(c(:)));
                        
                        yoffSet = ypeak-size(template,1);
                        xoffSet = xpeak-size(template,2)+4144;
                        
                        %                                 plot(xpeak,ypeak,'r.','MarkerSize',10)
                        %                                 plot(xpeak,ypeak,'ro','MarkerSize',10)
                        %                                 drawnow
                        %                                 eval(sprintf('print(gcf,''-r100'',''-dpng'',''-painters'',''TrakEM2Import_%s_%s_%s_%g_%g_%g'');',Datensatz,Wafer,Res,SectionNo,R,C));
                        %                                 axis([xpeak-74 xpeak+75 ypeak-74 ypeak+75])
                        %                                 eval(sprintf('print(gcf,''-r100'',''-dpng'',''-painters'',''TrakEM2Import_%s_%s_%s_%g_%g_%gz'');',Datensatz,Wafer,Res,SectionNo,R,C));
                        
                        if C==2
                            xtranslation{Way,1}{SectionNo,1}(R,C)=xoffSet;
                            ytranslation{Way,1}{SectionNo,1}(R,C)=yoffSet;
                        elseif C>2
                            xtranslation{Way,1}{SectionNo,1}(R,C)=xtranslation{Way,1}{SectionNo,1}(R,C-1)+xoffSet;
                            ytranslation{Way,1}{SectionNo,1}(R,C)=ytranslation{Way,1}{SectionNo,1}(R,C-1)+yoffSet;
                        end
                        
                        t=toc;
                        
                        fprintf('%g|%g|%g->%g\n',SectionNo,R,C-1,C);
                        
                    end
                    
                    if C==1 && R==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=0;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=0;
                    end
                    
                end
                
                if SectionNo == Sections && R == max(RC(:,1)) && C == max(RC(:,2))
                    fprintf(fid,'%s\t%g\t%g\t%g',path(end-25:end),xtranslation{Way,1}{SectionNo,1}(R,C),ytranslation{Way,1}{SectionNo,1}(R,C),SectionThickness/((DumpRes{SectionNo}{R,C}(1,1)*1000))*(SectionNo-1));
                else
                    fprintf(fid,'%s\t%g\t%g\t%g\n',path(end-25:end),xtranslation{Way,1}{SectionNo,1}(R,C),ytranslation{Way,1}{SectionNo,1}(R,C),SectionThickness/((DumpRes{SectionNo}{R,C}(1,1)*1000))*(SectionNo-1));
                end
            end
            
            for R=1:max(RC(:,1))
                
                if Way==1
                    
                    if C==1 && R==1
                        xtranslation{Way,1}{SectionNo,1}(R,C)=0;
                        ytranslation{Way,1}{SectionNo,1}(R,C)=0;
                    end
                    
                    xtranslation{Way,1}{SectionNo,1}(R,C)=((DumpIS{SectionNo,1}{R,C}(1,1)-OverlapPixel)*(C-1))/2;
                    ytranslation{Way,1}{SectionNo,1}(R,C)=((DumpIS{SectionNo,1}{R,C}(1,1)-OverlapPixel)*(R-1))/2;
                    
                end
                
            end
        end
        
        
        
    end
    if isnan(DumpX{SectionNo,1}{R,C}(1,1))==0 && Way==2 %Only for test purposes.
        StageX3(SectionNo,9)=StageX3(SectionNo,7)-StageX3(SectionNo,6); %Only for test purposes.
        StageX3(SectionNo,10)=StageX3(SectionNo,8)-StageX3(SectionNo,7); %Only for test purposes.
        StageY3(SectionNo,9)=StageY3(SectionNo,7)-StageY3(SectionNo,6); %Only for test purposes.
        StageY3(SectionNo,10)=StageY3(SectionNo,8)-StageY3(SectionNo,7); %Only for test purposes.
    end
    
    fclose(fid);
    %open(filename);
    
end

format short

USure=0;
if USure==1
    
    for tmp=1:size(xtranslation{1,1},1)
        
        for tmp2=1:size(xtranslation{1,1}{tmp,1},2)
            
            x(tmp,tmp2)=xtranslation{1,1}{tmp,1}(1,tmp2);
            
        end
        
    end
    
    plot(x(:,2))
    figure(2)
    hist(x(:,2))
    x2=abs(x);
    figure(3)
    plot(x2(:,2))
    figure(4)
    hist(x2(:,2))
    
end