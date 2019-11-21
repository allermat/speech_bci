function preproc_COMM(subID,varargin)
% BCI project MEG/EEG preprocessing common stage

%% Parsing input, checking matlab
validModalities = {'meg','eeg'};
p = inputParser;

addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
addOptional(p,'modality','meg',@(x) ismember(x,validModalities));

parse(p,subID,varargin{:});

subID = p.Results.subID;
modality = p.Results.modality;

%% Preparing file and directory names for the processing pipeline.
dataDir = fullfile(BCI_setupdir('analysis_meg_sub',subID),'maxfilter');
if ~exist(dataDir,'dir')
    error('The specified data folder does not exist!');
end

if strcmp(modality,'meg')
    analysisDir = fullfile(BCI_setupdir('analysis_meg_sub',subID),'COMM');
    if ~exist(analysisDir,'dir')
        mkdir(analysisDir);
    end
else
    analysisDir = fullfile(BCI_setupdir('analysis_eeg_sub',subID),'COMM');
    if ~exist(analysisDir,'dir')
        mkdir(analysisDir);
    end
end

% Loading files specifying parameters

% Trigger definition
trigDef = generateTrigDef(generateCondDef);
% Setup specifics
setupSpec = load('setup_spec.mat');
setupSpec = setupSpec.setup_spec;
setupSpec = setupSpec(ismember({setupSpec.description},'presentation'));
% Subject specifics
s = subjSpec;
if ~s.subjPresent(subID)
    error('No specific info found for this subject.');
end
% Preprocessing parameters that can vary individually
preprocParam = s.getField(subID,'preproc_param');
% Getting data file names
fileNames = s.getField(subID,'meg_files').fileName;
sourceFileNames = strcat(fileNames,'_trans1st');

tag = 'COMM_';

for iFile = 1:size(sourceFileNames,1)
    
    %% Checking if the processed data are already present
    artfResultFileName = sprintf('artf_%srun%d.mat',tag,iFile);
    if strcmp(modality,'meg')
        meegResultFileName = sprintf('ftmeg_%srun%d.mat',tag,iFile);
    else
        meegResultFileName = sprintf('fteeg_%srun%d.mat',tag,iFile);
    end
    if exist(fullfile(analysisDir,artfResultFileName),'file') && exist(fullfile(analysisDir,meegResultFileName),'file')
        warning('Skipping %s as it has been already processed! ',[sourceFileNames{iFile},'.fif']);
        continue;
    end
    
    %% Reading raw data
    cfg = struct();
    cfg.datafile = fullfile(dataDir,[sourceFileNames{iFile},'.fif']);
    cfg.channel = {modality};
    ftDataRaw = ft_preprocessing(cfg);
    
    %% High-pass filtering
    cfg = struct();
    cfg.hpfilter = 'yes';
    cfg.hpfreq = preprocParam.hp_freq;
    cfg.hpfiltord = 4;
    cfg.hpfiltdir = 'twopass';
    cfg.plotfiltresp = 'yes';
    fprintf('\nFILTERING: Highpass filter of order %d, half power frequency %d\n\n',cfg.hpfiltord,cfg.hpfreq);
    ftDataHp = ft_preprocessing(cfg,ftDataRaw);
    
    if strcmp(modality,'eeg')
        %% Checking channels visually to reject noisy ones
        
        % Coarse visual pass on the data just to check if any channels
        % should be rejected
        cfg = struct();
        cfg.headerfile = fullfile(dataDir,[sourceFileNames{iFile},'.fif']);
        cfg.trialdef.eventtype = 'Trigger';
        cfg.trialdef.faketrllength = 600;
        cfg.trialdef.trigdef = trigDef;
        megFiles = s.getField(subID,'meg_files');
        cfg.trialdef.fileSpec = megFiles(ismember(megFiles.fileName,fileNames{iFile}),:);
        cfg.trialdef.trig_audioonset_corr = setupSpec.trig_audioonset_corr_meg;
        cfg.trialfun = 'ft_trialfun_artefactdetection';
        cfg = ft_definetrial(cfg);
        trlArtf = cfg.trl;
        
        % Epoching data for channel check
        cfg = struct();
        cfg.trl = trlArtf;
        ftDataEpArtf = ft_redefinetrial(cfg,ftDataHp);
        
