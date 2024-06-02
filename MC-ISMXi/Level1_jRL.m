%% 1.
% read image
Img = SETUP.imgStack;

%% 2. illumination pattern
pinhole = SETUP.illumination;

%% 3. PSF_em

NA = app.NumericalAperture.Value;
upfactor = app.Upfactor.Value;
pixel_size = app.PixelSize.Value/upfactor;

FWHM_em = 0.61 * lambda_em / NA;
std_em = FWHM_em / 2.355;
psf_em = fspecial('gaussian', 61, std_em*upfactor/pixel_size);
psf_em = psf_em./sum(psf_em(:)); 

%% 4. starting iteration
dataIter.ReconPara = [SaveFreq, Iteration];
dataIter.image = Img;
dataIter.psfem = psf_em;
tic,
ReconResult_jRL = mISM_jRL_gui(dataIter, pinhole, filesave);
toc