function [stimAll,stimKeyAll,stimDurAll,targetWordsAll,nTargetsAll] = BCI_generateAllStimuli(subjectId,varargin)

validNoiseWordSelection = {'target','rand10','rand50','rand100'};
validStimulusTypes = {'pcentred_matt_2hz','pcentred_matt',...
                      'pcentred_benedikt','non-pcentred_pilot_2_1',...
                      'non-pcentred_pilot_2_2'};
validVocodeMethods = {'VOCODER','STRAIGHT'};

p = inputParser;

addRequired(p,'subjectId',@(x) validateattributes(x,{'char'},{'nonempty'}));
addParameter(p,'nRuns',6,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','integer','nonnegative'}));
addParameter(p,'nTrialsPerRun',12,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','integer','nonnegative'}));
addParameter(p,'stimulusType','non-pcentred_pilot_2_2',@(x) ismember(x,validStimulusTypes));
addParameter(p,'jitter',0.2,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','nonnegative'}));
addParameter(p,'prestim',0.1,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','nonnegative'}));
addParameter(p,'noiseWordSelection','target',@(x) ismember(x,validNoiseWordSelection));
addParameter(p,'noiseLpCutoff',30,@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','integer','nonnegative'}));
addParameter(p,'randSeed',[],@(x) validateattributes(x,{'numeric'}, ...
             {'scalar','integer','positive'}));
addParameter(p,'vocodeMethod','STRAIGHT',@(x) ismember(x,validVocodeMethods));
addParameter(p,'saveFile',true,@(x) validateattributes(x,{'logical'}, ...
             {'scalar'}));
addParameter(p,'fileName','stim',@(x) validateattributes(x,{'char'},{'nonempty'}));

parse(p,subjectId,varargin{:});

subjectId = p.Results.subjectId;
nRuns = p.Results.nRuns;
nTrialsPerRun = p.Results.nTrialsPerRun;
stimulusType = p.Results.stimulusType;
jitter = p.Results.jitter;
prestim = p.Results.prestim;
noiseWordSelection = p.Results.noiseWordSelection;
noiseLpCutoff = p.Results.noiseLpCutoff;
randSeed = p.Results.randSeed;
vocodeMethod = p.Results.vocodeMethod;
saveFile = p.Results.saveFile;
fileName = p.Results.fileName;

if ismember('randSeed',p.UsingDefaults)
    rng('shuffle');
else
    rng(randSeed);
end

% Getting file names
switch stimulusType
    case 'pcentred_matt_2hz'
        inputDir = fullfile(BCI_setupdir('stimuli'),stimulusType);
        filesNoise = dir(fullfile(inputDir,'*_2Hz.wav'));
        filesNoise = {filesNoise.name}';
        filesWords = {'yes_yes-maybe_2Hz.wav'
                      'yes_yes-thirsty_2Hz.wav'
                      'no_no-maybe_2Hz.wav'
                      'no_no-thirsty_2Hz.wav'
                      'maybe_maybe-thirsty_2Hz.wav'
                      'maybe_yes-maybe_2Hz.wav'};
        % Removing 'thirsty' from the set of words
        filesNoise = filesNoise(~cellfun(@isempty,...
            regexp(filesNoise,'^(yes|no|maybe).*\.wav')));
        wordsLoaded = regexp(filesWords,'(\w)*_.*','tokens','once');
        wordsLoaded = [wordsLoaded{:}];
        uniqueWords = unique(wordsLoaded);
        nUniqueWords = numel(uniqueWords);
        % To match the keys of the previous pilot yes-1, no-2, maybe-3
        wordKey = [3,2,1];
        nRepetitionPerWord = 12; % number of repetitions per words
        nNoiseStimuli = nRepetitionPerWord*nUniqueWords; % number of noise stimuli per trial
        nRepetitionMinimum = 10;
    case 'pcentred_matt'
        inputDir = fullfile(BCI_setupdir('stimuli'),stimulusType);
        filesNoise = dir(inputDir);
        filesNoise = {filesNoise.name}';
        filesNoise = filesNoise(~cellfun(@isempty,... 
            regexp(filesNoise,'[a-zA-Z]*_[a-zA-Z]*-[a-zA-Z]*.wav')));
        filesWords = {'yes_yes-maybe.wav'
                      'yes_yes-thirsty.wav'
                      'no_no-maybe.wav'
                      'no_no-thirsty.wav'
                      'maybe_maybe-thirsty.wav'
                      'maybe_yes-maybe.wav'};
        % Removing 'thirsty' from the set of words
        filesNoise = filesNoise(~cellfun(@isempty,...
            regexp(filesNoise,'^(yes|no|maybe).*\.wav')));
        wordsLoaded = regexp(filesWords,'(\w)*_.*','tokens','once');
        wordsLoaded = [wordsLoaded{:}];
        uniqueWords = unique(wordsLoaded);
        nUniqueWords = numel(uniqueWords);
        % To match the keys of the previous pilot yes-1, no-2, maybe-3
        wordKey = [3,2,1];
        nRepetitionPerWord = 12; % number of repetitions per words
        nNoiseStimuli = nRepetitionPerWord*nUniqueWords; % number of noise stimuli per trial
        nRepetitionMinimum = 10;
    case 'pcentred_benedikt'
        inputDir = fullfile(BCI_setupdir('stimuli'),stimulusType);
        filesWords = {'bread.wav'
                      'else.wav'
                      'fine.wav'
                      'like.wav'
                      'pair.wav'
                      'thin.wav'};
        switch noiseWordSelection
            case {'rand10','rand50','rand100'}
                filesNoise = dir(fullfile(inputDir,'*.wav'));
                filesNoise = {filesNoise.name}';
                idx = randperm(numel(filesNoise));
                n = regexp(noiseWordSelection,'[a-z]*([0-9]*)','tokens','once');
                n = str2double(n{:});
                filesNoise = filesNoise(idx(1:n));
            case 'target'
                filesNoise = filesWords;
        end
        wordsLoaded = regexp(filesWords,'(\w)*.wav','tokens','once');
        wordsLoaded = [wordsLoaded{:}]';
        uniqueWords = unique(wordsLoaded);
        nUniqueWords = numel(uniqueWords);
        wordKey = 1:nUniqueWords;
        nRepetitionPerWord = 8; % number of repetitions per words
        nNoiseStimuli = 16; % number of noise stimuli per trial
        nRepetitionMinimum = 8;
    case 'non-pcentred_pilot_2_1'
        inputDir = fullfile(BCI_setupdir('stimuli'),'non-pcentred_pilot_2','uniform');
        filesWords = {'yes.wav'
                      'no.wav'
                      'help.wav'
                      'pain.wav'
                      'left.wav'
                      'right.wav'};
        switch noiseWordSelection
            case {'rand10','rand50','rand100'}
                error('This option is not implemented! ');
            case 'target'
                filesNoise = filesWords;
        end
        wordsLoaded = regexp(filesWords,'(\w)*.wav','tokens','once');
        wordsLoaded = [wordsLoaded{:}]';
        uniqueWords = unique(wordsLoaded);
        nUniqueWords = numel(uniqueWords);
        wordKey = 1:nUniqueWords;
        nRepetitionPerWord = 8; % number of repetitions per words
        nNoiseStimuli = 16; % number of noise stimuli per trial
        nRepetitionMinimum = 8;
    case 'non-pcentred_pilot_2_2'
        inputDir = fullfile(BCI_setupdir('stimuli'),'non-pcentred_pilot_2','uniform');
        filesWords = {'yes.wav'
                      'no.wav'
                      'help.wav'
                      'pain.wav'
                      'hot.wav'
                      'cold.wav'};
        switch noiseWordSelection
            case {'rand10','rand50','rand100'}
                error('This option is not implemented! ');
            case 'target'
                filesNoise = filesWords;
        end
        wordsLoaded = regexp(filesWords,'(\w)*.wav','tokens','once');
        wordsLoaded = [wordsLoaded{:}]';
        uniqueWords = unique(wordsLoaded);
        nUniqueWords = numel(uniqueWords);
        wordKey = 1:nUniqueWords;
        nRepetitionPerWord = 8; % number of repetitions per words
        nNoiseStimuli = 16; % number of noise stimuli per trial
        nRepetitionMinimum = 8;
    otherwise
        error('Unrecognized word stimulus type');
end

% First read the words from disk and perform the vocoding on the already
% loaded data, it is more economical this way.
% NOISE words
[y,fs] = cellfun(@audioread,fullfile(inputDir,filesNoise'),...
                 'UniformOutput',false);
audioNoise = cell2struct(cat(1,y,fs),{'y','Fs'},1);

% WORDS
[y,fs] = cellfun(@audioread,fullfile(inputDir,filesWords'),...
                 'UniformOutput',false);
audioWords = cell2struct(cat(1,y,fs),{'y','Fs'},1);

if regexp(stimulusType,'^pcentred','once')
    % Making sure all files are the same length. Sometimes they differ by 1
    % sample.
    minLength = min(cellfun(@length,{audioNoise.y}));
    for i = 1:size(audioNoise,1)
        audioNoise(i).y = audioNoise(i).y(1:minLength);
    end
    
    
    % Making sure all files are the same length. Sometimes they differ by 1
    % sample.
    minLength = min(cellfun(@length,{audioWords.y}));
    for i = 1:size(audioWords,1)
        audioWords(i).y = audioWords(i).y(1:minLength);
    end
    
else
%     % Padding files to the same length
%     padTo = 0.63; % Pad to this length in s
%     for i = 1:size(audioNoise,1)
%         audioNoise(i).y = cat(1,audioNoise(i).y,...
%             zeros(round(padTo*audioNoise(i).Fs)-size(audioNoise(i).y,1),1));
%     end
%     
%     for i = 1:size(audioWords,1)
%         audioWords(i).y = cat(1,audioWords(i).y,...
%             zeros(round(padTo*audioWords(i).Fs)-size(audioWords(i).y,1),1));
%     end
end

% Making sure that the length of all files in milliseconds is a whole
% number (STRAIGHT seems to crash if this is not the case)
for i = 1:size(audioNoise,1)
    endIdx = find(mod((1:numel(audioNoise(i).y))/audioNoise(i).Fs*1000,1) == 0,...
        1,'last');
    audioNoise(i).y(endIdx+1:end) = [];
end

% Making sure that the length of all files in milliseconds is a whole
% number (STRAIGHT seems to crash if this is not the case)
for i = 1:size(audioWords,1)
    endIdx = find(mod((1:numel(audioWords(i).y))/audioWords(i).Fs*1000,1) == 0,...
        1,'last');
    audioWords(i).y(endIdx+1:end) = [];
end

% match RMS of input files
for f=1:size(audioNoise,1)
    audioNoise(f).y = audioNoise(f).y .* 1./rms(audioNoise(f).y);
end

% match RMS of input files
for f=1:size(audioWords,1)
    audioWords(f).y = audioWords(f).y .* 1./rms(audioWords(f).y);
end

S.audioWords = audioWords;
switch noiseWordSelection
    case {'rand10','rand50','rand100'}
        S.audioNoise = audioNoise;
        S.randSelect = false;
    case 'target'
        S.audioNoise = S.audioWords;
        S.randSelect = false;
end

% Applying STRAIGHT only once for each token and noise
if strcmp(vocodeMethod,'STRAIGHT')
    if ~S.randSelect
        % First noise is the standard summed, second is the word shaped
        [noise_straight{1},noise_straight{2}] = ...
            BCI_generateNoiseStraight(audioNoise,'lpCutoff',noiseLpCutoff);
    end
    words_straight = cell(size(audioWords));
    for i = 1:numel(words_straight)
        words_straight{i} = applyStraight(audioWords(i));
    end
    S.noise_straight = noise_straight;
    S.words_straight = words_straight;
end
S.fs = fs;
S.wordsLoaded = wordsLoaded;
S.jitter = jitter;
S.prestim = prestim;
S.nCh = 16; % number of channels for vocoding
S.nRepetitionPerWord = nRepetitionPerWord; % number of repetitions per words
S.nNoiseStimuli = nNoiseStimuli; % number of noise stimuli per trial
S.nRepetitionMinimum = nRepetitionMinimum;
S.wordKey = wordKey;
S.vocodeMethod = vocodeMethod;
S.noiseLpCutoff = noiseLpCutoff; % LP filter cutoff frequency (Hz) for noise vocoding

% Defining target words and how many times they are presented
targetWords = uniqueWords;
if nTrialsPerRun == 1
    % This option is only relevant for devMode
    targetWordsAll = targetWords(randperm(nUniqueWords));
    nTargetsAll = repmat(nRepetitionPerWord,nUniqueWords,1);
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
    temp = [];
    for i = 1:(nTrialsPerRun*nRuns/3)
        temp = cat(1,temp,circshift([8,9,10]',i-1));
    end
    nTargetsAll = reshape(temp,nTrialsPerRun,[])';
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
[stimAll,stimKeyAll,stimDurAll] = deal(cell(nRuns,nTrialsPerRun));
for i = 1:nRuns
    for j = 1:nTrialsPerRun
        S.targetKey = wordKey(ismember(targetWords,targetWordsAll(i,j)));
        S.nTargets = nTargetsAll(i,j);
        [stimAll{i,j},stimKeyAll{i,j},stimDurAll{i,j}] = BCI_generateStimulus(S);
    end
end

% Full path to the file containing the stimuli
if saveFile
    if isempty(strfind(fileName,'.mat')) %#ok<STREMP>
        fileName = strcat(fileName,'.mat');
    end
    filePath = fullfile(BCI_setupdir('data_behav_sub',subjectId),fileName);
    if exist(filePath,'file')
        delete(filePath);
    end
    save(filePath,'stimAll','stimKeyAll','stimDurAll','targetWordsAll','nTargetsAll');
end

end