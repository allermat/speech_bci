function [stimAll,stimKeyAll,targetWordsAll,nTargetsAll] = BCI_generateAllStimuli(subjectId,varargin)

p = inputParser;

addRequired(p,'subjectId',@(x) validateattributes(x,{'numeric'}, ...
            {'scalar','integer','nonnegative'}));
addParameter(p,'nRuns',6,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','integer','nonnegative'}));
addParameter(p,'nTrialsPerRun',12,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','integer','nonnegative'}));
addParameter(p,'saveFile',true,@(x) validateattributes(x,{'logical'}, ...
             {'scalar'}));
parse(p,subjectId,varargin{:});

subjectId = p.Results.subjectId;
nRuns = p.Results.nRuns;
nTrialsPerRun = p.Results.nTrialsPerRun;
saveFile = p.Results.saveFile;

% Getting file names
inputDir = BCI_setupdir('stimuli');
wordFreq = '1.6Hz';
switch wordFreq
    case '2Hz'
        filesForNoise = {'yes_yes-maybe_2Hz.wav'
                         'yes_yes-thirsty_2Hz.wav'
                         'no_no-maybe_2Hz.wav'
                         'no_no-thirsty_2Hz.wav'
                         'maybe_maybe-thirsty_2Hz.wav'
                         'maybe_yes-maybe_2Hz.wav'};
    case '1.6Hz'
        filesForNoise = {'yes_yes-maybe.wav'
                         'yes_yes-thirsty.wav'
                         'no_no-maybe.wav'
                         'no_no-thirsty.wav'
                         'maybe_maybe-thirsty.wav'
                         'maybe_yes-maybe.wav'};
    otherwise
        error('Unrecognized word frequency');
end

% First read the words from disk and perform the vocoding on the already
% loaded data, it is more economical this way.
[y,Fs] = cellfun(@audioread,fullfile(inputDir,filesForNoise'),...
                 'UniformOutput',false);
audioLoaded = cell2struct(cat(1,y,Fs),{'y','Fs'},1);

% Making sure all files are the same length. Sometimes they differ by 1
% sample. 
minLength = min(cellfun(@length,{audioLoaded.y}));
for i = 1:size(audioLoaded,1)
    audioLoaded(i).y = audioLoaded(i).y(1:minLength);
end

% match RMS of input files
for f=1:size(audioLoaded,1)
   audioLoaded(f).y = audioLoaded(f).y .* 1./rms(audioLoaded(f).y);
   %rms(audio2vocode(f).y)
end
wordsLoaded = regexp(filesForNoise,'(\w)*_.*','tokens','once');
wordsLoaded = [wordsLoaded{:}];
uniqueWords = unique(wordsLoaded);
nUniqueWords = numel(uniqueWords);
% To match the keys of the previous pilot yes-1, no-2, maybe-3
wordKey = [3,2,1];
S.audioLoaded = audioLoaded;
S.wordsLoaded = wordsLoaded;
S.nCh = 16; % number of channels for vocoding
S.nRepetitionPerWord = 12; % number of repetitions per words
S.nNoiseStimuli = S.nRepetitionPerWord*nUniqueWords; % number of noise stimuli per trial
S.nRepetitionMinimum = 10;
S.wordKey = wordKey;

% Defining target words and how many times they are presented
targetWords = uniqueWords;
if nTrialsPerRun == 1
    % This option is only relevant for devMode
    targetWordsAll = targetWords(randi(3));
    nTargetsAll = 12;
elseif mod(nTrialsPerRun/nUniqueWords,1) ~= 0
    error(['The number of trials per run must be a multiple of the number ',...
           'of target words']);
else
    % Target words
    targetWordsAll = repmat(targetWords,nTrialsPerRun/nUniqueWords,1);
    targetWordsAll = repmat(targetWordsAll(:)',nRuns,1);
    % Number of target words. This makes sure that across the whole
    % experiment each target word will be presented the same amount of 
    % times. 
    nTargetsAll = repmat([10,11,12;12,10,11;11,12,10],1,nTrialsPerRun/3);
    nTargetsAll = repmat(nTargetsAll,nRuns/3,1);
    for i = 1:nRuns
        randVec = randperm(nTrialsPerRun);
        targetWordsAll(i,:) = targetWordsAll(i,randVec);
        nTargetsAll(i,:) = nTargetsAll(i,randVec);
    end
end

% Double check if each target word is persented equal times
check = cellfun(@(x) sum(nTargetsAll(ismember(targetWordsAll,x))),unique(targetWordsAll));
if numel(unique(check)) > 1
    error(['Number of presentations per target word is not equal acros', ...
           ' the experiment']);
end

% Generating stimului
[stimAll,stimKeyAll] = deal(cell(nRuns,nTrialsPerRun));
for i = 1:nRuns
    for j = 1:nTrialsPerRun
        S.targetKey = wordKey(ismember(targetWords,targetWordsAll(i,j)));
        S.nTargets = nTargetsAll(i,j);
        [stimAll{i,j},stimKeyAll{i,j}] = BCI_generateStimulus(S);
    end
end

% Full path to the file containing the stimuli
if saveFile
    filePath = fullfile(BCI_setupdir('data_behav_sub',subjectId),'stim.mat');
    if exist(filePath,'file')
        delete(filePath);
    end
    save(filePath,'stimAll','stimKeyAll','targetWordsAll','nTargetsAll');
end

end