%% Set up global variables

clearvars

% add required paths

% define paths
rawpathstem = '/megdata/cbu/speech_bci/';
pathstem = '/imaging/ma09/Projects/BCI/pilot_3/MEG_analysis/';

%define subjects and blocks
cnt = 0;

% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0428';
% dates{cnt} = '191128';
% blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5' 'run6'},'_raw');
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% badeeg{cnt} = {''};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];

% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0432';
% dates{cnt} = '191129';
% blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5' 'run6'},'_raw');
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% badeeg{cnt} = {''};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];

% cnt = cnt + 1;
% subjects{cnt} = 'meg19_0436';
% dates{cnt} = '191203';
% blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5' 'run6'},'_raw');
% blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
% badeeg{cnt} = {''};
% badcomp{cnt}.MEG = [];
% badcomp{cnt}.MEGPLANAR = [];
% badcomp{cnt}.EEG = [];

cnt = cnt + 1;
subjects{cnt} = 'meg19_0439';
dates{cnt} = '191203';
blocksin{cnt} = strcat({'run1' 'run2' 'run3' 'run4' 'run5' 'run6'},'_raw');
blocksout{cnt} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
badeeg{cnt} = {''};
badcomp{cnt}.MEG = [];
badcomp{cnt}.MEGPLANAR = [];
badcomp{cnt}.EEG = [];
