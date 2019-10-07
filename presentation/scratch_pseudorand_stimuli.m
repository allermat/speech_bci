% There has to be at least this many other stimuli between each repetition
% of the same stimulus. It seems to covnerge pretty quickly wihth n = 2,
% but it becomes too long after above that. 
n = 2;
stimuli = repmat(1:6,8,1);
stimuli = cat(1,ones(16,1)*7,stimuli(:));

while 1
    temp = stimuli(randperm(numel(stimuli)));
    isFailed = arrayfun(@(x) any(diff(find(temp == x)) < n),unique(stimuli));
    if all(~isFailed)
        break;
    end
end

stimuli = temp;