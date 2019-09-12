function varargout = BCI_setupdir(varargin)
% Set up folders for the experiment. 
% 
% USAGE: 
%   out = BCI_setupdir();
%   out = BCI_setupdir(dirID);
%   out = BCI_setupdir(dirID,subID);
%
% INPUT:
%   dirID: directory ID string
%   subID: subject ID string
% OUTPUT: 
%   outPath: path of the required directory
%
% SIDE EFFECTS:
%   Some folders are created if not found. 
%   The required toolboxes are added to the path
%
% Copyright(C) Mate Aller 2019

%% Parsing input. 
p = inputParser;

validDirIDs = {'analysis_behav','analysis_eeg','analysis_meg','analysis_behav_sub',...
    'analysis_eeg_sub','analysis_eeg_sub_mvpa','analysis_eeg_sub_mvpa_preproc',...
    'analysis_eeg_sub_erp','analysis_eeg_sub_tf','analysis_meg_sub',...
    'analysis_meg_sub_mvpa','analysis_meg_sub_mvpa_preproc',...
    'analysis_meg_sub_erp','analysis_meg_sub_tf','analysis_scripts',...
    'data_behav','data_meg','data_behav_sub','data_meg_sub','pres',...
    'stimuli','study_root','toolbox'};

checkDirID = @(x) any(validatestring(x,validDirIDs));

addOptional(p,'dirID',[],checkDirID);
addOptional(p,'subID','',@(x) validateattributes(x,{'char'},{'nonempty'}));

parse(p,varargin{:});

dirID = p.Results.dirID;
subID = p.Results.subID; % subID is converted to character array here!

%% Setting up the basic directories if necessary. 
expStage = 'pilot_1';

[~,setupID] = system('hostname');
setupID = regexp(setupID,'[\w -]*','match');
setupID = setupID{1};

if strcmp(computer,'PCWIN64') || strcmp(computer,'PCWIN')
    [~,userID] = system('echo %username%');
    userID = regexp(userID,'[\w -]*','match');
    userID = userID{1};
elseif strcmp(computer,'GLNXA64') || strcmp(computer,'GLNX86')
    [~,userID] = system('id -n -u');
    userID = regexp(userID,'[\w -]*','match');
    userID = userID{1};
else
    error('Can''t find user name!');
end

% base folder depending on the setup
if strcmpi(setupID,'PC0220')
    baseDir = 'V:';
    mode = 'home';
elseif strcmpi(setupID,'DESKTOP-T5R7MNQ')
    baseDir = 'D:';
    mode = 'home';
elseif ~isempty(regexp(setupID,'^login','once'))
    baseDir = fullfile('/imaging',userID);
    mode = 'analysis';
elseif strcmpi(setupID,'STIM22')
    baseDir = fullfile('E:','MAller');
    mode = 'presentation';
else
    error('Unidentified setup!')
end

mypath.study_root = fullfile(baseDir,'Projects','BCI');
if ~exist(mypath.study_root,'dir')
    mkdir(mypath.study_root);
end
addpath(fullfile(mypath.study_root,expStage));

mypath.analysis_behav = fullfile(mypath.study_root,expStage,'behavioural_analysis');
if ~exist(mypath.analysis_behav,'dir') && strcmp(mode,'home')
    mkdir(mypath.analysis_behav);
end

mypath.analysis_eeg = fullfile(mypath.study_root,expStage,'EEG_analysis');
if ~exist(mypath.analysis_eeg,'dir') && any(strcmp(mode,{'home','analysis'}))
    mkdir(mypath.analysis_eeg);
end

mypath.analysis_meg = fullfile(mypath.study_root,expStage,'MEG_analysis');
if ~exist(mypath.analysis_meg,'dir') && any(strcmp(mode,{'home','analysis'}))
    mkdir(mypath.analysis_meg);
end

mypath.analysis_scripts = fullfile(mypath.study_root,expStage,'analysis_scripts');
if any(strcmp(mode,{'home','analysis'}))
    if ~exist(mypath.analysis_scripts,'dir')
        mkdir(mypath.analysis_scripts);
    end
    addpath(mypath.analysis_scripts);
end
mypath.data_behav = fullfile(mypath.study_root,expStage,'behavioural_data');
if ~exist(mypath.data_behav,'dir') && any(strcmp(mode,{'home','presentation'}))
    mkdir(mypath.data_behav);
end

mypath.data_meg = fullfile('/megdata','cbu','speech_bci');
% mypath.data_meg = fullfile(mypath.study_root,expStage,'MEG_data');
% if ~exist(mypath.data_meg,'dir') && any(strcmp(mode,{'home','analysis'}))
%     mkdir(mypath.data_meg);
% end

mypath.pres = fullfile(mypath.study_root,expStage,'presentation');
if any(strcmp(mode,{'home','presentation'}))
    if ~exist(mypath.pres,'dir')
        mkdir(mypath.pres);
    end
    addpath(mypath.pres,mypath.analysis_scripts);
end

mypath.toolbox = fullfile(mypath.study_root,expStage,'toolbox');
if ~exist(mypath.toolbox,'dir')
    mkdir(mypath.toolbox);
end
addpath(genpath(mypath.toolbox));


%% Returning the required path
% If not found either an error is thrown or the folder is created. 

if strcmp(dirID,'analysis_behav')
    outPath = mypath.analysis_behav;
elseif strcmp(dirID,'analysis_eeg')
    outPath = mypath.analysis_eeg;
elseif strcmp(dirID,'analysis_meg')
    outPath = mypath.analysis_meg;
elseif strcmp(dirID,'analysis_behav_sub')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_behav,subID);
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_eeg_sub')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_eeg,subID);
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_eeg_sub_mvpa')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_eeg,subID,'MVPA');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_eeg_sub_mvpa_preproc')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_eeg,subID,'MVPA','preproc');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_eeg_sub_erp')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_eeg,subID,'ERP');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_eeg_sub_tf')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_eeg,subID,'TF');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end    
elseif strcmp(dirID,'analysis_meg_sub')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_meg,subID);
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_meg_sub_mvpa')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_meg,subID,'MVPA');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_meg_sub_mvpa_preproc')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_meg,subID,'MVPA','preproc');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_meg_sub_erp')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_meg,subID,'ERP');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_meg_sub_tf')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.analysis_meg,subID,'TF');
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'analysis_scripts')
    outPath = mypath.analysis_scripts;
elseif strcmp(dirID,'data_behav')
    outPath = mypath.data_behav;
elseif strcmp(dirID,'data_meg')
    outPath = mypath.data_meg;
elseif strcmp(dirID,'data_behav_sub')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.data_behav,subID);
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'data_meg_sub')
    if strcmp(subID,'')
        error('Subject ID must be specified!');
    end
    outPath = fullfile(mypath.data_meg,subID);
    if ~exist(outPath,'dir')
        mkdir(outPath);
    end
elseif strcmp(dirID,'pres')
    outPath = mypath.pres;
elseif strcmp(dirID,'stimuli')
    outPath = fullfile(mypath.study_root,expStage,'stimuli');
elseif strcmp(dirID,'study_root')
    outPath = mypath.study_root;
elseif strcmp(dirID,'toolbox')
    outPath = fullfile(baseDir,'MATLAB');
    if ~exist(outPath,'dir')
        error('The specified folder does not exist!');
    end
else
    outPath = '';
end

if ~isempty(outPath)
    varargout{1} = outPath;
else
    fprintf('\nSetup ID: %s\nUser ID: %s\n\n',setupID,userID);
end

end