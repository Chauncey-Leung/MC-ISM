clear;clc;
% Path of raw images (pinhole_ALN_raw)
file_path = 'C:\Users\1\Desktop\Example\Fluo\pinhole_ALN_raw\';
% Set isLockin to 1 if you want to use the OLID images for positioning, 0 otherwise
isOLID = 0;
ws = 23; % Window size
upfactor = 1;
% background threshold
bg = 6000;
% The stepping direction and pixels'number of the spot between adjacentframes.
% (which can be determined using ImageJ or Matlab imshow) 
% Assign values according to the following rules. (These values can be adjusted later)
% [vertical(up- down+) horizontoal(left- right+)]
interval = [0  -1];  

if isOLID == 1
    lockin(file_path,"DeDC");
    file_path = [file_path, '..\pinhole_ALN\'];
end
pixel_size = 65/upfactor; % [nm]
extent = 2;
interval = interval .* upfactor;

%% Subpixel localization
tic;
bar = waitbar(0, 'Subpixel localizing...');
fileinfo = dir(file_path);
count = length(fileinfo)-2;
peakloc_subpixel = cell(length(count), 1);
img = cell(length(count), 1);
for imgIndex = 3:count+2
    strBar = ['Subpixel localizing...', num2str(imgIndex-2),'/',num2str(count)];
    waitbar((imgIndex - 2)/count, bar, strBar)
    filename = strcat(file_path,fileinfo(imgIndex).name);
    [peakloc_subpixel{imgIndex-2}, img{imgIndex-2}] = getSubpixelCoor(filename, ws, upfactor, bg);
end
close(bar);
toc;

% showImgandCoor(1, img, peakloc_subpixel);

%% Ask whether to adjust the interval 
showImgandCoor(4, img, peakloc_subpixel);
showImgandCoor(5, img, peakloc_subpixel);
prompt = {['Do you want to adjust the interval?The interval you previously set was (',...
    num2str(interval(1)), ' ', num2str(interval(2)),...
    ')  If you do not want to adjust it, click "Cancel".Otherwise, ' ...
    'please enter the adjusted interval and click "OK"']};
dlgtitle = 'Adjust interval';
dims = [1 40];
definput = {[num2str(interval(1)), ' ', num2str(interval(2))]};
opt.WindowStyle = 'normal';
opt.Resize = 'on';
answer = inputdlg(prompt,dlgtitle, dims, definput, opt);
if  ~isempty(answer)
    interval = str2num(answer{1});
end


%% Calculate step distance  
start_index = 1;
peakloc_subpixel_1 = peakloc_subpixel{start_index};
total_edge = cell(count-1, 1);
for num_idx = (start_index+1) : count
    peakloc_subpixel_2 = peakloc_subpixel{num_idx};
    point_num = size(peakloc_subpixel_1, 1);
    xx = peakloc_subpixel_2(:,1);
    yy = peakloc_subpixel_2(:,2);
    idx = 1;
    for i = 1 : point_num
        point = peakloc_subpixel_1(i,:);
        locx = point(1) + interval(1); locy = point(2) + interval(2);
        x = xx; y = yy;
        x((xx<locx-extent)|(xx>locx+extent)|(yy<locy-extent)|(yy>locy+extent))=[];
        y((xx<locx-extent)|(xx>locx+extent)|(yy<locy-extent)|(yy>locy+extent))=[];
        nextpoint_t = [x, y];
        if size(nextpoint_t, 1) > 1
            disp(point);
            error("debug:adjacent point should be unique");
        end
        if ~isempty(nextpoint_t)
            edge(idx, 1:2) = point;
            edge(idx, 3:4) = nextpoint_t;
            idx = idx + 1;
        end
    end 
    peakloc_subpixel_1 = peakloc_subpixel_2;
    total_edge{num_idx-1} = edge;
end

avg_stepsize = zeros(3, count-1); %(x,y,total)
std_stepsize = zeros(3, count-1);
edge_num = zeros(1, count-1);
for num_idx = 1 : count-1
    edge = total_edge{num_idx};
    x_distance = ((edge(:,4)-edge(:,2)).^2).^0.5;
    y_distance = ((edge(:,3)-edge(:,1)).^2).^0.5;
    distance = (x_distance.^2 + y_distance.^2).^0.5;
    avg_stepsize(1, num_idx) = mean(x_distance);
    avg_stepsize(2, num_idx) = mean(y_distance);
    avg_stepsize(3, num_idx) = mean(distance);
    std_stepsize(1, num_idx) = std(x_distance);
    std_stepsize(2, num_idx) = std(y_distance);
    std_stepsize(3, num_idx) = std(distance);
    edge_num(num_idx) = length(edge);
end

figure;
hold on;
plot(2:count,avg_stepsize(1,:),'LineWidth',1);
plot(2:count,avg_stepsize(2,:),'LineWidth',1);
plot(2:count,avg_stepsize(3,:),'LineWidth',1);
xlabel('frames');
ylabel('step size/pixel');
title('stepsize vs frame');
legend('x avg stepsize','y avg stepsize','avg stepsize');

w = size(img{1},1) * upfactor;
h = size(img{1},2) * upfactor;
ISM2_old = zeros(w, h);
ISM2_new = zeros(w, h);
for num_idx = 1 : count
    loc = peakloc_subpixel{num_idx};
    ISM2_new(sub2ind(size(ISM2_new(:,:,1)),round(loc(:, 1)'), round(loc(:, 2)'))) = 255;
    ISM2_new = ISM2_new + ISM2_old;
    imwrite(uint8(ISM2_new), [file_path '..\ISM_fold2.tif'],'writemode','append');
    ISM2_old = ISM2_new;
end
% % imshow(img{1},[]);
% % hold on;
% % plot(peakloc_subpixel{1}(:,2),peakloc_subpixel{1}(:,1),'o');

% % figure;
% % hold on;
% % errorbar(2:count,avg_stepsize(1,:),std_stepsize(1,:),'LineWidth',1.5);
% % errorbar(2:count,avg_stepsize(2,:),std_stepsize(1,:),'LineWidth',1.5);
% % errorbar(2:count,avg_stepsize(3,:),std_stepsize(1,:),'LineWidth',1.5);
% % xlabel('frames');
% % ylabel('step size/pixel');
% % title('stepsize vs frame');
% % legend('x avg stepsize','y avg stepsize','avg stepsize')

