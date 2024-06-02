lambda_ex = app.ExW.Value;
lambda_em = app.EmW.Value;
% % scanfast = app.step.Value;
% % scanslow = app.step.Value;
NA = app.NumericalAperture.Value;
upfactor = app.Upfactor.Value;
pixel_size = app.PixelSize.Value/upfactor;

% parameters used to calculate the illumination mode in the frequency domain
% % fixed = 2;
% % extent = 8;
% % interval = app.Interval.Value;

% excitation kernal
% % FWHM_ex = 0.61 * lambda_ex / NA;
% % std_ex = FWHM_ex / 2.355;
% % psf_ex = fspecial('gaussian', 61, std_ex*upfactor/pixel_size);
% % psf_ex = psf_ex./sum(psf_ex(:));
% emission kernal
FWHM_em = 0.61 * lambda_em / NA;
std_em = FWHM_em / 2.355;
psf_em = fspecial('gaussian', 61, std_em*upfactor/pixel_size);
psf_em = psf_em./sum(psf_em(:));

% % hole = round(FWHM_ex*1*upfactor/pixel_size); % pinhole diameter is the size of a PSF
% % [XX,YY] = meshgrid((1:hole)-(1+hole)/2, (1:hole)-(1+hole)/2);
% % pinhole_kernal = (sqrt(XX.^2 + YY.^2) < hole/2);