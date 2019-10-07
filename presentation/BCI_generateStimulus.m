function [stim,stimKey,stimDuration] = BCI_generateStimulus(S)

p = inputParser;

fieldsReqS = {'audioNoise','audioWords','wordsLoaded','jitter','prestim','nCh',...
              'nNoiseStimuli','nRepetitionPerWord','nTargets',...
              'noiseLpCutoff','targetKey','nRepetitionMinimum','wordKey',...
              'randSelect'};

checkS = @(x) all(isfield(x,fieldsReqS));

addRequired(p,'S',checkS);

parse(p,S);

S = p.Results.S;

% unpacking input into variables
audioNoise = S.audioNoise;
audioWords = S.audioWords;
wordsLoaded = S.wordsLoaded;
vocodeMethod = S.vocodeMethod;
jitter = S.jitter;
prestim = S.prestim;
nCh = S.nCh;
nNoiseStimuli = S.nNoiseStimuli;
nRepetitionPerWord = S.nRepetitionPerWord;
% nRepetitionMinimum = S.nRepetitionMinimum;
wordKey = S.wordKey;
uniqueWords = unique(wordsLoaded);
randSelect = S.randSelect;
noiseLpCutoff = S.noiseLpCutoff;

% Applying STRAIGHT only once for each token
if strcmp(vocodeMethod,'STRAIGHT')
    if ~randSelect
        noise_straight = BCI_generateNoiseStraight(audioNoise, ...
                    'lpCutoff',noiseLpCutoff);
    end
    words_straight = cell(size(audioWords));
    for i = 1:numel(words_straight)
        words_straight{i} = applyStraight(audioWords(i));
    end
end

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
                noise{i} = noise_straight;
        end
    end
    % Add jitter if necessary
    if jitter > 0
        noise{i} = cat(2,noise{i},zeros(1,round((prestim+jitter*rand())*audioNoise(1).Fs)));
    end
end

% Vocode words
wordKeysAll = repmat(wordKey,nRepetitionPerWord,1);
wordKeysAll = wordKeysAll(:);
% Adding instances of target word if necessary
if S.nTargets > nRepetitionPerWord
    nToAdd = nRepetitionPerWord-S.nTargets;
    wordKeysAll = cat(1,wordKeysAll,repmat(S.targetKey,nToAdd,1));
end
wordsAll = cell(size(wordKeysAll));

for iWord = 1:numel(wordsAll)
    idx = find(ismember(wordsLoaded,uniqueWords{wordKey == wordKeysAll(iWord)}));
%     idx = idx(randi(numel(idx)));
    switch vocodeMethod
        case 'VOCODER'
            % Choose randomly either of the instances of the words
            [~,~,~,wordsAll{iWord}] = vocode_ma('noise','n','greenwood','half', ...
                30,nCh,audioWords(idx),'');
            
        case 'STRAIGHT'
            wordsAll{iWord} = words_straight{idx};
    end
    % Add jitter if necessary
    if jitter > 0
        wordsAll{iWord} = cat(2,wordsAll{iWord},...
            zeros(1,round((prestim+jitter*rand())*audioNoise(1).Fs)));
    end
end

noiseKey = numel(wordKey)+1;

% Devide targ into two subparts and randomize separately
% stim_1 = wordsAll(1:nRepetitionMinimum,:);
% stim_1 = stim_1(:);
% stim_1 = cat(1,stim_1,cat(1,noise(1:nRepetitionMinimum*nUniqueWords)));
% stimKey_1 = wordKeysAll(1:nRepetitionMinimum,:);
% stimKey_1 = stimKey_1(:);
% stimKey_1 = cat(1,stimKey_1,cat(1,noiseKey*ones(nRepetitionMinimum*nUniqueWords,1)));
% randVector = randperm(size(stim_1,1));
% stim_1 = stim_1(randVector);
% stimKey_1 = stimKey_1(randVector);
% 
% stim_2 = wordsAll(nRepetitionMinimum+1:end,:);
% stim_2 = stim_2(:);
% stim_2 = cat(1,stim_2,cat(1,noise(nRepetitionMinimum*nUniqueWords+1:end)));
% stimKey_2 = wordKeysAll(nRepetitionMinimum+1:end,:);
% stimKey_2 = stimKey_2(:);
% stimKey_2 = cat(1,stimKey_2,...
%                 cat(1,noiseKey*ones(nNoiseStimuli-nRepetitionMinimum*nUniqueWords,1)));
% randVector = randperm(size(stim_2,1));
% stim_2 = stim_2(randVector);
% stimKey_2 = stimKey_2(randVector);
% % Removing instances of target word if necessary
% if S.nTargets < S.nRepetitionPerWord
%     nToRemove = S.nRepetitionPerWord-S.nTargets;
%     idx = find(ismember(stimKey_2,S.targetKey));
%     stim_2(idx(1:nToRemove)) = [];
%     stimKey_2(idx(1:nToRemove)) = [];
% end

stim = cat(1,wordsAll,noise);
stimKey = cat(1,wordKeysAll,noiseKey*ones(size(noise)));
randVector = pseudorandomize_stimuli(stimKey);
stim = stim(randVector);
stimKey = stimKey(randVector);
stimDuration = cellfun(@(x) numel(x)/audioNoise(1).Fs,stim);
stim = cat(2,stim{:});
% Normalize stimulus between +/-1
stim = stim./max(abs(stim));

end