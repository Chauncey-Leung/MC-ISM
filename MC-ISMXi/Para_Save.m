[file_name,file_path] = uiputfile([app.file_path,'\SETUP.mat'],'Save Pinhole Parameter');
para_save_path = fullfile(file_path, file_name);
app.SETUP.para_save_path = para_save_path;
SETUP = app.SETUP;
save(para_save_path, 'SETUP');