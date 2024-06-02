if ~sum(contains(dirinfo1_name, 'pinhole'))
    len1 = length(dirinfo1);
    for idx1 = 3:len1
        dirpath1 = strcat(dirpath, '\', dirinfo1_name{idx1});
        dirinfo2 = dir(dirpath1);
        dirinfo2_name = struct2cell(dirinfo2);
        dirinfo2_name = dirinfo2_name(1,:);

        if ~sum(contains(dirinfo2_name, 'pinhole'))
            len2 = length(dirinfo2);
            for idx2 = 3:len2
                dirpath2 = strcat(dirpath1, '\', dirinfo2_name{idx2});
                if isfolder(dirpath2)
                    filepath = dirpath2;
                    disp(filepath)
                    f1_preprocessLockin(filepath);
                end
            end
        else
            filepath = dirpath1;
            disp(filepath)
            f1_preprocessLockin(filepath);
        end
    end
else
    filepath = dirpath;
    disp(filepath)
    f1_preprocessLockin(filepath);
end