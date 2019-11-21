function condDef = generateCondDef()

% Words used in the experiment
wordId = {'yes','no','help','pain','hot','cold','',''}';
condition = (1:numel(wordId))';
stimType = cat(1,repmat({'word'},6,1),'noise_sum','noise_ws');

condDef = table(condition,stimType,wordId);

end
