%% Clear the workspace
clearvars;
close all;
sca;

%% Initialise random number generator
rng('shuffle');

%% Note when script started
tExpStart = tic;

%% Get subject and run numbers
prompt = {'Subject:','Run:','Practice mode:'};
title = 'Input';
lines = [1 35]; % 1 row, 35 chars in each line
defaults = {'','','0'};
params = inputdlg(prompt,title,lines,defaults);
if ~isempty(params) % ok is pressed
    params = cellfun(@str2num,params,'UniformOutput',false);
    [subjectId,iRun,practiceMode] = params{:};
else % cancel is pressed
    fprintf('Run has been aborted...\n')
    return;
end

%% Loading setup specific information
setupID = getenv('computername');

temp = load('setup_spec.mat');
setupIDlist = {temp.setup_spec.ID};
idx = find(strcmp(setupID,setupIDlist));
if ~isempty(idx)
    setupSpec = temp.setup_spec(idx);
else
    error('Could not find setup specific information! ');
end

%% Parameters
% Synchrony measurement mode
syncMode = false;
if syncMode
    warning('Experiment runs in sync mode! '); %#ok
end

% Developing mode
devMode = true;
if devMode
    warning('Experiment runs in development mode! '); %#ok
end

% Debugging mode
debugMode = 0;
 
% Add a practice mode with 1 run only but in the scanner
if devMode || practiceMode
    nRuns = 1;
    nTrialsPerRun = 1;
else
    nRuns = 6;
    nTrialsPerRun = 12;
end
fs = 44100;
nrchannels = 2;
wordFreq = 1.6; % Frequency of words in stimulus in Hz

%% setting up experiment environment
% always needs to be put if using KbName!!!!!
KbName('UnifyKeyNames');

% to exit the program
quit = KbName('ESCAPE');

%% Preload sound files into matlab workspace

% Full path to the file containing the stimuli
filePath = fullfile(BCI_setupdir('data_behav_sub',subjectId),'stim.mat');

if ~syncMode
    if devMode || practiceMode
        [stimAll,stimKeyAll,targetWordsAll,nTargetsAll] = ...
            BCI_generateAllStimuli(subjectId,'nRuns',nRuns,'nTrialsPerRun', ...
                                   nTrialsPerRun,'saveFile',false);
    else
        load(filePath,'stimAll','stimKeyAll','targetWordsAll','nTargetsAll');
    end
