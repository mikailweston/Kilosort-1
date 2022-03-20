addpath(genpath('C:\Users\mweston\Documents\GitHub\Kilosort')) % path to kilosort folder
addpath('C:\Users\mweston\Documents\GitHub\npy-matlab') % for converting to Phy
rootZ = 'F:\week2_pyecog_test\NP26_20200312_D14_imec0RB_imec1LB_g1_imec0'; % the raw data binary file is in this folder
rootH = 'F:\week2_pyecog_test\kilosort'; % path to temporary binary file (same size as data, should be on fast SSD)
pathToYourConfigFile = 'D:\GitHub\Kilosort2\configFiles'; % take from Github folder and put it somewhere else (together with the master_file)
chanMapFile = 'neuropixPhase3A_kilosortChanMap.mat';

ops.trange    = [0 Inf]; % time range to sort
ops.NchanTOT  = 385; % total number of channels in your recording

run(fullfile(pathToYourConfigFile, 'configFile384.m'))
ops.fproc   = fullfile(rootH, 'temp_wh.dat'); % proc file on a fast SSD
ops.chanMap = fullfile(pathToYourConfigFile, chanMapFile);
%% this block runs all the steps of the algorithm
fprintf('Looking for data inside %s \n', rootZ)

% main parameter changes from Kilosort2 to v2.5
ops.sig        = 20;  % spatial smoothness constant for registration
ops.fshigh     = 10; % high-pass more aggresively
ops.nblocks    = 5; % blocks for registration. 0 turns it off, 1 does rigid registration. Replaces "datashift" option. 
%ops.whiteningRange      = 32;


% main parameter changes from Kilosort2.5 to v3.0
ops.Th       = [9 9];

% is there a channel map file in this folder?
fs = dir(fullfile(rootZ, 'chan*.mat'));
if ~isempty(fs)
    ops.chanMap = fullfile(rootZ, fs(1).name);
end

% find the binary file
fs          = [dir(fullfile(rootZ, '*.bin')) dir(fullfile(rootZ, '*.dat'))];
ops.fbinary = fullfile(rootZ, fs(1).name);

rez                = preprocessDataSub(ops);
rez                = datashift2(rez, 1);

[rez, st3, tF]     = extract_spikes(rez);

rez                = template_learning(rez, tF, st3);

[rez, st3, tF]     = trackAndSort(rez);

rez                = final_clustering(rez, tF, st3);

rez                = find_merges(rez, 1);

rootZ = fullfile(rootZ, 'kilosort3');
mkdir(rootZ)
rezToPhy2(rez, rootZ);

%% 
