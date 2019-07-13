function [stim,stimKey] = BCI_generateStimulus(S)

p = inputParser;

fieldsReqS = {'audioLoaded','isSelectedWord','nCh','nNoiseStimuli', ...
              'nRepetitionPerWord','nTargets','nWordsSelected',...
              'targetKey','nRepetitionMinimum'};

checkS = @(x) all(isfield(x,fieldsReqS));

addRequired(p,'S',checkS);

parse(p,S);

S = p.Results.S;

% unpacking input into variables
audioLoaded = S.audioLoaded;
nCh = S.nCh;
nNoiseStimuli = S.nNoiseStimuli;
nRepetitionPerWord = S.nRepetitionPerWord;
nRepetitionMinimum = S.nRepetitionMinimum;
isSelectedWord = S.isSelectedWord;
nWordsSelected = S.nWordsSelected;

% Generate noise using all words
noise = cell(nNoiseStimuli,1);
for i = 1:nNoiseStimuli
    noise{i} = BCI_generateVocodedNoise(audioLoaded,nCh);
end

% Vocode words
words = cell(nRepetitionPerWord,nWordsSelected);
wordKeys = NaN(nRepetitionPerWord,nWordsSelected);
for iRep = 1:nRepetitionPerWord
    for iWord = 1:size(isSelectedWord,1)
        [~,~,~,words{iRep,iWord}] = vocode_ma('noise','n','greenwood','half', ...
            30,nCh,audioLoaded(isSelectedWord(iWord,:)),'');
        wordKeys(iRep,iWord) = iWord;
    end
end
noiseKey = nWordsSelected+1;
% Devide targ into two subparts and randomize separately
stim_1 = words(1:nRepetitionMinimum,:);
stim_1 = stim_1(:);
stim_1 = cat(1,stim_1,cat(1,noise(1:nRepetitionMinimum*nWordsSelected)));
stimKey_1 = wordKeys(1:nRepetitionMinimum,:);
stimKey_1 = stimKey_1(:);
stimKey_1 = cat(1,stimKey_1,cat(1,noiseKey*ones(nRepetitionMinimum*nWordsSelected,1)));
randVector = randperm(size(stim_1,1));
stim_1 = stim_1(randVector);
stimKey_1 = stimKey_1(randVector);

stim_2 = words(nRepetitionMinimum+1:end,:);
stim_2 = stim_2(:);
stim_2 = cat(1,stim_2,cat(1,noise(nRepetitionMinimum*nWordsSelected+1:end)));
stimKey_2 = wordKeys(nRepetitionMinimum+1:end,:);
stimKey_2 = stimKey_2(:);
stimKey_2 = cat(1,stimKey_2,...
                cat(1,noiseKey*ones(nNoiseStimuli-nRepetitionMinimum*nWordsSelected,1)));
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