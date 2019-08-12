% Loading data
vars = who;
if ~ismember('ftDataClean',vars)
    load(fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc','meg19_0251'),...
                               'ftmeg_MVPA_meg19_0251.mat'));
else
    clearvars -except 'ftDataClean'
end

% Select channels to be used
cfg = struct();
cfg.channel = 'all';
ftDataSelection = ft_selectdata(cfg,ftDataClean);

condDef = generateCondDef();
megData = ftDataSelection.trial;
trialInfo = struct2table(cell2mat(ftDataSelection.trialinfo));
trialInfo.target = categorical(trialInfo.target);
trialInfo.idx = (1:size(trialInfo,1))';

analysis = 'noise';
% analysis = 'words';

if strcmp(analysis,'noise')
    targetIdx = varfun(@(x) x,trialInfo(trialInfo.condition == 4,:),...
                  'InputVariables',{'idx'},'GroupingVariables',...
                  {'iRun','iTrialInRun','target'});
    targets = unique(trialInfo.target);
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
    % % Average across timepoints
    % data = mean(data,3);
    % % Vectorize data
    % s = size(data);
    % data = reshape(data,s(1),s(2)*s(3));
    
    distCrossval(data,labels,'doNoiseNorm',true);
    
else
    
    condIdx = varfun(@(x) x,trialInfo(ismember(trialInfo.condition,[1,2,3]),:),...
                     'InputVariables',{'idx'},'GroupingVariables',...
                     {'iRun','condition'});
    conditions = unique(condIdx.condition);
    data = {};
    labels = [];
    for iCond = 1:numel(conditions)
        tempData = cell(size(uniqueTrials,1),1);
        tempCond = NaN(size(uniqueTrials,1),1);
        for iTrial = 1:size(uniqueTrials,1)
            actSelection = condIdx.Fun_idx(condIdx.iRun == iTrial & ...
                                           condIdx.condition == conditions(iCond));
            temp = megData(actSelection);
            tempData{iTrial} = mean(cat(3,temp{:}),3);
            tempCond(iTrial) = conditions(iCond);
        end
        data = cat(1,data,tempData);
        labels = cat(1,labels,tempCond);
    end
    data = shiftdim(cat(3,data{:}),2);
    % % Average across timepoints
    % data = mean(data,3);
    % % Vectorize data
    % s = size(data);
    % data = reshape(data,s(1),s(2)*s(3));
    
    result_cv = distCrossval(data,labels,'doNoiseNorm',true)
end




% % Plotting number of noise trials per target
% clear g
% g(1,1) = gramm('x',temp.Fun_target,'y',temp.GroupCount,'color',temp.iRun);
% g(1,2) = gramm('x',temp.iRun,'y',temp.GroupCount,'color',temp.Fun_target);
% %Jittered scatter plot
% g(1,1).geom_jitter('width',0.4,'height',0);
% g(1,1).set_title('Noise trials per target');
% g(1,1).set_names('x','Target word','y','Number of noise trials',...
%                  'color','Run number');
% 
% g(1,2).geom_jitter('width',0.4,'height',0);
% g(1,2).set_title('Noise trials per target');
% g(1,2).set_names('x','Run number','y','Number of noise trials',...
%                  'color','Target word');
% figure();
% g.draw();