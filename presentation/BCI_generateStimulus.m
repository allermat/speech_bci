function [stim,stimKey,stimDuration] = BCI_generateStimulus(S)

p = inputParser;

fieldsReqS = {'audioNoise','audioWords','wordsLoaded','jitter','prestim','nCh',...
              'nNoiseStimuli','nTargets','nRepetitionNonTarget',...
              'noiseLpCutoff','targetKey','wordKey',...
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
nRepetitionNonTarget = S.nRepetitionNonTarget;
wordKey = S.wordKey;
uniqueWords = unique(wordsLoaded);
randSelect = S.randSelect;
noiseLpCutoff = S.noiseLpCutoff;

% Applying STRAIGHT only once for each token
if strcmp(vocodeMethod,'STRAIGHT')
%     if ~randSelect
%         noise_straight = BCI_generateNoiseStraight(audioNoise, ...
%                     'lpCutoff',noiseLpCutoff);
%     end
%     words_straight = cell(size(audioWords));
%     for i = 1:numel(words_straight)
%         words_straight{i} = applyStraight(audioWords(i));
%     end
    noise_straight = S.noise_straight;
    words_straight = S.words_straight;
    % noiseKey
    if ~iscell(noise_straight)
        noiseKey = numel(wordKey)+1;
        noiseKeysAll = noiseKey*ones(nNoiseStimuli,1);
    else
        noiseKey = numel(wordKey)+(1:numel(noise_straight));
        noiseKeysAll = NaN(nNoiseStimuli,1);
    end
elseif strcmp(vocodeMethod,'VOCODER')
    noiseKey = numel(wordKey)+1;
    noiseKeysAll = noiseKey*ones(nNoiseStimuli,1);
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
                if ~iscell(noise_straight)
                    % In this case there's only one noise stimulus
                    noise{i} = noise_straight;
                else
                    % In this case there are multiple noise varieties, make
                    % sure to use them equal times
                    idx = mod(i,numel(noise_straight))+1;
                    noise{i} = noise_straight{idx};
                    noiseKeysAll(i) = noiseKey(idx);
                end
        end
    end
    % Add jitter if necessary
    if jitter > 0
        noise{i} = cat(2,noise{i},zeros(1,round((prestim+jitter*rand())*audioNoise(1).Fs)));
    end
end

% Vocode words
wordKeysAll = repmat(S.targetKey,S.nTargets,1);
wordKeyTmp = wordKey(~ismember(wordKey,S.targetKey));
wordKeysAll = cat(1,wordKeysAll,repmat(wordKeyTmp',nRepetitionNonTarget,1));
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

stim = cat(1,wordsAll,noise);
stimKey = cat(1,wordKeysAll,noiseKeysAll);
% randVector = pseudorandomize_stimuli(stimKey);
randVector = randperm(numel(stimKey));
stim = stim(randVector);
stimKey = stimKey(randVector);
stimDuration = cellfun(@(x) numel(x)/audioNoise(1).Fs,stim);
stim = cat(2,stim{:});
% Normalize stimulus between +/-1
stim = stim./max(abs(stim));

end