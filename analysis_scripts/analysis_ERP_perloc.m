function analysis_ERP_perloc(subID)
%% Parsing input, checking matlab
p = inputParser;

addRequired(p,'subID',@(x)validateattributes(x, ...
            {'numeric'},{'scalar','integer','positive'}));
        
parse(p,subID);

subID = p.Results.subID;

%% Preparing file and directory names for the processing pipeline.
eegDataDir = AVWM_setupdir('data_eeg_sub',num2str(subID));
sourceDir = fullfile(AVWM_setupdir('anal_eeg_sub_mvpa_preproc',num2str(subID)));
destDir = AVWM_setupdir('anal_eeg_sub_erp',num2str(subID));

% Loading files specifying parameters
condDef = generateCondDef;

% Getting eeg source file names' list
saveDf = cd(sourceDir);
fileNames = cellstr(ls(['fteeg_MVPA_',num2str(subID),'_day*.mat']));
cd(saveDf);

%% Loading files
sourceFiles = cell(size(fileNames));

for iFile = 1:size(fileNames,1)
    
    sourceFiles{iFile} = load(fullfile(sourceDir,fileNames{iFile}));
    sourceFiles{iFile} = sourceFiles{iFile}.ftDataClean;
    
end

%% Merging files for the same day if necessary
if numel(sourceFiles) > 1
    ftDataMerged = ft_appenddata([],sourceFiles{:});
else
    ftDataMerged = sourceFiles{1}; %#ok<*NASGU>
end

sourceFiles = [];

%% Downsampling
cfg = struct();
cfg.resamplefs = 250;
cfg.detrende = 'no';
ftDataDsampl = ft_resampledata(cfg,ftDataMerged);
% Clearing unnecessary previous dataset
ftDataMerged = [];

trialInfo = struct2table(cell2mat(ftDataDsampl.trialinfo));
%% Averaging over conditions
condsVV = condDef.condition(condDef.S1mod == 'V' & condDef.S2mod == 'V');
S1locations = unique(condDef.S1loc);
modStr = 'VV';
stimStr = 'S1';

% Initializing progress monitor
fprintf('\n\nAveraging tials...\n');
days = unique(trialInfo.iDay);

for iDay = days'
    for iLoc = 1:size(S1locations,1)
        
        actLoc = S1locations(iLoc);
        cfg = struct();
        % Selecting good trials belonging to the actual condition
        cfg.trials = trialInfo.iDay == iDay & ...
                     trialInfo.stim == 'S1' & ...
                     ismember(trialInfo.condition,condsVV) & ...
                     trialInfo.S1loc == actLoc & ...
                     trialInfo.badtrials == 0;
        ftDataAvg = ft_timelockanalysis(cfg,ftDataDsampl);
        % Getting rid of unnecesary previous cfgs
        ftDataAvg.cfg.previous = [];
        dayStr = sprintf('day%d',iDay);
        condTag = [modStr,'_',stimStr,'_',num2str(actLoc),'_',dayStr];
                
        %% Saving data
        fprintf('\n\nSaving data...\n\n');
        savePath = fullfile(destDir,['fteeg_ERP_',num2str(subID),'_',condTag,'.mat']);
        save(savePath,'ftDataAvg','-v7.3');
        
        ftDataAvg = [];
        
    end
    % Average across all locations
    cfg = struct();
    % Selecting good trials belonging to the actual condition
    cfg.trials = trialInfo.iDay == iDay & ...
        trialInfo.stim == 'S1' & ...
        ismember(trialInfo.condition,condsVV) & ...
        trialInfo.badtrials == 0;
    ftDataAvg = ft_timelockanalysis(cfg,ftDataDsampl);
    % Getting rid of unnecesary previous cfgs
    ftDataAvg.cfg.previous = [];
    dayStr = sprintf('day%d',iDay);
    condTag = [modStr,'_',stimStr,'_allLoc_',dayStr];
    
    %% Saving data
    fprintf('\n\nSaving data...\n\n');
    savePath = fullfile(destDir,['fteeg_ERP_',num2str(subID),'_',condTag,'.mat']);
    save(savePath,'ftDataAvg','-v7.3');
    
    ftDataAvg = [];
end


end
