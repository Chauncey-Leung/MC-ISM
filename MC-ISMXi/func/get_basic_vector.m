function [direct_lattice_vectors,corrected_basis_vectors, vec_estimate_manual] = get_basic_vector(param,isPreBasis,isDisplay)
range = param.range;
extent = param.extent;
reference = param.reference;
Img = param.imgStack;
vec_estimate_manual = param.vec_estimate_manual;% [vf1_x,vf1_y;vf2_x,vf2_y]
[Height, Width, Counts] = size(param.imgStack);

%% Generate the Fourier spectrum of raw images
fft_abs = zeros(Height, Width);
% % todo: edge_mixing
if reference == "Sum"
    for imgIdx = 1 : Counts
        fft_abs = fft_abs + abs(fftshift(fft2(Img(:,:, imgIdx))));
    end
    f2 = fft_abs / Counts;
%     imtool(f2, []);
else
    fft_abs  = fftshift(fft2(Img(:,:,str2num(reference))));
    fft_abs_filter = log(abs(fft_abs)+1);
    f = fft_abs_filter - mean(fft_abs_filter(:));
    f2 = f / std(f(:));
%     imtool(f2, [])
end

%% Determine the basic vectors
% Be carefore to the center_pixel(1) is along the Width direction (horizontal, x)
% and center_pixel(2) is along the Height direction (vertical, or y)
% That's because the return value of function ginput() is [x, y],
% the origin point is on the topleft and x axis is horizontal.
center_pixel = [Width/2, Height/2] + 1;
if ~isPreBasis
    h_fig = figure('units','normalized','outerposition',[0 0 1 1]);
    imagesc(f2)
    axis image
    colormap gray
    zoom(3)
    vec_estimate_manual(1,:) = ginput(1);
    hold on;
    plot(vec_estimate_manual(1,1),vec_estimate_manual(1,2),'x');
    vec_estimate_manual(1,:) = vec_estimate_manual(1,:) - center_pixel;
    vec_estimate_manual(2,:) = ginput(1);
    plot(vec_estimate_manual(2,1),vec_estimate_manual(2,2),'x');
    vec_estimate_manual(2,:) = vec_estimate_manual(2,:) - center_pixel;
    close(h_fig);
end

%% Determine searching scope
% center_pix = [Height/2, Width/2] + 1;
[xx, yy] = meshgrid(-range:range, -range:range);
cc = [xx(:), yy(:)];
cc(abs(xx(:)) + abs(yy(:)) > range, :) = [ ];
cc(cc(:,1)==0 & cc(:,2)==0, :) = [ ];

%% Find local peak values
vec = cc(:,1) .* vec_estimate_manual(1,:) + cc(:,2) .* vec_estimate_manual(2,:);
coord = vec + repmat(center_pixel, size(cc,1), 1);
coord2 = zeros(size(coord)); %[x y](Width Height)
% % The order of vec and coor: [x y] ([Width Height])
% % The order to index the element of matrix (the pixel of images):[y x]([Height Width])
for ii = 1:size(coord, 1)
    loc = round(coord(ii,:));
    temp = f2(loc(2)-extent:loc(2)+extent, loc(1)-extent:loc(1)+extent);
    [y, x] = find(temp == max(temp(:)));
    coord2(ii, :) = loc - 1 - extent + [x(1) y(1)]; 
end
% % 
% figure;imshow(f2,[]);
% hold on;
% for ii = 1 : size(coord2, 1)
%     plot(coord2(ii,1),coord2(ii,2),'x');
% end


%% Get the sub-pixel coordination of each peak value
coord_subpixel = zeros(size(cc,1), 2); % [x y]

masksize = 3;
interpPoints = -masksize:1:masksize;
for ii = 1:size(cc,1)
    p = coord2(ii, :); %[x y]
    temp = abs(fft_abs(p(2)-masksize:p(2)+masksize, p(1)-masksize:p(1)+masksize));
    tempy = temp(:,masksize+1);

    [xData, yData] = prepareCurveData(interpPoints, tempy');
    ft = fittype( 'poly2' );
    [fitresult, ~] = fit(xData, yData, ft);
    coord_subpixel(ii,2) = -fitresult.p2/(2*fitresult.p1) + coord2(ii,2);
%     imtool(temp, []);
%     figure;
%     xxx = -3:0.001:3;
%     yyy = xxx.^2 * fitresult.p1 + xxx * fitresult.p2 + fitresult.p3;
%     plot(xxx,yyy,LineWidth=1.5);
    tempx = temp(masksize+1,:);
    [xData, yData] = prepareCurveData(interpPoints, tempx);
    ft = fittype( 'poly2' );
    [fitresult, ~] = fit(xData, yData, ft );
    coord_subpixel(ii,1) = -fitresult.p2/(2*fitresult.p1) + coord2(ii,1);
end
vec_subpixel = coord_subpixel - center_pixel;
% LS
fun = @(x, xdata) xdata * x;
precise_basis_vectors = lsqcurvefit(fun, vec_estimate_manual, cc, vec_subpixel);

corrected_basis_vectors = precise_basis_vectors;

%% Determine the spatial basic vector by Fourier lattice
area = cross([corrected_basis_vectors(1,:),0], [corrected_basis_vectors(2,:),0]);
rotate_90 = [0, -1; 1, 0];
direct_lattice_vectors = corrected_basis_vectors * rotate_90 .* repmat(size(fft_abs),2,1)/area(end);

%% show
if isDisplay
    figure;
    Fig_Size = (range + 1) * mean([sqrt(sum(corrected_basis_vectors(1,:).^2)),...
        sqrt(sum(corrected_basis_vectors(2,:).^2))]);
    imagesc(log(1+f2(round(center_pixel(2) - Fig_Size):round(center_pixel(2) + Fig_Size),...
                          round(center_pixel(1) - Fig_Size):round(center_pixel(1) + Fig_Size))))
    axis image
    axis off
    title(['Basic vectors in Fourier domain : (', num2str(corrected_basis_vectors(1,:)), ... 
                                       ') & (', num2str(corrected_basis_vectors(2,:)), ')']);
    colormap gray
    hold on
    quiver(Fig_Size + 1,Fig_Size + 1,corrected_basis_vectors(1,1),corrected_basis_vectors(1,2),'g','autoscale','off')
    quiver(Fig_Size + 1,Fig_Size + 1,corrected_basis_vectors(2,1),corrected_basis_vectors(2,2),'g','autoscale','off')
    plot(Fig_Size + 1 + vec_subpixel(:,1),Fig_Size + 1 + vec_subpixel(:,2),'redx');
end

end