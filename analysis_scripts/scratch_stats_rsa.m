load('noise_time-movingWin_chan-all.mat');
timeWin = [275,325;...
           400,500];

for i = 1:size(timeWin,1)
    idx = timeLabel >= timeWin(i,1) & timeLabel <= timeWin(i,2);
    w = squeeze(nanmean(nanmean(nanmean(distWithin_indiv(:,:,idx,:)))));
    b = squeeze(nanmean(nanmean(nanmean(distBetween_indiv(:,:,idx,:)))));
    [h(i),p(i),ci(i,:),stats(i)] = ttest(b,w);
end
