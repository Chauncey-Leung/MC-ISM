% Reading parameters from the GUI interface
upfactor = app.Upfactor.Value;                % Multiple of interpolation
NA = app.NumericalAperture.Value;             % systemetric NA 
pixel_size = app.PixelSize.Value/upfactor;    % pixel size 

ispinhole = app.DigitalpinholeCheckBox.Value; % Whether to perform digital pinholing
pinholefactor = app.pinhole.Value;            % pinhole parameters
isEdge = app.EdgetaperCheckBox.Value;         % Whether edge attenuation is performed for each subimage
Edgefactor = app.Edge.Value;                  % Edge decay ratio: For example, 30% of the maximum value of the subimage, fill in 0.3
ws = app.WS.Value;                            % The size of the subimage

isLiWF = app.LiWFCheckBox.Value;              % Whether to calculate wide field results
isconfocal = app.ConfocalCheckBox.Value;      % Whether to calculate confocal results
isISM = app.PRCheckBox.Value;                 % Whether to calculate PR results
isDeconv = app.DeconvCheckBox.Value;          % Whether to further deconvolution of the PR results

if upfactor == 1
    ws2 = ws;
else
    ws2 = ws*upfactor+1;
end

FWHM_ex = 0.61 * lambda_ex / NA;
std_ex = FWHM_ex / 2.355;
FWHM_em = 0.61 * lambda_em / NA;
std_em = FWHM_em / 2.355;
hole = std_em*2/pixel_size;
std_con = sqrt(1/(1/std_ex^2+1/std_em^2));
PSF_con = fspecial('gaussian', 61, std_con/pixel_size);