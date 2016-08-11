function[Imf] = mexHatFlex(I,mexHatVar);

%% process I
kSize = mexHatVar.kernSize ;
s1 =mexHatVar.cent;
s2 = mexHatVar.surround;

kRad = (kSize + 1)/2;
kern = zeros(kSize);

[y x z] = ind2sub(kSize,find(kern==0));
dists = sqrt(((y-kRad(1))).^2 + ((x - kRad(2))).^2);

cKern = 1 * exp(-.5 * (dists/s1).^2);
cKern = cKern/sum(cKern(:));
sKern = 1 * exp(-.5 * (dists/s2).^2);
sKern = sKern/sum(sKern(:));
kern(:) = cKern - sKern;

% subplot(2,1,1)
% plot(kern(round(kRad(1)),:))

%% Convolve

Itemp = fastCon(I,kern);
pixClip = mexHatVar.clipEdge;
Imf  = Itemp * 0;
Imf(pixClip +1:end-pixClip,pixClip +1:end-pixClip)=Itemp(pixClip +1:end-pixClip,pixClip +1:end-pixClip);
Imf(Imf<0)=0;
