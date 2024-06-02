%% 1. 
% read original files
Img = SETUP.imgStack;
for imgIdx = 1:size(Img, 3)
    temp = Img(:,:,imgIdx) - bg;
%     temp(temp < 0) = 0;
%     Img(:,:,imgIdx) = temp;
end

%% 2. illumination pattern and PSF_em
pinhole = SETUP.illumination;

NA = app.NumericalAperture.Value;
upfactor = app.Upfactor.Value;
pixel_size = app.PixelSize.Value/upfactor;

FWHM_em = 0.61 * lambda_em / NA;
std_em = FWHM_em / 2.355;
psf_em = fspecial('gaussian', 61, std_em*upfactor/pixel_size);
psf_em = psf_em./sum(psf_em(:)); 

%% 3. starting iteration
dataIter.ReconPara = [lambda1, lambda2, Iteration, SaveFreq, L];
dataIter.image = Img;
dataIter.psfem = psf_em;
dataIter.RegItem = RegItem;

if exeItem(1) == 1
    [ParaIter, ReconResult_fista] = mISM_FISTA4_gui(dataIter, pinhole,filesave);
elseif exeItem(2) == 1
    [ParaIter, ReconResult_fista] = mISM_FISTA4_acdc_gui(dataIter, pinhole,filesave);
end
