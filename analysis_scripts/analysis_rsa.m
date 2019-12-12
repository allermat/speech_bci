function analysis_rsa(subID,varargin)
% Compute dissimilarity measures on MEG data

validAnalyses = {'words','noise','all'};
validTimeModes = {'resolved','pooled','movingWin'};
p = inputParser;

addRequired(p,'subID',@(x) validateattributes(x,{'char'},{'nonempty'}));
addParameter(p,'ftData',struct([]),@isstruct);
addParameter(p,'analysis','words',@(x) ismember(x,validAnalyses));
addParameter(p,'channel','all',@(x) validateattributes(x,{'char'},{'nonempty'}));
addParameter(p,'timeMode','resolved',@(x) ismember(x,validTimeModes));
addParameter(p,'equalizeTargetDistance',false,...
             @(x) validateattributes(x,{'logical'},{'scalar'}));
addParameter(p,'equalizeNtoAvg',false,...
             @(x) validateattributes(x,{'logical'},{'scalar'}));

parse(p,subID,varargin{:});

subID = p.Results.subID;
ftData = p.Results.ftData;
analysis = p.Results.analysis;
channel = p.Results.channel;
timeMode = p.Results.timeMode;
equalizeTargetDistance = p.Results.equalizeTargetDistance;
equalizeNtoAvg = p.Results.equalizeNtoAvg;

if equalizeNtoAvg
    nToAvg = 10;
end

% Loading data if necessary
if isempty(ftData)
    ftData = load(fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID),...
        sprintf('ftmeg_MVPA_%s.mat',subID)));
    ftData = ftData.ftDataClean;
end

trialInfo = struct2table(cell2mat(ftData.trialinfo));
if equalizeTargetDistance
    % Equalize target temporal distances
    tempTrials = unique(trialInfo(:,{'iRun','iTrialInRun','target'}),'rows');
    idxToRemove = equalize_target_temporal_distance(tempTrials.target,...
        'nToEliminate',4,'plotFigure',true);
    trialsToKeep = ~ismember(trialInfo(:,{'iRun','iTrialInRun'}),...
                             tempTrials(idxToRemove,{'iRun','iTrialInRun'}),...
                             'rows')';
else
    trialsToKeep = true(1,size(trialInfo,1));
end

% Select channels and trials if applicable
cfg = struct();
cfg.channel = channel;
cfg.trials = trialsToKeep;
ftData = ft_selectdata(cfg,ftData);

condDef = generateCondDef();
megData = ftData.trial;
% Trials might have been potentially removed previously, so better create
% trialInfo from fieldtrip file again. 
trialInfo = struct2table(cell2mat(ftData.trialinfo));
trialInfo.target = categorical(trialInfo.target);
% Recoding target to numbers for consistency with the variable 'condition'
trialInfo.targetNum = rowfun(@(x) condDef.condition(condDef.wordId == x),...
                             trialInfo,'InputVariables',{'target'},...
                             'OutputFormat','Uniform');
trialInfo.idx = (1:size(trialInfo,1))';

switch analysis
    case 'noise'
        condSelection = condDef.condition(ismember(condDef.stimType,'noise'));
    case 'words'
        condSelection = condDef.condition(ismember(condDef.stimType,'word'));
    case 'all'
        condSelection = condDef.condition;
end

stimIdx = varfun(@(x) x,trialInfo(ismember(trialInfo.condition,condSelection),:),...
    'InputVariables',{'idx'},'GroupingVariables',...
    {'iRun','iTrialInRun','targetNum','condition'});
conditions = unique(stimIdx(:,{'targetNum','condition'}),'rows');
if strcmp(analysis,'all')
    conditions = sortrows(conditions,{'condition','targetNum'});
end
data = {};
labels = [];
nStimAvg = [];
for iCond = 1:size(conditions,1)
    actCondIdx = ismember(stimIdx(:,{'targetNum','condition'}),conditions(iCond,:));
    uniqueTrials = unique(stimIdx(actCondIdx,{'iRun','iTrialInRun'}),'rows');
    tempData = cell(size(uniqueTrials,1),1);
    [tempCond,tempNstimAvg] = deal(NaN(size(uniqueTrials,1),1));
    for iTrial = 1:size(uniqueTrials,1)
        actSelection = stimIdx.Fun_idx(actCondIdx & ...
                           ismember(stimIdx(:,{'iRun','iTrialInRun'}),...
                           uniqueTrials(iTrial,:)));
        if equalizeNtoAvg
            % Average exactly nToAvg stimuli and get rid of the trial if it
            % has less than that amount of stimuli
            if numel(actSelection) >= nToAvg
                temp = megData(actSelection(randsample(1:numel(actSelection),nToAvg)));
                tempData{iTrial} = mean(cat(3,temp{:}),3);
                tempCond(iTrial) = iCond;
                tempNstimAvg(iTrial) = numel(actSelection);
            end
        else
            % Average all available stimuli in each trial
            temp = megData(actSelection);
            tempData{iTrial} = mean(cat(3,temp{:}),3);
            tempCond(iTrial) = iCond;
            tempNstimAvg(iTrial) = numel(actSelection);
        end
    end
        
    data = cat(1,data,tempData(~isnan(tempNstimAvg)));
    labels = cat(1,labels,tempCond(~isnan(tempNstimAvg)));
    nStimAvg = cat(1,nStimAvg,tempNstimAvg(~isnan(tempNstimAvg)));
end

% Make sure there are even number of averaged trials and they are equal
% across conditions
nTrialsPerCond = histcounts(labels,'BinMethod','integers');
nToKeep = min(nTrialsPerCond);
if mod(nToKeep,2) == 1
    nToKeep = nToKeep-1;
end
uniqueLabels = unique(labels);
for i = 1:numel(uniqueLabels)
    % Removing surplus trials
    actIdx = find(labels == uniqueLabels(i));
    idxToRemove = actIdx(randsample(1:numel(actIdx),numel(actIdx)-nToKeep));
    data(idxToRemove) = [];
    labels(idxToRemove) = [];
    nStimAvg(idxToRemove) = [];
end
% Reshaping data to fit subsequent analysis better
data = shiftdim(cat(3,data{:}),2);

switch timeMode
    case 'pooled'
        timeIdx = {1:numel(ftData.time{1})};
        timeLabel = []; %#ok<*NASGU>
    case 'resolved'
        timeIdx = num2cell(1:numel(ftData.time{1}));
        timeLabel = ftData.time{1}.*1000;
    case 'movingWin'
        t = cellfun(@plus,num2cell(-50:4:800),...
                    repmat({-50:4:0},1,size(-50:4:800,2)),...
                    'UniformOutput',false);
        timeIdx = cellfun(@(x) find(ismembertol(ftData.time{1},x./1000)),...
                          t,'UniformOutput',false);
        timeLabel = cellfun(@max,t);
end

[distAll,distWithin,distBetween] = distCrossval(data,labels,'doNoiseNorm',true,...
    'timeIdx',timeIdx);

% Clearing variables before saving
clearvars ftData megData varargin p
% Saving data
fileName = sprintf('%s_time-%s_chan-%s_%s.mat',analysis,timeMode,channel,...
                   datestr(now,'yymmddHHMMSS'));
destDir = fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subID),'RSA');
if ~exist(destDir,'dir'), mkdir(destDir); end
save(fullfile(destDir,fileName),'analysis','channel','condDef',...
    'conditions','condSelection','distAll','distBetween','distWithin',...
    'subID','timeLabel','timeMode','-v7.3');

end