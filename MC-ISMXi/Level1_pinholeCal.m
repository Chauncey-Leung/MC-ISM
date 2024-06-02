app.SETUP.upfactor = app.UpfactorEditField.Value;
app.SETUP.range = app.RangeEditField.Value;
app.SETUP.extent = app.ExtentEditField.Value;
app.SETUP.reference = app.ReferenceDropDown.Value;
if  app.AlreadyknowthebasicvectorsCheckBox.Value
    app.SETUP.vec_estimate_manual = [str2num(app.v_f1xv_f1yEditField.Value);
                                    str2num(app.v_f2xv_f2yEditField.Value)];
else
    app.SETUP.vec_estimate_manual = [0, 0; 0, 0];
end

filepath = app.file_path;
filepath_ALN = [filepath, '\pinhole_ALN'];
fileinfo_ALN = dir(filepath_ALN);

fp = strcat(filepath_ALN, '\', fileinfo_ALN(3).name);
imginfo = imfinfo(fp);
Width = imginfo.Width * app.SETUP.upfactor;
Height = imginfo.Height * app.SETUP.upfactor;
Counts = length(fileinfo_ALN) - 2;
MaxLength = max(Width, Height);
app.SETUP.imgStack = zeros(MaxLength, MaxLength, Counts);
for imgIdx = 1 : Counts
    fp = strcat(filepath_ALN, '\', fileinfo_ALN(imgIdx+2).name);
    temp = double(imread(fp));
    if app.SETUP.upfactor == 2
        temp = imresize(temp, 2, 'bilinear');
    elseif app.SETUP.upfactor == 4
        temp = imresize(temp, 2, 'bilinear');
        temp = imresize(temp, 2, 'bilinear');
    elseif app.SETUP.upfactor == 8
        temp = imresize(temp, 2, 'bilinear');
        temp = imresize(temp, 2, 'bilinear'); 
        temp = imresize(temp, 2, 'bilinear'); 
    end

    if Width > Height
        temp = padarray(temp, [(Width-Height)/2,0], 'both');
%         MinH = (Width-Height)/2;
%         MaxH = Width - (Width - Height)/2;
%         MinW = 0;
%         MaxW = Width;
    elseif Width < Height
        temp = padarray(temp, [0,(Height-Width)/2], 'both');
%         MinH = 0;
%         MaxH = Height;
%         MinW = (Height - Width)/2;
%         MaxW = Height - (Height - Width)/2;
    else
%         MinH = 0;
%         MaxH = Height;
%         MinW = 0;
%         MaxW = Width;
    end
    app.SETUP.imgStack(:,:,imgIdx) = temp;

end
[direct_lattice_vectors,corrected_basis_vectors,vec_estimate_manual] = get_basic_vector(app.SETUP,app.AlreadyknowthebasicvectorsCheckBox.Value,app.DisplayCheckBox.Value);
app.SETUP.basicVec_fourier = corrected_basis_vectors;
app.SETUP.basicVec_spatial = direct_lattice_vectors;
app.SETUP.vec_estimate_manual = vec_estimate_manual;