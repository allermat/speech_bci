function preproc_MVPA(subID,varargin)
%% Parsing input, checking matlab
p = inputParser;

validModes = {'compICA','rejectICcomp'};

addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
addParameter(p,'runMode','compICA',@(x) ismember(x,validModes));

parse(p,subID,varargin{:});

subID = p.Results.subID;
runMode = p.Results.runMode;

%% Preparing file and directory names for the processing pipeline.
maxfilterDir = fullfile(BCI_setupdir('analysis_meg_sub',subID),'maxfilter');
sourceDir = fullfile(BCI_setupdir('analysis_meg_sub',subID),'COMM');
behavSourceDir = BCI_setupdir('data_behav_sub',subID);
destDir = BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID);

% Subject specifics
s = subjSpec;
if ~s.subjPresent(subID)
    error('No specific info found for this subject.');
end

% Getting original eeg data file names' list
dataFileNames = s.getField(subID,'meg_files').fileName;

% Loading files specifying parameters
% Trigger definition
trigDef = generateTrigDef(generateCondDef);
% Setup specifics
setupSpec = load('setup_spec.mat');
setupSpec = setupSpec.setup_spec;
setupSpec = setupSpec(ismember({setupSpec.description},'presentation'));

if strcmp(runMode,'compICA')
    % Getting eeg source file names' list
    sourceFileNames = strcat('ftmeg_COMM_',dataFileNames,'.mat');
    % Checking if the required files are available
    listing = dir(sourceDir);
    fileNames = {listing.name}';
    sourceFileNamesPresent = ...
        fileNames(~cellfun(@isempty,regexp(fileNames,'^ftmeg_COMM_','once')));
    if any(~ismember(sourceFileNames,sourceFileNamesPresent))
        error('The specified source files are not found');
    end
    
    % Getting artefact file names' list
    artefactFileNames = strcat('artf_COMM_',dataFileNames,'.mat');
    % Checking if the required files are available
    artefactFileNamesPresent = ...
        fileNames(~cellfun(@isempty,regexp(fileNames,'^artf_COMM_','once')));
    if any(~ismember(artefactFileNames,artefactFileNamesPresent))
        error('The specified artefact files are not found');
    end
    % Loading behavioural data 
    matchStr = strcat(subID,'_run[0-9]_[0-9]{8}_[0-9]{4}.mat');
    listing = dir(behavSourceDir);
    fileNames = {listing.name}';
    fileNames = fileNames(~cellfun(@isempty,regexp(fileNames,matchStr,'once')));
    dataBehav = struct2cell(cellfun(@(x) load(x,'data'),fullfile(behavSourceDir,fileNames)));
    % Load stimuli for trigger correction
    matchStr = 'stim.mat';
    fileNames = {listing.name}';
    fileNames = fileNames(~cellfun(@isempty,regexp(fileNames,matchStr,'once')));
    dataStim = cellfun(@(x) load(x,'stimAll','stimKeyAll'),...
                           fullfile(behavSourceDir,fileNames));
    
end

% Checking for existing result files, in which case the day is skipped
icaFileName = fullfile(destDir,['ftmeg_ICA_',subID,'.mat']);
resultFileName = fullfile(destDir,['ftmeg_MVPA_',subID,'.mat']);
if strcmp(runMode,'compICA') && exist(icaFileName,'file')
    warning('ICA has already been computed, returning! ');
    return;
elseif strcmp(runMode,'rejectICcomp') && exist(resultFileName,'file')
    warning('Components have already been rejected, returning! '); 
    return;
end

fprintf('\n\nProcessing files for subject %s...\n', subID);

