function condDef = generateCondDef()

% Words used in the experiment
wordId = {'yes','no','maybe',''}';
condition = (1:numel(wordId))';
stimType = cat(1,repmat({'word'},3,1),'noise');

condDef = table(condition,stimType,wordId);

end
