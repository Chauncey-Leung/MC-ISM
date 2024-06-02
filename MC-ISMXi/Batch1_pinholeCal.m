isFirstReference = true;
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
                    % Determine the excitation light and background corresponding to the channel
                    if isFirstReference
                        load([filepath, '\SETUP.mat']);
                        isFirstReference = false;
                    else
                        if isC && contains(filepath, '_c')
                            lambda_ex = Lambda_ex(idx2-2);
                            lambda_em = Lambda_em(idx2-2);
                            bg = bgC(idx2-2);
                        else
                            lambda_ex = app.ExW.Value;
                            lambda_em = app.EmW.Value;
                            bg = app.Bg.Value;
                        end
                        disp(filepath);
                        Batch2_pinholeCal;
                    end
                end
            end
        else
            filepath = dirpath1;
            if isFirstReference
                load([filepath, '\SETUP.mat']);
                isFirstReference = false;
            else
                if isC && contains(filepath, '_c')
                    lambda_ex = Lambda_ex(idx2-2);
                    lambda_em = Lambda_em(idx2-2);
                    bg = bgC(idx2-2);
                else
                    lambda_ex = app.ExW.Value;
                    lambda_em = app.EmW.Value;
                    bg = app.Bg.Value;
                end
                disp(filepath);
                Batch2_pinholeCal;
            end
        end
    end
end