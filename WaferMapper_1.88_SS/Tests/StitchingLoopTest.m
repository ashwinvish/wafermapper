clear
close all

ActualxcTranslation=0:92:460;
ActualycTranslation=0:10:50;
ActualyrTranslation=0:90:270;
ActualxrTranslation=0:-5:-15;

for C=1:6
    for R=1:4
        if C==1 || C==1
            xctranslation(R,C)=0;
            yctranslation(R,C)=0;
        end
        if C>1
            xctranslation(R,C)=ActualxcTranslation(C);
            yctranslation(R,C)=ActualycTranslation(C);
        end
        if R>1
            xrtranslation(R,C)=ActualxrTranslation(R);
            yrtranslation(R,C)=ActualyrTranslation(R);
        end
    end
end

xtranslation=xctranslation+xrtranslation;
ytranslation=yctranslation+yrtranslation;

figure(1);set(gcf,'OuterPosition',[-900 100 570 450]);
axis([-50 1000 -1000 50])
axis square
hold on
for C=1:6
    for R=1:4
        plot([xtranslation(R,C) 100+xtranslation(R,C)],[-ytranslation(R,C) -ytranslation(R,C)],'b-');
        pause(0.015)
        plot([100+xtranslation(R,C) 100+xtranslation(R,C)],[-ytranslation(R,C) -ytranslation(R,C)-100],'b-');
        pause(0.015)
        plot([xtranslation(R,C) 100+xtranslation(R,C)],[-ytranslation(R,C)-100 -ytranslation(R,C)-100],'b-');
        pause(0.015)
        plot([xtranslation(R,C) xtranslation(R,C)],[-ytranslation(R,C) -ytranslation(R,C)-100],'b-');
        pause(0.015)
    end
end
