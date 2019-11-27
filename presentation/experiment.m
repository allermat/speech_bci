%% Clear the workspace
clearvars;
close all;
sca;

%% Initialise random number generator
rng('shuffle');
sCurr = rng;

%% Note when script started
tExpStart = tic;

%% Get subject and run numbers
prompt = {'Subject:','Run:','Practice mode:'};
title = 'Input';
lines = [1 35]; % 1 row, 35 chars in each line
defaults = {'','','0'};
params = inputdlg(prompt,title,lines,defaults);
if ~isempty(params) % ok is pressed
    subjectId = params{1};
    params = cellfun(@str2num,params(2:end),'UniformOutput',false);
    [iRun,isPractice] = params{:};
    isPractice = logical(isPractice);
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
devMode = false;
if devMode
    warning('Experiment runs in development mode! '); %#ok
end

% Debugging mode
debugMode = 0;
 
% Sound device settings
fs = 44100;
nrchannels = 2;

%% setting up experiment environment
% always needs to be put if using KbName!!!!!
KbName('UnifyKeyNames');

% to exit the program
quitKey = KbName('ESCAPE');
aKey = KbName('a');
sKey = KbName('s');
dKey = KbName('d');

%% Preload sound files into matlab workspace
if syncMode
    % Generate 50 ms Gaussian white noise bursts followed by 450 ms silence
    nStim = 100;
    noiseDuration = 0.05;
    stimDuration = 0.5;
    noise = cat(1,randn(round(fs*noiseDuration),nStim),...
                zeros(round(fs*(stimDuration-noiseDuration)),nStim));
    stimActRun = {noise(:)'};
    stimKeyActRun = {ones(1,nStim)};
    stimDurActRun = {stimDuration*ones(1,nStim)};
    targetWordsActRun = {'yes'};
    nTargetsActRun = 12;
    
    nTrialsPerRun = 1;
else
    if isPractice
        % Full path to the file containing the stimuli
        filePath = fullfile(BCI_setupdir('data_behav_sub',subjectId),'stim_pract.mat');
    else
        filePath = fullfile(BCI_setupdir('data_behav_sub',subjectId),'stim.mat');
    end
    % Load data as a matfile object, this makes partial loading possible
    % which is faster than loading the whole file. 
    mStim = matfile(filePath);
    stimActRun = mStim.stimAll(iRun,:);
    stimKeyActRun = mStim.stimKeyAll(iRun,:);
    stimDurActRun = mStim.stimDurAll(iRun,:);
    targetWordsActRun = mStim.targetWordsAll(iRun,:);
    nTargetsActRun = mStim.nTargetsAll(iRun,:);
    nTrialsPerRun = size(stimActRun,2);
end

%% Setting up variables
[tStartSound,tEndSound,responses] = deal(NaN(nTrialsPerRun,1));
correctResponses = nTargetsActRun;
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
    if ~syncMode
        DrawFormattedText(window, 'Press button when ready...', 'center', 'center', black);
        Screen('Flip', window);
        MEG.WaitForButtonPress();
    end
    DrawFormattedText(window, '+', 'center', 'center', black);
    Screen('Flip', window);
    WaitSecs(1);
    
    %% Reset triggers
    MEG.SendTrigger(0);
    
    %% Trial loop here
    for iTrial = 1:nTrialsPerRun
        
        % Check for quitting
        [~,~,keyCode] = KbCheck;
        if keyCode(quitKey)
            break;
        end
        % Select sound for current trial and extract stim info from sound filename
        targetWordCurrent = targetWordsActRun{iTrial};
        audioCurrent = repmat(stimActRun{iTrial},2,1);
        stimTriggerCurrent = stimKeyActRun{iTrial};
        stimTriggerWaitTimeCurrent = cumsum(stimDurActRun{iTrial});
        
        % Display target word
        if ~syncMode
            DrawFormattedText(window, targetWordCurrent, 'center', 'center', black);
        else
            DrawFormattedText(window, '+', 'center', 'center', black);
        end
        respTrig = NaN;
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
            if keyCode(quitKey)
                abort = true;
                break;
            end
            WaitSecs('UntilTime',tStartSoundCurrent+stimTriggerWaitTimeCurrent(iStim));
        end
        % Stop the sound
        [~,~,~,tEndSoundCurrent] = PsychPortAudio('Stop',pahandle);
        
        if ~abort
            % Present question
            txt = sprintf('How many targets\ndid you count?\n10(Y)   12(G)   14(R)');
            DrawFormattedText(window, txt, 'center', 'center', black);
            Screen('Flip', window);
            % Send trigger to indicate the onset of the response screen
            MEG.SendTrigger(13);
            WaitSecs(0.01);
            MEG.SendTrigger(0);
            if devMode
                % Wait for response here for 10 seconds, then go on
                [~,keyCode] = KbWait([],[],GetSecs+10);
                if any(keyCode)
                    if keyCode(aKey)
                        respTrig = 20;
                        respCurrent = 10;
                    elseif keyCode(sKey)
                        respTrig = 21;
                        respCurrent = 12;
                    elseif keyCode(dKey)
                        respTrig = 22;
                        respCurrent = 14;
                    else
                        respTrig = 23;
                        respCurrent = 0;
                    end
                    if ~isnan(respTrig)
                        % Send response trigger
                        MEG.SendTrigger(respTrig);
                        WaitSecs(0.01);
                        MEG.SendTrigger(0)
                    end
                else
                    respCurrent = NaN;
                end
            else
                % Wait for response here for 10 seconds, then go on
                MEG.ResetClock;
                MEG.WaitForButtonPress(10,whichButton);
                buttonPressed = MEG.LastButtonPress;
                if ~isempty(buttonPressed)
                    
                    % Log response (we don't care about multiple presses here) the
                    % responded repetition numbers are 10 for button 3, 11 for 4 and 12
                    % for 5, so I just add 7 the the buttonPressed variable to get
                    % the values
                    switch buttonPressed{1}
                        case 'RY'
                            respTrig = 20;
                            respCurrent = 10;
                        case 'RG'
                            respTrig = 21;
                            respCurrent = 12;
                        case 'RR'
                            respTrig = 22;
                            respCurrent = 14;
                        otherwise
                            respTrig = 23;
                            respCurrent = 0;
                    end
                    if ~isnan(respTrig)
                        % Send response trigger
                        MEG.SendTrigger(respTrig);
                        WaitSecs(0.01);
                        MEG.SendTrigger(0)
                    end
                else
                    respCurrent = NaN;
                end
            end
            
            % Save response
            responses(iTrial) = respCurrent;
            
            % Reset screen
            Screen('FillRect',window,grey,windowRect);
            Screen('Flip', window);
            
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
    
    
    
    %% Compute performance
    score = (sum((responses == correctResponses'))/numel(correctResponses))*100;
    
    %% Exit message for subject
    DrawFormattedText(window, sprintf('You got %.1f%% correct',score), 'center', 'center', black);
    Screen('Flip', window);
    WaitSecs(3);
    
    %% Collect data
    dataVarNames = {'Subject','Run','Trial','Sound_onset','Sound_offset', ...
                    'Target_word','Response','Correct_response'};
    data = table(repmat({subjectId},nTrialsPerRun,1),repmat(iRun,nTrialsPerRun,1),...
                 (1:nTrialsPerRun)',tStartSound,tEndSound,... 
                 targetWordsActRun',responses,correctResponses',...
                 'VariableNames',dataVarNames);
    % Saving experiment data
    if isPractice
        savedfname = fullfile(BCI_setupdir('data_behav_sub',subjectId),...
            sprintf('behav_pract_%s_run%d_%s.mat',subjectId,...
            iRun,datestr(now,'ddmmyyyy_HHMM')));
    else
        savedfname = fullfile(BCI_setupdir('data_behav_sub',subjectId),...
            sprintf('behav_%s_run%d_%s.mat',subjectId,...
            iRun,datestr(now,'ddmmyyyy_HHMM')));
    end
    save(savedfname,'data');
    
    %% Shut down and save data
    es_ptb_close;
    
    %% Show experimenter some peformance feedback
    fprintf('\nTrials completed: %d\n',iTrial);
    fprintf('\nScore: %.1f%%\n',score);
    
    %% Note when script finished
    tExpDur = toc(tExpStart)/60;
    fprintf('\nTime taken = %.1f minutes\n',tExpDur);
catch e %e is an MException struct
    
    es_ptb_close;
    rethrow(e);
    
end