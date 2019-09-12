%% Separately for each run
s = subjSpec;
subjList = sort({s.subjInfo.subID});
distAll = cell(numel(subjList),1);
for iSub = 1:numel(subjList)
    load(fullfile(BCI_setupdir('data_behav_sub',subjList{iSub}),'stim.mat'),'targetWordsAll');
    targets = {'yes','no','maybe'};
    % mask for averaging over target conditions in distance vector
    nTrialsPerTarget = sum(ismember(targetWordsAll(1,:),targets{1}));
    e = ones(nTrialsPerTarget);
    avgMask = [e,e*2,e*3;e*2,e*4,e*5;e*3,e*5,e*6];
    avgMask = avgMask(tril(avgMask,-1)~=0);
    %
    distSubj = cell(size(targetWordsAll,1),1);
    for iRun = 1:size(targetWordsAll,1)
        targTrialNumbers = [];
        for i = 1:numel(targets)
            targTrialNumbers = cat(1,targTrialNumbers,find(ismember(targetWordsAll(iRun,:),targets{i}))');
        end
        % Compute pairvise distance between the trial numbers (arranged by
        % target condition)
        temp = pdist(targTrialNumbers);
        % Avarage over distances for a target condition
        tempDist = arrayfun(@(x) mean(temp(avgMask == x)),unique(avgMask));
        temp = NaN(3);
        temp(tril(true(size(temp)))) = tempDist;
        temp(triu(true(size(temp)),1)) = temp(tril(true(size(temp)),-1));
        distSubj{iRun} = temp;
    end
    % The first subject completed only 5 runs
    if iSub == 1
        distSubj(end) = [];
    end
    distAll{iSub} = mean(cat(3,distSubj{:}),3);
    
    figure(); imagesc(distAll{iSub}); axis square;
    colormap(magma);
    colorbar;
end

%% All runs together in series (closer to the actual cross-validation)
s = subjSpec;
subjList = sort({s.subjInfo.subID});
distAll = cell(numel(subjList),1);
for iSub = 1:numel(subjList)
    load(fullfile(BCI_setupdir('data_behav_sub',subjList{iSub}),'stim.mat'),'targetWordsAll');
    targets = {'yes','no','maybe'};
    % mask for averaging over target conditions in distance vector
    nTrialsPerTarget = sum(ismember(targetWordsAll(:),targets{1}));
    e = ones(nTrialsPerTarget);
    avgMask = [e,e*2,e*3;e*2,e*4,e*5;e*3,e*5,e*6];
    avgMask = avgMask(tril(avgMask,-1)~=0);
    %
    targTrialNumbers = [];
    for i = 1:numel(targets)
        targTrialNumbers = cat(1,targTrialNumbers,find(ismember(reshape(targetWordsAll',1,[]),targets{i}))');
    end
    % Compute pairvise distance between the trial numbers (arranged by
    % target condition)
    temp = pdist(targTrialNumbers);
    % Avarage over distances for a target condition
    tempDist = arrayfun(@(x) mean(temp(avgMask == x)),unique(avgMask));
    temp = NaN(3);
    temp(tril(true(size(temp)))) = tempDist;
    temp(triu(true(size(temp)),1)) = temp(tril(true(size(temp)),-1));
        
    distAll{iSub} = temp;
    
    figure(); 
    subplot(1,2,1);
    imagesc(distAll{iSub}); axis square;
    colormap(magma);
    colorbar;
    subplot(1,2,2);
    b = mean(distAll{iSub}([2,3,6]));
    b_err = std(distAll{iSub}([2,3,6]));
    w = mean(distAll{iSub}([1,5,9]));
    w_err = std(distAll{iSub}([1,5,9]));
    barwitherr([b_err,w_err],[b,w]);
    set(gca,'XTickLabel',{'between','within'});
end

%% Code snippet for testing orderings
nTrialsPerTarget = 24;
e = ones(nTrialsPerTarget);
avgMask = [e,e*2,e*3;e*2,e*4,e*5;e*3,e*5,e*6];
avgMask = avgMask(tril(avgMask,-1)~=0);

% ordering = [1,2,3,4,5,6,7,8,9,10,11,12]';
[~,ordering] = sort(cat(1,targetOrder_collection{:}));
% Compute pairvise distance between the trial numbers (arranged by
% target condition)
temp = pdist(ordering);
% Avarage over distances for a target condition
tempDist = arrayfun(@(x) mean(temp(avgMask == x)),unique(avgMask));
temp = NaN(3);
temp(tril(true(size(temp)))) = tempDist;
temp(triu(true(size(temp)),1)) = temp(tril(true(size(temp)),-1));
dist = temp;

b = mean(tempDist([2,3,5]));
w = mean(tempDist([1,4,6]));
b_err = std(tempDist([2,3,5]));
w_err = std(tempDist([1,4,6]));
figure(); 
subplot(1,2,1);
imagesc(dist); axis square;
colormap(magma);
colorbar;
subplot(1,2,2);
barwitherr([b_err,w_err],[b,w]);
set(gca,'XTickLabel',{'between','within'});
