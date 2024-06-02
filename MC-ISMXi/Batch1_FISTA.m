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
                    if isC && contains(filepath, '_c')
                        lambda_ex = Lambda_ex(idx2-2);
                        lambda_em = Lambda_em(idx2-2);
                        bg = bgC(idx2-2);
                    else
                        lambda_ex = app.ExW.Value;
                        lambda_em = app.EmW.Value;
                        bg = app.Bg.Value;
                    end
                    if exeItem(1) == 1
	                    filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
				                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
				                    num2str(lambda2),'_L_',num2str(L));
                    elseif exeItem(2) == 1
	                    filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
				                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
				                    num2str(lambda2),'_L_',num2str(L),'_ACbg');
                    end
                    if RegItem(2) == 1
	                    filesave = [filesave, '_GroupSparsity'];
                    end
                    mkdir(filesave)

                    if app.RefCheckBox.Value == 1
                        load(app.PinholeFilepath.Value);
                    else
                        load([filepath, '\SETUP.mat']);
                    end
%                     Para_deconv;
                    Level1_FISTA;
                end
            end
        else
            filepath = dirpath1;
            if isC && contains(filepath, '_c')
                lambda_ex = Lambda_ex(idx1-2);
                lambda_em = Lambda_em(idx1-2);
                bg = bgC(idx1-2);
            else
                lambda_ex = app.ExW.Value;
                lambda_em = app.EmW.Value;
                bg = app.Bg.Value;
            end
            if exeItem(1) == 1
                filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
		                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
		                    num2str(lambda2),'_L_',num2str(L));
            elseif exeItem(2) == 1
                filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
		                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
		                    num2str(lambda2),'_L_',num2str(L),'_ACbg');
            elseif exeItem(3) == 1
                filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
		                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
		                    num2str(lambda2),'_L_',num2str(L),'_ACDC');
            end
            if RegItem(2) == 1
                filesave = [filesave, '_Sparsity'];
            elseif RegItem(3) == 1
                filesave = [filesave, '_GroupSparsity'];
            end
            mkdir(filesave)

            if app.RefCheckBox.Value == 1
                load(app.PinholeFilepath.Value);
            else
                load([filepath, '\SETUP.mat']);
            end
            Level1_FISTA;
        end
    end
else
    filepath = dirpath;
    if exeItem(1) == 1
        filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
                    num2str(lambda2),'_L_',num2str(L));
    elseif exeItem(2) == 1
        filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
                    num2str(lambda2),'_L_',num2str(L),'_ACbg');
    elseif exeItem(3) == 1
        filesave = strcat(filepath, '\deconv_result\FISTA_Ex',...
                    num2str(lambda_ex),'_lam1_',num2str(lambda1),'_lam2_',...
                    num2str(lambda2),'_L_',num2str(L),'_ACDC');
    end
    if RegItem(2) == 1
        filesave = [filesave, '_Sparsity'];
    elseif RegItem(3) == 1
        filesave = [filesave, '_GroupSparsity'];
    end
    mkdir(filesave)

    if app.RefCheckBox.Value == 1
        load(app.PinholeFilepath.Value);
    else
        load([filepath, '\SETUP.mat']);
    end
    Level1_FISTA;
end