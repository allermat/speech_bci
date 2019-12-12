function analysis_ERP_perWord_spm(subID,varargin)
% Parsing input, checking matlab
p = inputParser;

validModalities = {'meg','eeg'};

addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
addOptional(p,'modality','meg',@(x) ismember(x,validModalities));

parse(p,subID,varargin{:});

subID = p.Results.subID;
modality = p.Results.modality;

%% Preparing file and directory names for the processing pipeline.
if strcmp(modality,'meg')
    sourceDir = fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID));
    destDir = BCI_setupdir('analysis_meg_sub_erp',subID);
    matchStr = ['ftmeg_MVPA_',subID,'.mat'];
    fileStem = 'ftmeg_ERP_';
else
    sourceDir = fullfile(BCI_setupdir('analysis_eeg_sub_mvpa_preproc',subID));
    destDir = BCI_setupdir('analysis_eeg_sub_erp',subID);
    matchStr = ['fteeg_MVPA_',subID,'.mat'];
    fileStem = 'fteeg_ERP_';
end
% Loading files specifying parameters
condDef = generateCondDef;

% Getting eeg source file names' list
listing = dir(sourceDir);
fileNames = {listing.name}';
fileNames = fileNames(~cellfun(@isempty,regexp(fileNames,matchStr,'once')));

%% Loading files
if ~exist(fullfile(sourceDir,fileNames{1}),'file')
    error('Source file not found. ');
end
sourceFile = load(fullfile(sourceDir,fileNames{1}));
ftDataClean = sourceFile.ftDataClean;
trialInfo = struct2table(cell2mat(ftDataClean.trialinfo));
trialInfo.wordId = cell(size(trialInfo,1),1);
trialInfo.wordId(:) = {''};
% Adding wordID for each stimulus if it isn't present
conds = condDef.condition(ismember(condDef.stimType,'word'));
noiseCond = condDef.condition(contains(condDef.stimType,'noise'));
for i = 1:numel(conds)
    trialInfo.wordId(trialInfo.condition == conds(i)) = ...
        condDef.wordId(condDef.condition == conds(i));
end

%% Averaging over conditions

% Initializing progress monitor
fprintf('\n\nAveraging tials...\n');

for iCond = 1:size(conds,1)
    
    actCond = conds(iCond);
    actWordId = condDef.wordId{ismember(condDef.condition,actCond)};
    
    %% Target words
    condTag = [actWordId,'_targ'];
    cfg = struct();
    % Selecting good trials belonging to the actual condition
    cfg.trials = ismember(trialInfo.condition,actCond) & ...
                 ismember(trialInfo.target,actWordId) & ...
                 trialInfo.badTrials == 0;
    nActTrials = sum(cfg.trials);
    ftDataToAvg = ft_selectdata(cfg,ftDataClean);
    D = spm_eeg_ft2spm(ftDataToAvg,fullfile(destDir,'temp.mat'));
    D = D.conditions(1:nActTrials,repmat({condTag},1,nActTrials));
    
    S = struct();
    S.D = D;
    S.robust.ks = 3;
    S.robust.bycondition = true;
    S.robust.savew = false;
    S.robust.removebad = false;
    S.circularise = false;
    S.prefix = 'm';
    Dnew = spm_eeg_average(S);
    % Delete intermediate file
    D.delete;
    D = [];
    % % Rename result file
    % Dnew = move(Dnew,fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']));
    ftDataAvg = Dnew.fttimelock;
    Dnew.delete;
    Dnew = [];
    % Saving data
    fprintf('\n\nSaving data...\n\n');
    savePath = fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']);
    save(savePath,'ftDataAvg','-v7.3');
    
    ftDataAvg = [];
    
end

%% All words
condTag = 'all_words';
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,conds) & ... % Only words, no noise
             trialInfo.badTrials == 0; % Only good data
nActTrials = sum(cfg.trials);
ftDataToAvg = ft_selectdata(cfg,ftDataClean);
D = spm_eeg_ft2spm(ftDataToAvg,fullfile(destDir,'temp.mat'));
D = D.conditions(1:nActTrials,repmat({condTag},1,nActTrials));

S = struct();
S.D = D;
S.robust.ks = 3;
S.robust.bycondition = true;
S.robust.savew = false;
S.robust.removebad = false;
S.circularise = false;
S.prefix = 'm';
Dnew = spm_eeg_average(S);
% Delete intermediate file
D.delete;
D = [];
% % Rename result file
% Dnew = move(Dnew,fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']));
ftDataAvg = Dnew.fttimelock;
Dnew.delete;
Dnew = [];
% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

%% Target words
condTag = 'all_targ';
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,conds) & ... % Only words, no noise
             strcmp(trialInfo.wordId,trialInfo.target) & ... % Only targets
             trialInfo.badTrials == 0; % Only good data
nActTrials = sum(cfg.trials);
ftDataToAvg = ft_selectdata(cfg,ftDataClean);
D = spm_eeg_ft2spm(ftDataToAvg,fullfile(destDir,'temp.mat'));
D = D.conditions(1:nActTrials,repmat({condTag},1,nActTrials));

S = struct();
S.D = D;
S.robust.ks = 3;
S.robust.bycondition = true;
S.robust.savew = false;
S.robust.removebad = false;
S.circularise = false;
S.prefix = 'm';
Dnew = spm_eeg_average(S);
% Delete intermediate file
D.delete;
D = [];
% % Rename result file
% Dnew = move(Dnew,fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']));
ftDataAvg = Dnew.fttimelock;
Dnew.delete;
Dnew = [];
% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

%% Noise

condTag = 'noise';
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,noiseCond) & ... % Only noise
    trialInfo.badTrials == 0; % Only good data
nActTrials = sum(cfg.trials);
ftDataToAvg = ft_selectdata(cfg,ftDataClean);
D = spm_eeg_ft2spm(ftDataToAvg,fullfile(destDir,'temp.mat'));
D = D.conditions(1:nActTrials,repmat({condTag},1,nActTrials));

S = struct();
S.D = D;
S.robust.ks = 3;
S.robust.bycondition = true;
S.robust.savew = false;
S.robust.removebad = false;
S.circularise = false;
S.prefix = 'm';
Dnew = spm_eeg_average(S);
% Delete intermediate file
D.delete;
D = [];
% % Rename result file
% Dnew = move(Dnew,fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']));
ftDataAvg = Dnew.fttimelock;
Dnew.delete;
Dnew = [];
% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,[fileStem,subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];



end
