%% Get SETUP based on the SETUP of the first frame

SETUP_new.upfactor = SETUP.upfactor;
SETUP_new.range = SETUP.range;
SETUP_new.extent = SETUP.extent;
SETUP_new.reference = SETUP.reference;
SETUP_new.vec_estimate_manual = SETUP.vec_estimate_manual;

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
    SETUP_new.imgStack(:,:,imgIdx) = temp;
end
[direct_lattice_vectors,corrected_basis_vectors,vec_estimate_manual] = ...
                                get_basic_vector(SETUP_new, true, false);
SETUP_new.basicVec_fourier = corrected_basis_vectors;
SETUP_new.basicVec_spatial = direct_lattice_vectors;


offset_vector = zeros(Counts, 2);
Img = SETUP_new.imgStack;
for ii = 1:Counts
    offset_vector(ii,:) = get_offset_vector(Img(:,:,ii), direct_lattice_vectors);
end
SETUP_new.offsetVec = offset_vector;


illumination = zeros(size(SETUP.illumination));
ws_sub = round(mean([sqrt(direct_lattice_vectors(1,1)^2 + direct_lattice_vectors(1,2)^2),...
                     sqrt(direct_lattice_vectors(2,1)^2 + direct_lattice_vectors(2,2)^2)]));
if mod(ws_sub, 2) == 0
    ws_sub = ws_sub + 1;
end
% update the Height Width
[Height, Width, Counts] = size(Img);
upfactor = SETUP_new.upfactor;
pixel_size = app.PixelSize.Value / upfactor;
NA = app.NumericalAperture.Value;
% excitation kernal
FWHM_ex = 0.61 * lambda_ex / NA;
std_ex = FWHM_ex / 2.355;
psf_ex = fspecial('gaussian', ws_sub, std_ex*upfactor/pixel_size);
psf_ex = psf_ex./sum(psf_ex(:));
% pinhole kernal
hole = round(FWHM_ex*1*upfactor/pixel_size); % pinhole diameter is the size of a PSF
[XX,YY] = meshgrid((1:hole)-(1+hole)/2, (1:hole)-(1+hole)/2);
pinhole_kernal = (sqrt(XX.^2 + YY.^2) < hole/2);

% single_point_distributon = conv2(pinhole_kernal, psf_ex, 'same');
single_point_distributon = conv2(psf_ex, pinhole_kernal, 'same');
for ii = 1:Counts
    final_lattice = generate_lattice(Height, Width, offset_vector(ii, :), direct_lattice_vectors, 10);
    
    for point = 1:size(final_lattice,1)
        loc = final_lattice(point, :);
        [X, Y] = meshgrid(linspace(loc(1)-(ws_sub-1)/2,loc(1)+(ws_sub-1)/2,ws_sub),...
                          linspace(loc(2)-(ws_sub-1)/2,loc(2)+(ws_sub-1)/2,ws_sub));
        loc_round = round(loc);
        [Xq, Yq] = meshgrid(linspace(loc_round(1)-(ws_sub-1)/2,loc_round(1)+(ws_sub-1)/2,ws_sub),...
                            linspace(loc_round(2)-(ws_sub-1)/2,loc_round(2)+(ws_sub-1)/2,ws_sub));
        single_point_distributon_interp = interp2(X,Y,single_point_distributon,Xq,Yq,'linear',0);
        illumination(Yq(1):Yq(end), Xq(1):Xq(end), ii) = illumination(Yq(1):Yq(end), Xq(1):Xq(end), ii) + single_point_distributon_interp;    
    end
end
SETUP_new.illumination = illumination;

para_save_path = [filepath, '\SETUP.mat'] ;
SETUP_new.para_save_path = para_save_path;
SETUP = SETUP_new;
save(para_save_path, 'SETUP');