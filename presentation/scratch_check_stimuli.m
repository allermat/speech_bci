%% Loading stimuli and condDef
load('stim.mat')
condDef = generateCondDef();

%% Checking word-condition association
idx = [1,4];
temp = num2cell(stimKeyAll{idx(1),idx(2)});
wordList = cellfun(@(x) condDef.wordId(condDef.condition == x),temp);
sound(stimAll{idx(1),idx(2)},44100)

%% Checking if all targets are presented equal number of times
cellfun(@(x) sum(nTargetsAll(ismember(targetWordsAll,x))),unique(targetWordsAll))