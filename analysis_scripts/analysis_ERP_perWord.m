function analysis_ERP_perWord(subID)
%% Parsing input, checking matlab
p = inputParser;

addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
        
parse(p,subID);

subID = p.Results.subID;

%% Preparing file and directory names for the processing pipeline.
sourceDir = fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID));
destDir = BCI_setupdir('analysis_meg_sub_erp',subID);

% Loading files specifying parameters
condDef = generateCondDef;

% Getting eeg source file names' list
matchStr = ['ftmeg_MVPA_',subID,'.mat'];
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
noiseCond = condDef.condition(ismember(condDef.stimType,'noise'));
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
    cfg = struct();
    % Selecting good trials belonging to the actual condition
    cfg.trials = ismember(trialInfo.condition,actCond) & ...
                 ismember(trialInfo.target,actWordId) & ...
                 trialInfo.badTrials == 0;
    ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
    % Getting rid of unnecesary previous cfgs
    ftDataAvg.cfg.previous = [];
    condTag = [actWordId,'_targ'];
    
    % Saving data
    fprintf('\n\nSaving data...\n\n');
    savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
    save(savePath,'ftDataAvg','-v7.3');
    
    ftDataAvg = [];
    
    %% Non-target words
    cfg = struct();
    % Selecting good trials belonging to the actual condition
    cfg.trials = ismember(trialInfo.condition,actCond) & ...
                 ~ismember(trialInfo.target,actWordId) & ...
                 trialInfo.badTrials == 0;
    ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
    % Getting rid of unnecesary previous cfgs
    ftDataAvg.cfg.previous = [];
    condTag = [actWordId,'_nontarg'];
    
    % Saving data
    fprintf('\n\nSaving data...\n\n');
    savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
    save(savePath,'ftDataAvg','-v7.3');
    
    ftDataAvg = [];
end

%% All words
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,conds) & ... % Only words, no noise
             trialInfo.badTrials == 0; % Only good data
ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
% Getting rid of unnecesary previous cfgs
ftDataAvg.cfg.previous = [];
condTag = 'all_words';

% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

%% Target words
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,conds) & ... % Only words, no noise
             strcmp(trialInfo.wordId,trialInfo.target) & ... % Only targets
             trialInfo.badTrials == 0; % Only good data
ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
% Getting rid of unnecesary previous cfgs
ftDataAvg.cfg.previous = [];
condTag = 'all_targ';

% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

%% Non-target words
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,conds) & ... % Only words, no noise
             ~strcmp(trialInfo.wordId,trialInfo.target) & ... % Only non-targets
             trialInfo.badTrials == 0; % Only good data
ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
% Getting rid of unnecesary previous cfgs
ftDataAvg.cfg.previous = [];
condTag = 'all_nontarg';

% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

%% Non-target words plus noise
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ~strcmp(trialInfo.wordId,trialInfo.target) & ... % Only non-target words and noise
             trialInfo.badTrials == 0; % Only good data
ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
% Getting rid of unnecesary previous cfgs
ftDataAvg.cfg.previous = [];
condTag = 'all_nontarg_noise';

% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

%% Noise
cfg = struct();
% Selecting good trials belonging to the actual condition
cfg.trials = ismember(trialInfo.condition,noiseCond) & ... % Only noise
             trialInfo.badTrials == 0; % Only good data
ftDataAvg = ft_timelockanalysis(cfg,ftDataClean);
% Getting rid of unnecesary previous cfgs
ftDataAvg.cfg.previous = [];
condTag = 'noise';

% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
save(savePath,'ftDataAvg','-v7.3');

ftDataAvg = [];

% % Average across all locations
% cfg = struct();
% % Selecting good trials belonging to the actual condition
% cfg.trials = trialInfo.iDay == iDay & ...
%     trialInfo.stim == 'S1' & ...
%     ismember(trialInfo.condition,conds) & ...
%     trialInfo.badtrials == 0;
% ftDataAvg = ft_timelockanalysis(cfg,ftDataDsampl);
% % Getting rid of unnecesary previous cfgs
% ftDataAvg.cfg.previous = [];
% dayStr = sprintf('day%d',iDay);
% condTag = [modStr,'_',stimStr,'_allLoc_',dayStr];
% 
% %% Saving data
% fprintf('\n\nSaving data...\n\n');
% savePath = fullfile(destDir,['ftmeg_ERP_',subID,'_',condTag,'.mat']);
% save(savePath,'ftDataAvg','-v7.3');
% 
% ftDataAvg = [];


end
