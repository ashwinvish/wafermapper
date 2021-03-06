function [relscales,relangles,reldx,reldy,goodmatrix]=extract_relative_rigid(transforms,numinlier,inlier_thresh)
%takes a ZxZ cell array of similarity "transforms" between different sections
%of the same stack, and extracts their
%relative scale factors, angular rotations, and translations
%it does this for only the tranforms which were produced with "numinliers"
%greater than "inlier_thresh".  Numinliers is thus also a ZxZ matrix with
%the number of inliers, and inlier_thresh is the minimum number of
%tranformation needed.  It assumes that "transforms" is upper right
%triangular, but then infers the relative angle shift, scale factor and
%offset of the lower left triangle of the matrix by simple inversion of the
%transformation.
%
%it returns relscales, a ZxZ matrix of scale factors which describe how
%section from row i must be transformed into the section in column j.
%similarly returns relangles, reldx, and reldy for the angular rotation,and
%x,y translation.  
%
%it also returns goodmatrix, which in a binary ZxZ matrix which contains a
%1 for the comparisions for which there is data.

if ~exist('inlier_thresh','var')
    inlier_thresh=15;
end
goodones=find(numinlier>inlier_thresh);

relscales=zeros(size(numinlier));
relangles=zeros(size(numinlier));
reldx=zeros(size(numinlier));
reldy=zeros(size(numinlier));
goodmatrix=numinlier>inlier_thresh;

for ind=1:length(goodones)
   k=goodones(ind);
   [p1,p2]=ind2sub(size(numinlier),k);
   goodmatrix(p2,p1)=goodmatrix(p1,p2);
   trans=transforms{p1,p2};
   fieldnames(trans.tdata);
   
   if length(fieldnames(trans.tdata))==2
       M=trans.tdata.T;
       R=M(1:2,1:2); 
       relscales(p1,p2)=sqrt(det(R));
       relscales(p2,p1)=1.0/relscales(p1,p2);
       R=R/sqrt(det(R));
       relangles(p1,p2)=atan2(R(1,2),R(1,1));
       relangles(p2,p1)=-relangles(p1,p2);
       
       reldx(p1,p2)=M(3,1)/relscales(p1,p2);
       reldy(p1,p2)=M(3,2)/relscales(p1,p2);
       reldx(p2,p1)=-M(3,1)/relscales(p2,p1);
       reldy(p2,p1)=-M(3,2)/relscales(p2,p1);
   else
       relscales(p1,p2)=1.0;
       relangles(p1,p2)=0.0;
       relangles(p2,p1)=0.0;
       reldx(p1,p2)=0;
       reldy(p1,p2)=0;
       reldx(p2,p1)=0;
       reldy(p2,p1)=0;
   end
   
end
relangles=180*relangles/pi; %convert to degrees