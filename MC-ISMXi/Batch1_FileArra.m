base_data_path = app.FilepathBatch.Value;
base_save_path = app.FilepathSaveBatch.Value;
n = round(sqrt(app.step.Value));

color_num = CNum;
z_num = app.Zend.Value - app.Zstart.Value + 1;
isWF = app.isWF.Value;
worker_num = 6; % Number of parallel threads
if app.FastAixsDummy.Value==0 && app.SlowAxisDummy.Value==0
    dummy_scan_dimension = 0;
elseif app.FastAixsDummy.Value==1 && app.SlowAxisDummy.Value==0
    dummy_scan_dimension = 1;
elseif app.FastAixsDummy.Value==1 && app.SlowAxisDummy.Value==1
    dummy_scan_dimension = 2;
end
isRename = app.isrename.Value;
z_begin_num = app.Zstart.Value;
z_end_num = app.Zend.Value;
c_begin_num = 1;
c_end_num = CNum;
data_path = strcat(base_data_path, '\data');
fileinfo = dir(data_path);
img0 = imread([data_path, '\', fileinfo(3).name]);
img_size_h = size(img0, 1);
img_size_w = size(img0, 2);

savepath_list = cell(z_num * color_num , 1); 
mkdir(base_save_path);

% If the number of images collected at one time is more than 100,000
% then you need to rename the image name, eg. imagexx_00064.tif->imagexx_000064.tif
% To perform this renaming, change the value of isRename to 1 and 
% at the same time rename the [data] folder in the path to [data_unrename]
% The script file will rename the files by copying them and save them in 
% the [data] folder in the same path that the program automatically creates.
% Automatically check the number of files, if the number exceeds 100 000 and
% isRename is still not 0, a warning confirmation window will pop up.
% Insist that isRename is set to 0 if the file has already been renamed before, 
% or 1 if you forgot to change it before.

if length(fileinfo) - 2 >= 100000 && isRename == 0
    paraminput = inputdlg('Num of Raw Images exceeds 100,000, please check again, whether to rename: 0 - No, 1 - Yes');
    isRename = str2double(paraminput{1});
end
if isRename
   data_rename(base_data_path); 
end

fileinfo = dir(data_path);
if dummy_scan_dimension == 0
    begin_idx = 1;
    end_idx = begin_idx + n * n - 1;
    for z = z_begin_num : z_end_num
       save_name_z = "\data_z" + num2str(z,'%03d');
       save_path_z = strcat(base_save_path, save_name_z);
       for c = 1 : color_num
           save_name_c = save_name_z +  "_c" +  num2str(c) + '\pinhole_ALN_raw';
           save_path_c = strcat(save_path_z, save_name_c);
           mkdir(save_path_c)
           savepath_list{color_num * (z - 1) + c, 1} = save_path_c;

           for imgIdx = begin_idx : end_idx
               idx = (color_num * (z - 1) + (c - 1)) * n * n + imgIdx;
               src_path = strcat(data_path, '\', fileinfo(idx+2).name);
               copyfile(src_path, save_path_c);  
           end
       end
    end
%     begin_idx = 2 + n;
%     end_idx = begin_idx + n * n - 1;
%     for z = z_begin_num : z_end_num
%        save_name_z = "\data_z" + num2str(z);
%        save_path_z = strcat(base_save_path, save_name_z);
%        mkdir(save_path_z);
%        for c = c_begin_num : c_end_num
%            save_name_c = save_name_z +  "_c" +  num2str(c) + '\pinhole_ALN_raw';
%            save_path_c = strcat(save_path_z, save_name_c);
%            mkdir(save_path_c);
%            savepath_list{color_num * (z - 1) + c, 1} = save_path_c;
%            for imgIdx = begin_idx : end_idx
%                idx = (color_num * (z - 1) + (c - 1)) * n * (n + 1) + imgIdx;
%                src_path = data_path + '\' + fileinfo(idx).name;
%                copyfile(src_path, save_path_c);  
%            end
%        end
%     end
elseif dummy_scan_dimension == 1
    begin_idx = 3 + n;
    end_idx = begin_idx + n * n - 1;
    for z = z_begin_num : z_end_num
       save_name_z = "\data_z" + num2str(z,'%03d');
       save_path_z = strcat(base_save_path, save_name_z);
       mkdir(save_path_z);
       for c = c_begin_num : c_end_num
           save_name_c = save_name_z +  "_c" +  num2str(c) + "\pinhole_ALN_raw";
           save_path_c = strcat(save_path_z, save_name_c);
           mkdir(save_path_c);
           savepath_list{color_num * (z - 1) + c, 1} = save_path_c;
           for imgIdx = begin_idx : end_idx
               idx = (color_num * (z - 1) + (c - 1)) * n * (n + 1) + imgIdx;
               src_path = data_path + "\" + fileinfo(idx).name;
               copyfile(src_path, save_path_c);  
           end
       end
    end    
elseif dummy_scan_dimension == 2
    begin_idx = 3 + (n + 1);
    end_idx = begin_idx + (n +1) * n - 1;
    for z = z_begin_num : z_end_num
        save_name_z = "\data_z" + num2str(z,'%03d');
        save_path_z = strcat(base_save_path, save_name_z);
        mkdir(save_path_z);
        for c = c_begin_num : c_end_num
            save_name_c = save_name_z +  "_c" +  num2str(c) + "\pinhole_ALN_raw";
            save_path_c = strcat(save_path_z, save_name_c);
            mkdir(save_path_c);
            savepath_list{color_num * (z - 1) + c, 1} = save_path_c;
            for imgIdx = begin_idx : end_idx
                if mod(imgIdx - begin_idx, n + 1) ~= 0
                    idx = (color_num * (z - 1) + (c - 1)) * (n +1) * (n + 1) + imgIdx;
                    src_path = data_path + "\" + fileinfo(idx).name;
                    copyfile(src_path, save_path_c); 
                end
            end
        end
    end
else
    error("Input [dummy_scan_dimension] should be 0, 1 or 2.");
end



% %% operate OLID
% if isLockin
%     tic
%     ticBytes(gcp)
%     parfor (path_idx = z_begin_num : z_end_num, worker_num)
%         save_path = savepath_list{path_idx} + "\";
%         lockin_lqx(save_path); 
%     end
%     tocBytes(gcp)
%     toc
% end

%% Overlay pinhole_ALN_raw and pinhole_ALN into widefield
for path_idx = z_begin_num : z_end_num
%     str_len = strlength(savepath_list{path_idx});
    savepath_list{path_idx} = savepath_list{path_idx}{1}(1:end-15);
end
if isWF
    save_name_ALN_raw = strcat(base_save_path, "\..\AVG_pinhole_ALN_raw");
    mkdir(save_name_ALN_raw);
    for c = c_begin_num : c_end_num
        mkdir(save_name_ALN_raw + "\c" + num2str(c))
    end
%     c = c_begin_num;
    tic
    ticBytes(gcp)
    parfor path_idx = z_begin_num : z_end_num
        img_path = savepath_list{path_idx};
        ALN_raw_path = strcat(img_path, 'pinhole_ALN_raw');
        ALN_raw_img = zeros(img_size_h, img_size_w)
        fileinfo_ALN_raw = dir(ALN_raw_path);
        for imgIdx = 3 : length(fileinfo_ALN_raw)
            filename_ALN_raw = [ALN_raw_path,'\',fileinfo_ALN_raw(imgIdx).name];
%             img = gpuArray(double(imread(filename_ALN_raw)));
            img = double(imread(filename_ALN_raw));
            ALN_raw_img = ALN_raw_img + img;            
        end
        c = mod(path_idx, color_num);
        if c == 0
            c = color_num;
        end
        save_name_single = save_name_ALN_raw + "\c" + num2str(c) + "\";
%         c = c + 1;
%         if c > c_end_num
%             c = c_begin_num;
%         end
%         z_idx = floor((path_idx-1)/3) + 1;
        z_idx = path_idx;
        save_name_single = save_name_single + num2str(z_idx, '%03d')  + ".tif";
        imwrite(uint16(10000*ALN_raw_img./max(ALN_raw_img(:))),save_name_single)
%         imwrite(uint16(ALN_raw_img/49), save_name_single)
    end
    tocBytes(gcp)
    toc
end

function data_rename(base_data_path)
    %If more than 100,000 images are captured at one time, they need to be renamed    
    data_path = strcat(base_data_path, "\data");
    fileinfo = dir(data_path);
    count = length(fileinfo)-2;
    Num = length(num2str(count));
    for imgIdx = 3:length(fileinfo)
        current_img_name = fileinfo(imgIdx).name;
        Name_ = strsplit(current_img_name, '_');
        Name_dot = strsplit(Name_{2},'.');
        if length(num2str(Name_dot{1})) < Num
            zhushi = strcat('%0', num2str(Num), 'd');
            Name_Num = num2str(str2double(Name_dot{1}),zhushi);
    %         Name_Num = num2str(str2double(Name_dot{1}),'%06d');
            New_img_name = strcat(Name_{1}, '_', Name_Num, '.tif');
            szCmdLine = strcat("ren ", data_path, '\', current_img_name," ", New_img_name);
            if dos(szCmdLine)
                warning( "Fail to execute " + szCmdLine)
            end
        end
    end

end