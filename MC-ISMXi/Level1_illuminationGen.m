% % This script is aim at generating the illumination pattern

isSubpixel = app.SubpixelCheckBox.Value;
file_path = app.file_path;

Img = app.SETUP.imgStack;
direct_lattice_vectors = app.SETUP.basicVec_spatial;
illumination = zeros(size(Img));
[Height, Width, Counts] = size(Img);

lambda_ex = app.app_parent.ExW.Value;
lambda_em = app.app_parent.EmW.Value;
upfactor = app.app_parent.Upfactor.Value;
pixel_size = app.app_parent.PixelSize.Value / upfactor;
NA = app.app_parent.NumericalAperture.Value;

% excitation kernal
FWHM_ex = 0.61 * lambda_ex / NA;
std_ex = FWHM_ex / 2.355;
psf_ex = fspecial('gaussian', 61, std_ex*upfactor/pixel_size);
psf_ex = psf_ex./sum(psf_ex(:));

hole = round(FWHM_ex*1*upfactor/pixel_size); % pinhole diameter is the size of a PSF
[XX,YY] = meshgrid((1:hole)-(1+hole)/2, (1:hole)-(1+hole)/2);
pinhole_kernal = (sqrt(XX.^2 + YY.^2) < hole/2);


%% Get offset_vector from the first frame
offset_vector = zeros(Counts, 2);
for ii = 1:Counts
    offset_vector(ii,:) = get_offset_vector(Img(:,:,ii), direct_lattice_vectors);
end
app.SETUP.offsetVec = offset_vector;

% final_lattice = generate_lattice(Height, Width, offset_vector, direct_lattice_vectors, 10);        
% figure;
% imshow(Img(:,:,1),[]);
% hold on;
% plot(final_lattice(:,1),final_lattice(:,2),'x');


% if use subpixel precision
if isSubpixel
    ws_sub = round(mean([sqrt(direct_lattice_vectors(1,1)^2 + direct_lattice_vectors(1,2)^2),...
                         sqrt(direct_lattice_vectors(2,1)^2 + direct_lattice_vectors(2,2)^2)]));
    if mod(ws_sub, 2) == 0
        ws_sub = ws_sub + 1;
    end
    psf_ex = fspecial('gaussian', ws_sub, std_ex*upfactor/pixel_size);
    psf_ex = psf_ex./sum(psf_ex(:));
    [XX,YY] = meshgrid((1:ws_sub)-(1+ws_sub)/2, (1:ws_sub)-(1+ws_sub)/2);
    pinhole_kernal = (sqrt(XX.^2 + YY.^2) < hole/2);
%     single_point_distributon = conv2(pinhole_kernal, psf_ex, 'same');
    single_point_distributon = conv2(psf_ex, pinhole_kernal, 'same');
    for ii = 1:Counts
        final_lattice = generate_lattice(Height, Width, offset_vector(ii, :), direct_lattice_vectors, (ws_sub-1)/2+1);
        
        for point = 1:size(final_lattice,1)
            loc = final_lattice(point, :);
            [X, Y] = meshgrid(linspace(loc(1)-(ws_sub-1)/2,loc(1)+(ws_sub-1)/2,ws_sub),...
                              linspace(loc(2)-(ws_sub-1)/2,loc(2)+(ws_sub-1)/2,ws_sub));
            loc_round = round(loc);
            [Xq, Yq] = meshgrid(linspace(loc_round(1)-(ws_sub-1)/2,loc_round(1)+(ws_sub-1)/2,ws_sub),...
                                linspace(loc_round(2)-(ws_sub-1)/2,loc_round(2)+(ws_sub-1)/2,ws_sub));
            single_point_distributon_interp = interp2(X,Y,single_point_distributon,Xq,Yq,'linear',0);
            illumination(Yq(1):Yq(end), Xq(1):Xq(end), ii) = illumination(Yq(1):Yq(end), Xq(1):Xq(end), ii) + single_point_distributon_interp;
% %             figure;
% %             imshow(single_point_distributon, []);
% %             hold on;
% %             cc = loc - loc_round + (ws_sub - 1)/2 +1;
% %             plot(cc(1), cc(2), 'redx');
% %             figure;
% %             imshow(single_point_distributon_interp, []);
% %             hold on;
% %             cc = loc - loc_round + (ws_sub - 1)/2 +1;
% %             plot(cc(1), cc(2), 'redx');
        end
    end
    illumination = illumination ./ max(illumination(:));
else
    for ii = 1:Counts
        final_lattice = generate_lattice(Height, Width, offset_vector(ii, :), direct_lattice_vectors, 10);
        pinhole_center = zeros(Height, Width);
        for point = 1:size(final_lattice,1)
            pinhole_center(round(final_lattice(point,2)), round(final_lattice(point,1))) = 1;
        end
        illumination(:,:,ii) = conv2(conv2(pinhole_center, pinhole_kernal, 'same'),psf_ex,'same');
    end
    illumination = illumination ./ max(illumination(:));
end

app.SETUP.illumination = illumination;

% % for ii = 1 : 49
% %     ii = 34;
% %     final_lattice = generate_lattice(Height, Width, offset_vector(ii, :), direct_lattice_vectors, 10);
% %     figure;
% %     imshow(illumination(:,:,ii),[]);
% %     hold on;
% %     plot(final_lattice(:,1),final_lattice(:,2),'x');
% % 
% %     figure;
% %     imshow(Img(:,:,ii),[]);
% %     hold on;
% %     plot(final_lattice(:,1),final_lattice(:,2),'bluex');
% %     final_lattice = generate_lattice(Height, Width, 0, direct_lattice_vectors, 10);
% %     plot(final_lattice(:,1),final_lattice(:,2),'redx');
% end