if strcmp(runMode,'compICA')
    
    % Cell array for collecting result files
    resultFiles = cell(numel(sourceFileNames),1);
    
    for iFile = 1:size(sourceFileNames,1)
        %% Loading the source data
        ftDataHp = load(fullfile(sourceDir,sourceFileNames{iFile}));
        ftDataHp = ftDataHp.ftDataHp;
        
        %% low-pass filtering
        cfg = struct();
        cfg.lpfilter = 'yes';
        cfg.lpfreq = 45;
        cfg.lpfiltord = 5;
        cfg.lpfiltdir = 'twopass';
        ftDataLp = ft_preprocessing(cfg,ftDataHp);
        % Clearing unnecessary previous dataset
        ftDataHp = [];
        
        %% Epoching
        % Compute trigger offset
        trig = cell(1,size(dataStim.stimAll,2));
        fs = 44100;
        wordFreq = 1.6;
        incr = round(1/wordFreq*fs);
        nTrials = size(dataStim.stimAll,2);
        for j = 1:nTrials
            nStim = numel(dataStim.stimKeyAll{iFile,j});
            trig{j} = 1:incr:incr*nStim; 
        end
        trigOffset = cellfun(@compTrigOffset,dataStim.stimAll(iFile,:),...
                             repmat({fs},1,nTrials),trig,'UniformOutput',false);
        % Trial definition
        cfg = struct();
        cfg.headerfile = ...
            fullfile(maxfilterDir,[dataFileNames{iFile},'_trans1st.fif']);
        cfg.trialfun = 'ft_trialfun_eventlocked';
        cfg.trialdef = struct();
        cfg.trialdef.prestim = 0.1;
        cfg.trialdef.poststim = 0.5;
        cfg.trialdef.trigdef = trigDef;
        cfg.trialdef.trigOffset = cat(2,trigOffset{:});
        meegFiles = s.getField(subID,'meg_files');
        fileSpec = meegFiles(ismember(meegFiles.fileName,dataFileNames{iFile}),:);
        cfg.trialdef.fileSpec = fileSpec;
        cfg.trialdef.trig_audioonset_corr = setupSpec.trig_audioonset_corr_meg;
        cfg.trialdef.eventtype = 'Trigger';
        cfg = ft_definetrial(cfg);
        
        % epoching with background correction
        ftDataEp = ft_redefinetrial(cfg,ftDataLp);
        
        % Clearing unnecessary previous dataset
        ftDataLp = [];
        
        %% Rejecting trials based on artefacts.
        
        % Loading artefact data
        dataArtf = load(fullfile(sourceDir,artefactFileNames{iFile}));
        
        % Marking bad trials
        % Last column of trialinfo gives the following info:
        % 0 - good
        % 1 - no response
        % 2 - early response
        % 3 - wrong hand (not used here)
        % 4 - EEG artefact
        % 5 - missing eyetracker data
        % 6 - eyeblink
        % 7 - saccade
        % 8 - wrong fixation location
        badTrials = rejecttrials(ftDataEp,dataArtf, ...
            [0,0.625]);       % Window of interest which must be free of artefacts and eye events.
        ftDataEp.trialinfo = buildtrialinfo([ftDataEp.trialinfo,badTrials],...
            dataBehav{iFile},fileSpec);
        
        % Remove trials with artefacts from data.
        cfg = struct();
        cfg.trials = (badTrials == 0)';
        ftDataEp = ft_selectdata(cfg,ftDataEp);
        
        %% Downsampling
        cfg = struct();
        cfg.resamplefs = 250;
        cfg.detrend = 'no';
        resultFiles{iFile} = ft_resampledata(cfg,ftDataEp);
        % Clearing unnecessary previous dataset
        ftDataEp = [];
        
    end
    
    %% Merging files for the same day if necessary
    if numel(resultFiles) > 1
        ftDataMerged = ft_appenddata([],resultFiles{:});
    else
        ftDataMerged = resultFiles{1}; %#ok<*NASGU>
    end
    
    resultFiles = [];
    
    %% ICA for blink correction
    
    % Do ICA separately for the two modalities
    modality = {'megmag','megplanar'};
    ftData_IC = cell(size(modality));
    for iMod = 1:numel(modality)
        
        % ICA finds tons of slow wave components, so I should high pass
        % filter the data at higher frequency (1 Hz) before starting it the
        % unmixing marix can then also be applied to the original data
        cfg = struct();
        cfg.channel = modality{iMod};
        cfg.hpfilter = 'yes';
        cfg.hpfreq = 1;
        cfg.hpfiltord = 4;
        cfg.hpfiltdir = 'twopass';
        ftData_preICA = ft_preprocessing(cfg, ftDataMerged);
        
        % The data went through Maxfilter so some channels might have been
        % rejected and reconstructed. Find the rank of the data using the first
        % stimulus and set the number of components in ICA to that number
        nComp = rank(ftData_preICA.trial{1} * ftData_preICA.trial{1}');
        % Divide data into independent components
        ica_randseed(iMod) = randi(1000000,1); %#ok<AGROW>
        cfg = struct();
        cfg.method = 'runica';
        cfg.runica.pca = nComp;
        cfg.randomseed = ica_randseed(iMod);
        ftData_IC{iMod} = ft_componentanalysis(cfg, ftData_preICA);
        
    end
    % Save IC data
    fprintf('\n\nSaving ICA data...\n\n');
    save(icaFileName,'ftData_IC','ftDataMerged','modality',...
        'ica_randseed','-v7.3');
else
    
    if ~exist(icaFileName,'file')
        warning('ICA file is missing, please compute ICA first. Returning. ');
        return;
    end
    % Load ICA file
    fLoaded = load(icaFileName);
    ftData_IC = fLoaded.ftData_IC;
    ftDataMerged = fLoaded.ftDataMerged;
    modality = fLoaded.modality;
    
    ftDataClean = cell(size(modality));
    for iMod = 1:numel(modality)
        
        % inspect independent components (determine artifacts)
        cfg = struct();
        cfg.viewmode = 'component';
        cfg.layout = 'neuromag306all';
        cfg.continuous = 'yes';
        cfg.blocksize = 20;
        cfg.channel = 1:16;
        
        cfg = ft_databrowser(cfg, ftData_IC{iMod});
        
        % Reject ICA components
        prompt = {'ICA components to be rejected (e.g. [1, 2, 3])'};
        titleP = 'ICA prompt';
        lines = [1 70];
        default = {'[]'};
        Input = inputdlg(prompt, titleP, lines, default);
        
        % Select actual channel modality from original data
        cfg = struct();
        cfg.channel = modality{iMod};
        ftDataOrig = ft_selectdata(cfg,ftDataMerged);
        
        % Decompose the original data using the computed unmixing matrix
        cfg = struct();
        cfg.unmixing = ftData_IC{iMod}.unmixing;
        cfg.topolabel = ftData_IC{iMod}.topolabel;
        ftData_IC_orig = ft_componentanalysis(cfg,ftDataOrig);
        
        % Reconstruct the original data excluding the chosen components
        cfg = struct();
        cfg.component = eval(Input{:});
        ftDataClean{iMod} = ft_rejectcomponent(cfg,ftData_IC_orig,ftDataOrig);
    end
    
    % Merge data across modalities
    ftDataClean = ft_appenddata([],ftDataClean{:});
    
    %% Baseline correction
    cfg = struct();
    cfg.demean = 'yes';
    cfg.baselinewindow = [-0.1,0];
    ftDataClean = ft_preprocessing(cfg,ftDataClean);
    
    %% Saving data
    fprintf('\n\nSaving MEG data...\n\n');
    save(resultFileName,'ftDataClean','-v7.3');
    
    ftDataClean = [];
    
end

end
