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

poolOverTime = true;

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
    
    [distWithin,distBetween] = distCrossval(data,labels,'doNoiseNorm',true,...
                                            'poolOverTime',poolOverTime);
else
    
    condIdx = varfun(@(x) x,trialInfo(ismember(trialInfo.condition,[1,2,3]),:),...
                     'InputVariables',{'idx'},'GroupingVariables',...
                     {'iRun','condition'});
    conditions = unique(condIdx.condition);
    nTrials = numel(unique(condIdx.iRun));
    data = {};
    labels = [];
    for iCond = 1:numel(conditions)
        tempData = cell(nTrials,1);
        tempCond = NaN(nTrials,1);
        for iTrial = 1:nTrials
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
    
    [distWithin,distBetween] = distCrossval(data,labels,'doNoiseNorm',true,...
                                            'poolOverTime',poolOverTime);
end


if poolOverTime
    distAll = distBetween;
    distAll = triu(distAll)+triu(distAll)';
    distAll(logical(eye(size(distAll)))) = diag(distWithin);
    
    figure(); 
    imagesc(distAll);
    colormap(redblue);
    c = colorbar;
    c.Label.String = 'Crossnobis distance';
    set(gca,'XTick',[1,2,3],'YTick',[1,2,3]);
    if strcmp(analysis,'noise')
        tickLabels = cellstr(targets);
        titleStr = sprintf('Decoding target word from noise\npooled over time');
    else
        tickLabels = condDef.wordId(ismember(condDef.condition,conditions));
        titleStr = sprintf('Decoding presented word\npooled over time');
    end
    set(gca,'XTickLabel',tickLabels,'YTickLabel',tickLabels)
    title(titleStr);
else
    % Time resolved figure
    distAll = distBetween;
    for i = 1:size(distWithin,3)
        temp = distAll(:,:,i);
        temp = triu(temp)+triu(temp)';
        temp(logical(eye(size(temp)))) = diag(distWithin(:,:,i));
        distAll(:,:,i) = temp;
    end
    figure;
    hold on;
    plot(-100:4:500, squeeze(nanmean(nanmean(distBetween, 1), 2)), 'linewidth', 2);
    plot(-100:4:500, squeeze(nanmean(nanmean(distWithin, 1), 2)), 'linewidth', 2);
    xlim([-100 500]);
    xlabel('Time [ms]');
    ylabel('Crossnobis distance');
    legend('Between', 'Within', 'location', 'NorthWest');
    if strcmp(analysis,'noise')
        title(sprintf('Decoding target word from noise\ntime resolved'));
    else
        title(sprintf('Decoding presented word\ntime resolved'));
    end
    
    % Average across time figure
    figure(); 
    imagesc(mean(distAll,3));
    colormap(redblue);
    c = colorbar;
    c.Label.String = 'Crossnobis distance';
    set(gca,'XTick',[1,2,3],'YTick',[1,2,3]);
    if strcmp(analysis,'noise')
        tickLabels = cellstr(targets);
        titleStr = sprintf('Decoding target word from noise\nmean across time');
    else
        tickLabels = condDef.wordId(ismember(condDef.condition,conditions));
        titleStr = sprintf('Decoding presented word\nmean across time');
    end
    set(gca,'XTickLabel',tickLabels,'YTickLabel',tickLabels)
    title(titleStr);
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