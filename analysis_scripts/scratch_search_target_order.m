nTrialsPerTarget = 4;
e = ones(nTrialsPerTarget);
avgMask = [e,e*2,e*3;e*2,e*4,e*5;e*3,e*5,e*6];
avgMask = avgMask(tril(avgMask,-1)~=0);

rng('shuffle');

threshold = 0.05;
targetOrder = cat(1,ones(nTrialsPerTarget,1),ones(nTrialsPerTarget,1)*2,...
                    ones(nTrialsPerTarget,1)*3);
% targetOrder = repmat([1,1,1,1,2,2,2,2,3,3,3,3]',6,1);
targetOrder_collection = cell(6,1);
cnt = 0;
while 1
    
    
    % Compute pairvise distance between the trial numbers (arranged by
    % target condition)
    [~,idx] = sort(targetOrder);
    temp = pdist(idx);
    tempDist = arrayfun(@(x) mean(temp(avgMask == x)),unique(avgMask));
    b = mean(tempDist([2,3,5]));
    w = mean(tempDist([1,4,6]));
    if abs(b-w) < threshold
        % if max(tempDist)-min(tempDist) < threshold
        % break;
        cnt = cnt +1;
        targetOrder_collection{cnt} = targetOrder;
        if cnt == 6
            break;
        else
            targetOrder = targetOrder(randperm(numel(targetOrder)));
        end
    else
        % This suffles across all runs
        targetOrder = targetOrder(randperm(numel(targetOrder)));
        % This shuffling respects run boundaries
%         permVec = arrayfun(@(x) randperm(x),12*ones(6,1),'UniformOutput',false);
%         permVec = cellfun(@plus,permVec,{0,12,24,36,48,60}','UniformOutput',false);
%         permVec = cat(2,permVec{:});
%         targetOrder = targetOrder(permVec);
    end

end

for i = 1:numel(targetOrder_collection)
    targetOrder = targetOrder_collection{i};
    [~,idx] = sort(targetOrder);
    temp = pdist(idx);
    tempDist = arrayfun(@(x) mean(temp(avgMask == x)),unique(avgMask));
    b = mean(tempDist([2,3,5]));
    w = mean(tempDist([1,4,6]));
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