else
    % Generate 50 ms Gaussian white noise bursts followed by 450 ms silence
    noiseDuration = 0.05;
    noise = cat(1,randn(round(fs*noiseDuration),72),...
                zeros(round(fs*(1/wordFreq-noiseDuration)),72));
    stimAll = {noise(:)'};
    stimKeyAll = {ones(1,72)};
    targetWordsAll = {'yes'};
    nTargetsAll = 12;
end



%% Setting up variables
[tStartSound,tEndSound,responses] = deal(NaN(nTrialsPerRun,1));
correctResponses = nTargetsAll(iRun,:);
abort = false; % flag for aborting the run

try
    %% Initialise a MEGSynchClass session
    if devMode
        MEG = MEGSynchClass(1); % If testing outside MEG scanner
    else
        MEG = MEGSynchClass; % If testing inside MEG scanner
    end
    MEG.Keys = {'z','x','c'}; % emulation Buttons
    whichButton = [3,4,5]; % which response button in MEG scanner to listen for
    
    %% Prepare screen, inputs and sound
    es_ptb_prepare;
    
    %% Ask participant if ready to start
    DrawFormattedText(window, 'Press button when ready...', 'center', 'center', black);
    Screen('Flip', window);
    MEG.WaitForButtonPress();
    DrawFormattedText(window, '+', 'center', 'center', black);
    Screen('Flip', window);
    WaitSecs(1);
    
    %% Reset triggers
    MEG.SendTrigger(0);
    
    %% Trial loop here
    for iTrial = 1:nTrialsPerRun
        
        % Check for quitting
        [~,~,keyCode] = KbCheck;
        if keyCode(quit)
            break;
        end
        % Select sound for current trial and extract stim info from sound filename
        targetWordCurrent = targetWordsAll{iRun,iTrial};
        audioCurrent = repmat(stimAll{iRun,iTrial},2,1);
        stimTriggerCurrent = stimKeyAll{iRun,iTrial};
        
        
        % Display target word
        if ~syncMode
            DrawFormattedText(window, targetWordCurrent, 'center', 'center', black);
        else
            DrawFormattedText(window, '+', 'center', 'center', black);
        end
        Screen('Flip', window);
        MEG.SendTrigger(10);
        WaitSecs(0.01);
        MEG.SendTrigger(0);
        WaitSecs(3);
        DrawFormattedText(window, '+', 'center', 'center', black);
        Screen('Flip', window);
        
        % Fill the audio playback buffer with the audio data, doubled for stereo presentation
        PsychPortAudio('FillBuffer', pahandle, audioCurrent);
                
        % Start audio playback
        tStartSoundCurrent = PsychPortAudio('Start', pahandle, 1, 0, waitForDeviceStart);
        
        % MEG.ResetClock; % is this necessary?
        % Sending triggers in to indicate individual word onsets within the
        % continuous audio stimulus
        for iStim = 1:numel(stimTriggerCurrent)
            MEG.SendTrigger(stimTriggerCurrent(iStim));
            WaitSecs(0.01);
            MEG.SendTrigger(0);
            
            % Check for quitting
            [~,~,keyCode] = KbCheck;
            if keyCode(quit)
                abort = true;
                break;
            end
            WaitSecs('UntilTime', tStartSoundCurrent+((iStim)*0.625));
        end
        % Stop the sound
        [~,~,~,tEndSoundCurrent] = PsychPortAudio('Stop',pahandle);
        
        if ~abort
            % Present question
            txt = sprintf('How many targets\ndid you count?\n10(Y)   11(G)   12(B)');
            DrawFormattedText(window, txt, 'center', 'center', black);
            Screen('Flip', window);
            % Send trigger to indicate the onset of the response screen
            MEG.SendTrigger(13);
            WaitSecs(0.01);
            MEG.SendTrigger(0);
            % Wait for response here for 10 seconds, then go on
            MEG.ResetClock;
            MEG.WaitForButtonPress(10,whichButton);
            buttonPressed = MEG.LastButtonPress;
            if ~isempty(buttonPressed)
                % Reset screen
                Screen('FillRect',window,grey,windowRect);
                Screen('Flip', window);
                % Log response (we don't care about multiple presses here) the
                % responded repetition numbers are 10 for button 3, 11 for 4 and 12
                % for 5, so I just add 7 the the buttonPressed variable to get
                % the values
                switch buttonPressed{1}
                    case 'RY', respCurrent = 10;
                    case 'RG', respCurrent = 11;
                    case 'RB', respCurrent = 12;
                    otherwise, respCurrent = 0;
                end
                % Send response trigger
                MEG.SendTrigger(10+respCurrent);
                WaitSecs(0.01);
                MEG.SendTrigger(0)
            else
                respCurrent = NaN;
            end
            
            responses(iTrial) = respCurrent;
            
            % Send trigger to indicate the end of the trial
            WaitSecs(0.2);
            MEG.SendTrigger(11);
            WaitSecs(0.01);
            MEG.SendTrigger(0);
            
            % Display progress to experimenter
            fprintf('\nRun %d, trial %d...\n',iRun,iTrial);
        else
            % Display progress to experimenter
            fprintf('\nRun %d, trial %d...Aborted!\n',iRun,iTrial);
            break;
        end
        tStartSound(iTrial) = tStartSoundCurrent;
        tEndSound(iTrial) = tEndSoundCurrent;
        
    end % End trial loop
    
    %% Collect data
    dataVarNames = {'Subject','Run','Trial','Sound_onset','Sound_offset', ...
                    'Target_word','Response','Correct_response'};
    data = table(repmat(subjectId,nTrialsPerRun,1),repmat(iRun,nTrialsPerRun,1),...
                 (1:nTrialsPerRun)',tStartSound,tEndSound,... 
                 targetWordsAll(iRun,:),responses,correctResponses,...
                 'VariableNames',dataVarNames);
    
    %% Compute performance
    score = ((responses == correctResponses)/numel(correctResponses))*100;
    
    %% Exit message for subject
    DrawFormattedText(window, sprintf('You got %d%% correct',score), 'center', 'center', black);
    Screen('Flip', window);
    WaitSecs(3);
    
    %% Shut down and save data
    es_ptb_close;
    
    %% Show experimenter some peformance feedback
    fprintf('\nTrials completed = %d\n',trial);
    fprintf('\nScore = %d%\n',score);
    
    %% Note when script finished
    tExpDur = toc(tExpStart)/60;
    fprintf('\nTime taken = %f minutes\n',tExpDur);
catch e %e is an MException struct
    
    es_ptb_close;
    rethrow(e);
    
end