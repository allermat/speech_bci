function trialIdxEliminated = equalize_target_temporal_distance(targetWords,varargin)

p = inputParser;

addRequired(p,'targetWords',@(x) validateattributes(x,{'cell'},{'column'}));
addParameter(p,'threshold',0.05,@(x) validateattributes(x,{'numeric'}, ...
            {'finite','positive'}));
addParameter(p,'nToEliminate',2,@(x) validateattributes(x,{'numeric'}, ...
            {'finite','integer','positive'}));
addParameter(p,'plotFigure',false,@(x) validateattributes(x,{'logical'}, ...
            {'scalar'}));

parse(p,targetWords,varargin{:});

targetWords = p.Results.targetWords;
threshold = p.Results.threshold;
nToEliminate = p.Results.nToEliminate;
plotFigure = p.Results.plotFigure;

targets = unique(targetWords);

rng('shuffle');

while 1
    trialIdxEliminated = {};
    targetOrder = targetWords;
    % Remove equal number of trials per target condition randomly
    for i = 1:numel(targets)
        targIdx = find(ismember(targetOrder,targets{i}));
        trialIdxEliminated{i} = targIdx(randperm(numel(targIdx),nToEliminate));  %#ok<AGROW>
    end
    targetOrder(cat(1,trialIdxEliminated{:})) = [];
    % mask for averaging over target conditions in distance vector
    nTrialsPerTarget = sum(ismember(targetOrder,targets{1}));
    e = ones(nTrialsPerTarget);
    avgMask = [e,e*2,e*3;e*2,e*4,e*5;e*3,e*5,e*6];
    avgMask = avgMask(tril(avgMask,-1)~=0);
    
    % Compute pairvise distance between the trial numbers (arranged by
    % target condition) !!CAUTION!! THE ORDER OF TARGET CONDITIONS HERE 
    % WILL BE ALPHABETICAL, SO: MAYBE - NO - YES
    [~,idx] = sort(targetOrder);
    temp = pdist(idx);
    tempDist = arrayfun(@(x) mean(temp(avgMask == x)),unique(avgMask));
    b = mean(tempDist([2,3,5]));
    w = mean(tempDist([1,4,6]));
    if abs(b-w) < threshold
        break;
    end

end

trialIdxEliminated = sort(cat(1,trialIdxEliminated{:}));

if plotFigure
    % Avarage over distances for a target condition
    temp = NaN(3);
    temp(tril(true(size(temp)))) = tempDist;
    temp(triu(true(size(temp)),1)) = temp(tril(true(size(temp)),-1));
    dist = temp;
    
    figure();
    subplot(1,2,1);
    imagesc(dist); axis square;
    colormap(magma);
    colorbar;
    subplot(1,2,2);
    b_err = std(tempDist([2,3,5]));
    w_err = std(tempDist([1,4,6]));
    barwitherr([b_err,w_err],[b,w]);
    set(gca,'XTickLabel',{'between','within'});
end

end
