!matlab -nodesktop -nosplash -r "info = matlab.apputil.getInstalledAppInfo; addpath(genpath(info(ismember({info.name}, 'Symphony')).location)); addpath(genpath(fileparts(which('start_all.m')))); matlab.apputil.run(info(ismember({info.name}, 'Stage Server')).id);" &