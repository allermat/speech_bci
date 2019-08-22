%% Set up global variables

clearvars

% add required paths

% define paths
rawpathstem = '/megdata/cbu/speech_bci/';
pathstem = '/imaging/ma09/Projects/BCI/pilot_1/MEG_analysis/';

%define subjects and blocks
cnt = 0;

cnt = cnt + 1;
subjects{cnt} = 'meg19_0233';
dates{cnt} = '1907115';
blocksin{cnt} = strcat('speech_bci_',{'run1' 'run2' 'run3' 'run4' 'run5'});
blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5'};
badeeg{cnt} = {''};
badcomp{cnt}.MEG = [];
badcomp{cnt}.MEGPLANAR = [];
badcomp{cnt}.EEG = [];

% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0239';
% dates{cnt} = '1907116';
% blocksin{cnt} = strcat('speech_bci_',{'run1' 'run2' 'run3' 'run4' 'run5' 'run6'});
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% badeeg{cnt} = {''};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];

% cnt = cnt + 1;xf
% subjects{cnt} = 'meg19_0251';
% dates{cnt} = '190722';
% blocksin{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% badeeg{cnt} = {'EEG033'};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];
%