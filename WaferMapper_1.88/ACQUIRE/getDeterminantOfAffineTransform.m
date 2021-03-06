function determinant=getDeterminantOfAffineTransform(tform)

if isfield(tform.tdata,'T')
    R=tform.tdata.T(1:2,1:2);
    determinant=det(R);
else
    R=tform.tdata.tshifted.tdata.T(1:2,1:2);
    determinant=det(R);
end
