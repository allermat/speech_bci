function condDef = generateCondDef()

% Words used in the experiment
wordId = cat(2,sort({'yes','no','pain'}),{''})';
condition = (1:numel(wordId))';
stimType = cat(1,repmat({'word'},3,1),'noise');

condDef = table(condition,stimType,wordId);

end