%         cfg = struct();
%         cfg.method = 'trial';
%         ft_rejectvisual(cfg,ftDataHp);
        
        % Inspect data
        cfg = struct();
        cfg.viewmode  = 'vertical';
        cfg.continuous = 'no';
        cfg.channel = 'all';
        cfg.fontsize = 5;
        cfg = ft_databrowser(cfg,ftDataEpArtf); %#ok
        
        % Marking bad channels
        channelsList = ftDataHp.label;
        selection = listdlg('ListString',channelsList, ...
            'SelectionMode', 'multiple', 'ListSize', [200 400],...
            'PromptString','Choose bad channels');
        if ~isempty(selection)
            badChannels = channelsList(selection);
            goodChannels = setdiff(channelsList,badChannels);
        else
            badChannels = {};
            goodChannels = channelsList;
        end
        % Rejecting bad channels
        cfg = struct();
        cfg.channel = goodChannels;
        ftDataHp = ft_selectdata(cfg,ftDataHp);
        
    end
    %% Artefact detection
    if ~exist(fullfile(analysisDir,artfResultFileName),'file')
        %% Automatic artefact detection
        % Marking trials for artefact detection
        cfg = struct();
        cfg.headerfile = fullfile(dataDir,[sourceFileNames{iFile},'.fif']);
        cfg.trialdef.eventtype = 'Trigger';
        cfg.trialdef.faketrllength = 15;
        cfg.trialdef.trigdef = trigDef;
        megFiles = s.getField(subID,'meg_files');
        cfg.trialdef.fileSpec = megFiles(ismember(megFiles.fileName,fileNames{iFile}),:);
        cfg.trialdef.trig_audioonset_corr = setupSpec.trig_audioonset_corr_meg;
        cfg.trialfun = 'ft_trialfun_artefactdetection';
        cfg = ft_definetrial(cfg);
        trlArtf = cfg.trl;
        
        % Epoching data for automatic artefact detection
        cfg = struct();
        cfg.trl = trlArtf;
        ftDataEpArtf = ft_redefinetrial(cfg,ftDataHp);
        
        % - MUSCLE ARTEFACTS -
        cfg = struct();
        cfg.continuous = 'no';
        % channel selection, cutoff and padding
        cfg.artfctdef.zvalue.channel = 'all'; 
        cfg.artfctdef.zvalue.cutoff = preprocParam.cutoff_zval;
        cfg.artfctdef.zvalue.trlpadding = 0;
        cfg.artfctdef.zvalue.fltpadding = 0;
        cfg.artfctdef.zvalue.artpadding = 0.1;
        % algorithmic parameters
        cfg.artfctdef.zvalue.bpfilter = 'yes';
        cfg.artfctdef.zvalue.bpfreq = [110 140];
        cfg.artfctdef.zvalue.bpfilttype = 'but';
        cfg.artfctdef.zvalue.bpfiltord = 9;
        cfg.artfctdef.zvalue.bpinstabilityfix = 'reduce';
        cfg.artfctdef.zvalue.hilbert = 'yes';
        % Kernel length in seconds for smoothing, it is used by
        % ft_preproc_smooth.m
        cfg.artfctdef.zvalue.boxcar = 0.2; 
        % make the process interactive
        cfg.artfctdef.zvalue.interactive = 'yes';
        
        [cfg,artefact_muscle] = ft_artifact_zvalue(cfg,ftDataEpArtf); %#ok<ASGLU>
        zval_muscle = cfg.artfctdef.zvalue.cutoff; %#ok<NASGU>
        
%         if strcmp(modality,'eeg')
%             % Inspect detected artifacts
%             cfg = struct();
%             cfg.viewmode  = 'vertical';
%             cfg.continuous = 'no';
%             cfg.channel = 'all';
%             cfg.artfctdef.muscle.artifact = artefact_muscle;
%             cfg = ft_databrowser(cfg,ftDataEpArtf);
%             
%             ftDataEpArtf = [];
%             
%             artefact_muscle = cfg.artfctdef.muscle.artifact; %#ok<NASGU>
%             artefact_visual = cfg.artfctdef.visual.artifact; %#ok<NASGU>
%             save(fullfile(analysisDir,artfResultFileName),...
%                 'artefact_muscle','artefact_visual','badChannels','-v7.3');
%         end
        
        %% Saving artefact data
        fprintf('\n\nSaving artefact data...\n\n');
        if strcmp(modality,'eeg')
            save(fullfile(analysisDir,artfResultFileName),...
                'artefact_muscle','zval_muscle','badChannels','-v7.3');
        else
            save(fullfile(analysisDir,artfResultFileName),...
                'artefact_muscle','zval_muscle','-v7.3');
        end
    end
    
    %% Saving MEG/EEG data
    if strcmp(modality,'meg')
        fprintf('\n\nSaving MEG data...\n\n');
    else
        fprintf('\n\nSaving EEG data...\n\n');
    end
    save(fullfile(analysisDir,meegResultFileName),'ftDataHp','-v7.3');
    
    ftDataChanSel = []; %#ok<NASGU>
end

end
