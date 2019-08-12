root = '/home/ma09/Documents/MATLAB/guggenmos_tutorial_matlab'; 
% Load data and trial labels for the two sessions of participant 01

load(fullfile(root, 'data01_sess1.mat'));
load(fullfile(root, 'labels01_sess1.mat'));

cvMethod = 'leaveOneOut';
if strcmp(cvMethod,'random')
    data = data01_sess1;
    labels = labels01_sess1';
else
    dataIn = data01_sess1;
    labelsIn = labels01_sess1;
    n_trials = histcounts(labelsIn,'BinMethod','integers');
    conditions = unique(labelsIn);
    nTrialPseudo = 4;
    
    data = {};
    labels = [];
    for iCond = 1:numel(conditions)
        trlIdx = mod(randperm(n_trials(iCond)),nTrialPseudo);
        trlIdx(trlIdx == 0) = nTrialPseudo;
        tempData = cell(nTrialPseudo,1);
        tempLabels = NaN(nTrialPseudo,1);
        for iTrial = 1:nTrialPseudo
            temp = find(labelsIn == conditions(iCond));
            actSelection = temp(trlIdx == iTrial);
            
            tempData{iTrial} = mean(dataIn(actSelection,:,:),1);
            tempLabels(iTrial) = conditions(iCond);
        end
        data = cat(1,data,tempData);
        labels = cat(1,labels,tempLabels);
    end
    data = cat(1,data{:});
end
result_cv_check = distCrossval(data,labels,'doNoiseNorm',true);

figure;
hold on
plot(-100:10:1001, squeeze(nanmean(nanmean(result_cv_check, 1), 2)), 'linewidth', 2)
xlim([-100 1000])
xlabel('Time [ms]')
ylabel('Euclidean distance')

