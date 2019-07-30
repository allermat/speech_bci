function preproc_EYE(subID)
% DEC_2 project EEG preprocessing common stage

%% Parsing input, checking matlab
p = inputParser;

addRequired(p,'subID',@(x)validateattributes(x, ...
            {'numeric'},{'scalar','integer','positive'}));
        
parse(p,subID);

subID = p.Results.subID;

if isempty(regexp(path,'parfor_progress','once'))
    error('parfor_progress not found in path!');
end

%% Opening parallel pool. 
currPool = gcp('nocreate');
% if there is no parallel pool opened, open one.
if isempty(currPool)
    parpool('local');
end

%% Preparing file and directory names for the processing pipeline.
tag = 'EYE';

dataDir = AVWM_setupdir('data_behav_sub',num2str(subID));
analysisDir = fullfile(AVWM_setupdir('anal_eeg_sub',num2str(subID)),tag);
if ~exist(analysisDir,'dir')
    mkdir(analysisDir);
end

% Getting data file names
saveDf = cd(dataDir);
% fileNames = sort_nat(cellstr(ls([num2str(subID),'_exp*eyelink*.asc'])));
fileNames = sort_nat(cellstr(ls([num2str(subID),'_*eyelink*.asc'])));
cd(saveDf);

% Loading files specifying parameters
% Trigger definition
trigDef = generateTrigDef(generateCondDef);
% Setup specifics
setupSpec = load('setup_spec.mat');
setupSpec = setupSpec.setup_spec;
setupSpec = setupSpec(ismember({setupSpec.description},'presentation'));

stimTriggers = trigDef.trig_eye(ismember(trigDef.type,{'S1','S2'}));
trig_visonset_corr_eyelink = setupSpec.trig_visonset_corr_eyelink;

dataEye = struct('run',[],'event',[],'Fs',[]);
dataEye(size(fileNames,1)).run = [];

fprintf('\n\nConverting files...\n');
parfor_progress(size(fileNames,1));

parfor iFile = 1:size(fileNames,1)
    
    %% Reading raw data
    [event,hdr] = read_eyelink_event(fullfile(dataDir,fileNames{iFile}));
    
    evValues = {event.value}';
    evTypes = {event.type}';
    evStartSamples = [event.sample]';
    % Finding the onset samples of stimulus triggers
    targEvStartSamples = evStartSamples(ismember(evTypes,'Stimulus') & ...
        ismember(evValues,stimTriggers));
    % Correcting stimulus triggers for trigger-visual onset asynchrony
    targEvStartSamples = targEvStartSamples+(trig_visonset_corr_eyelink*hdr.Fs);
    % Saving corrected values into the original structure
    evStartSamples(ismember(evTypes,'Stimulus') & ...
        ismember(evValues,stimTriggers)) = targEvStartSamples;
    evStartSamples = num2cell(evStartSamples);
    [event.sample] = evStartSamples{:};
    
    dataEye(iFile).run = iFile; %#ok<PFOUS>
    dataEye(iFile).event = event;
    dataEye(iFile).Fs = hdr.Fs;
    
    % Advancing Progress monitor
    parfor_progress;
    
end
% Finalizing progress monitor.
parfor_progress(0);

%% Saving data
fprintf('\n\nSaving data...\n\n');
savePath = fullfile(analysisDir,[tag,'_',num2str(subID),'.mat']);
save(savePath,'dataEye','-v7.3');
    


%% Closing parallel pool. 
% currPool = gcp('nocreate');
% % If there is a parallel pool opened, close it. 
% if ~isempty(currPool)
%     delete(currPool);
% end

end
