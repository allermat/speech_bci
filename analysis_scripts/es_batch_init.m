%% Set up global variables

clearvars

% add required paths

% define paths
rawpathstem = '/megdata/cbu/speech_bci/';
pathstem = '/imaging/ma09/Projects/BCI/pilot_2/MEG_analysis/';

%define subjects and blocks
cnt = 0;

% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0378';
% dates{cnt} = '191011';
% blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5'},'_raw');
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5'};
% badeeg{cnt} = {''};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];
% 
% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0379';
% dates{cnt} = '191008';
% blocksin{cnt} = strcat({'run1' 'run2' 'run3' },'_raw');
% blocksout{cnt} = {'run1' 'run2' 'run3' };
% badeeg{cnt} = {''};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];
% 
% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0382';
% dates{cnt} = '191017';
% blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5' 'run6'},'_raw');
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% badeeg{cnt} = {'EEG049'};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];

cnt = cnt + 1;
subjects{cnt} = 'meg19_0397';
dates{cnt} = '191017';
blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5' 'run6'},'_raw');
blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
badeeg{cnt} = {'EEG066'};
badcomp{cnt}.MEG = [];
badcomp{cnt}.MEGPLANAR = [];
badcomp{cnt}.EEG = [];