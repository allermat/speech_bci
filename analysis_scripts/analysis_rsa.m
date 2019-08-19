function analysis_rsa(subID,varargin)
% Compute dissimilarity measures on MEG data

validAnalyses = {'words','noise'};

p = inputParser;

addRequired(p,'subID',@(x) validateattributes(x,{'char'},{'nonempty'}));
addParameter(p,'ftData',struct([]),@isstruct);
addParameter(p,'analysis','words',@(x) ismember(x,validAnalyses));
addParameter(p,'channel','all',@(x) validateattributes(x,{'char'},{'nonempty'}));
addParameter(p,'poolOverTime',false,@(x) validateattributes(x,{'logical'},{'scalar'}));

parse(p,subID,varargin{:});

subID = p.Results.subID;
ftData = p.Results.ftData;
analysis = p.Results.analysis;
channel = p.Results.channel;
poolOverTime = p.Results.poolOverTime;

% Loading data if necessary
if isempty(ftData)
    ftData = load(fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID),...
        sprintf('ftmeg_MVPA_%s.mat',subID)));
    ftData = ftData.ftDataClean;
end

% Select channels to be used
cfg = struct();
cfg.channel = channel;
ftData = ft_selectdata(cfg,ftData);

condDef = generateCondDef();
megData = ftData.trial;
trialInfo = struct2table(cell2mat(ftData.trialinfo));
trialInfo.target = categorical(trialInfo.target);
% Recoding target to numbers for consistency with the variable 'condition'
trialInfo.targetNum = rowfun(@(x) condDef.condition(condDef.wordId == x),...
                             trialInfo,'InputVariables',{'target'},...
                             'OutputFormat','Uniform');
trialInfo.idx = (1:size(trialInfo,1))';

if strcmp(analysis,'noise')
    targetIdx = varfun(@(x) x,trialInfo(trialInfo.condition == 4,:),...
                  'InputVariables',{'idx'},'GroupingVariables',...
                  {'iRun','iTrialInRun','target'});
    targets = unique(trialInfo.target);
    % Making sure targets are ordered the same as the condition labels
    [lia,locb]= ismember(condDef.wordId,targets);
    targets = targets(locb(lia));
    data = {};
    labels = [];
    for iTarget = 1:numel(targets)
        uniqueTrials = unique(targetIdx(targetIdx.target == targets(iTarget),{'iRun','iTrialInRun'}),'rows');
        tempData = cell(size(uniqueTrials,1),1);
        tempCond = NaN(size(uniqueTrials,1),1);
        for iTrial = 1:size(uniqueTrials,1)
            actSelection = targetIdx.Fun_idx(ismember(targetIdx(:,{'iRun','iTrialInRun'}), ...
                                                      uniqueTrials(iTrial,:)));
            temp = megData(actSelection);
            tempData{iTrial} = mean(cat(3,temp{:}),3);
            tempCond(iTrial) = condDef.condition(condDef.wordId == targets(iTarget));
        end
        data = cat(1,data,tempData);
        labels = cat(1,labels,tempCond);
    end
    data = shiftdim(cat(3,data{:}),2);
    
    [distAll,distWithin,distBetween] = distCrossval(data,labels,'doNoiseNorm',true,...
                                            'poolOverTime',poolOverTime);
    
else
    
    condIdx = varfun(@(x) x,trialInfo(ismember(trialInfo.condition,[1,2,3]),:),...
                     'InputVariables',{'idx'},'GroupingVariables',...
                     {'iRun','targetNum','condition'});
    conditions = unique(condIdx(:,{'targetNum','condition'}),'rows');
    nTrialPerCond = numel(unique(condIdx.iRun));
    data = {};
    labels = [];
    for iCond = 1:size(conditions,1)
        tempData = cell(nTrialPerCond,1);
        tempCond = NaN(nTrialPerCond,1);
        for iTrial = 1:nTrialPerCond
            actSelection = ...
                condIdx.Fun_idx(condIdx.iRun == iTrial & ...
                                condIdx.targetNum == conditions.targetNum(iCond) & ...
                                condIdx.condition == conditions.condition(iCond));
            temp = megData(actSelection);
            tempData{iTrial} = mean(cat(3,temp{:}),3);
            tempCond(iTrial) = iCond;
        end
        data = cat(1,data,tempData);
        labels = cat(1,labels,tempCond);
    end
    data = shiftdim(cat(3,data{:}),2);
    
    [distAll,distWithin,distBetween] = distCrossval(data,labels,'doNoiseNorm',true,...
                                            'poolOverTime',poolOverTime);
end

if poolOverTime
    fileName = sprintf('%s_time-pooled_chan-%s.mat',analysis,channel);
else
    fileName = sprintf('%s_time-resolved_chan-%s.mat',analysis,channel);
end

% Clearing variables before saving
clearvars ftData megData varargin p
% Saving data
save(fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subID),'RSA',fileName),'-v7.3');

end