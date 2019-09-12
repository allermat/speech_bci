function [stim,stimKey] = BCI_generateStimulus(S)

p = inputParser;

fieldsReqS = {'audioNoise','audioWords','wordsLoaded','nCh','nNoiseStimuli',...
              'nRepetitionPerWord','nTargets','noiseLpCutoff','targetKey',...
              'nRepetitionMinimum','wordKey','randSelect'};

checkS = @(x) all(isfield(x,fieldsReqS));

addRequired(p,'S',checkS);

parse(p,S);

S = p.Results.S;

% unpacking input into variables
audioNoise = S.audioNoise;
audioWords = S.audioWords;
wordsLoaded = S.wordsLoaded;
vocodeMethod = S.vocodeMethod;
nCh = S.nCh;
nNoiseStimuli = S.nNoiseStimuli;
nRepetitionPerWord = S.nRepetitionPerWord;
nRepetitionMinimum = S.nRepetitionMinimum;
wordKey = S.wordKey;
uniqueWords = unique(wordsLoaded);
nUniqueWords = numel(uniqueWords);
randSelect = S.randSelect;
noiseLpCutoff = S.noiseLpCutoff;

% Generate noise
noise = cell(nNoiseStimuli,1);
for i = 1:nNoiseStimuli
    if randSelect
        % Select tokens randomly from the word set
        if numel(audioNoise) ~= numel(audioWords)
            error(['Random selection of tokens for noise requires the same word',...
                  'set for noise and words']);
        end
        % First find the indices of each repetition of each word in the loaded
        % audio data
        temp = cellfun(@(x) find(ismember(wordsLoaded,x)),uniqueWords,...
            'UniformOutput',false);
        % Choose randomly either of the instances of each word
        idx = cellfun(@(x) x(randi(numel(x))),temp);
        switch vocodeMethod
            case 'VOCODER'
                noise{i} = BCI_generateVocodedNoise(audioNoise(idx),nCh, ...
                    'lpCutoff',noiseLpCutoff);
            case 'STRAIGHT'
                noise{i} = BCI_generateNoiseStraight(audioNoise(idx), ...
                    'lpCutoff',noiseLpCutoff);
        end
    else
        % Use all available tokens to generate noise
        switch vocodeMethod
            case 'VOCODER'
                noise{i} = BCI_generateVocodedNoise(audioNoise,nCh, ...
                    'lpCutoff',noiseLpCutoff);
            case 'STRAIGHT'
                noise{i} = BCI_generateNoiseStraight(audioNoise, ...
                    'lpCutoff',noiseLpCutoff);
        end
    end
end

% Vocode words
wordsAll = cell(nRepetitionPerWord,nUniqueWords);
wordKeysAll = NaN(nRepetitionPerWord,nUniqueWords);
for iRep = 1:nRepetitionPerWord
    for iWord = 1:nUniqueWords
        idx = find(ismember(wordsLoaded,uniqueWords{iWord}));
        switch vocodeMethod
            case 'VOCODER'
                % Choose randomly either of the instances of the words
                [~,~,~,wordsAll{iRep,iWord}] = vocode_ma('noise','n','greenwood','half', ...
                    30,nCh,audioWords(idx(randi(2))),'');
                
            case 'STRAIGHT'
                wordsAll{iRep,iWord} = applyStraight(audioWords(idx(randi(2))));
        end
       wordKeysAll(iRep,iWord) = wordKey(iWord);
    end
end
noiseKey = numel(wordKey)+1;

% Devide targ into two subparts and randomize separately
stim_1 = wordsAll(1:nRepetitionMinimum,:);
stim_1 = stim_1(:);
stim_1 = cat(1,stim_1,cat(1,noise(1:nRepetitionMinimum*nUniqueWords)));
stimKey_1 = wordKeysAll(1:nRepetitionMinimum,:);
stimKey_1 = stimKey_1(:);
stimKey_1 = cat(1,stimKey_1,cat(1,noiseKey*ones(nRepetitionMinimum*nUniqueWords,1)));
randVector = randperm(size(stim_1,1));
stim_1 = stim_1(randVector);
stimKey_1 = stimKey_1(randVector);

stim_2 = wordsAll(nRepetitionMinimum+1:end,:);
stim_2 = stim_2(:);
stim_2 = cat(1,stim_2,cat(1,noise(nRepetitionMinimum*nUniqueWords+1:end)));
stimKey_2 = wordKeysAll(nRepetitionMinimum+1:end,:);
stimKey_2 = stimKey_2(:);
stimKey_2 = cat(1,stimKey_2,...
                cat(1,noiseKey*ones(nNoiseStimuli-nRepetitionMinimum*nUniqueWords,1)));
randVector = randperm(size(stim_2,1));
stim_2 = stim_2(randVector);
stimKey_2 = stimKey_2(randVector);
% Removing instances of target word if necessary
if S.nTargets < S.nRepetitionPerWord
    nToRemove = S.nRepetitionPerWord-S.nTargets;
    idx = find(ismember(stimKey_2,S.targetKey));
    stim_2(idx(1:nToRemove)) = [];
    stimKey_2(idx(1:nToRemove)) = [];
end
stim = cat(2,stim_1{:},stim_2{:});
% Normalize stimulus between +/-1
stim = stim./max(abs(stim));
stimKey = cat(2,stimKey_1',stimKey_2');

end