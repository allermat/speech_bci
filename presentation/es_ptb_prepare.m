%% For screen

% Here we call some default settings for setting up Psychtoolbox
PsychDefaultSetup(2);

% Get the screen numbers
screens = Screen('Screens');
if devMode
    Screen('Preference', 'SkipSyncTests', 1);
end
% Makes it so characters typed don't show up in the command window
ListenChar(2);

% Hides the cursor
HideCursor();

% Select the external screen if it is present, else revert to the native
% screen
screenNumber = max(screens);

% Define black, white and grey
black = BlackIndex(screenNumber);
white = WhiteIndex(screenNumber);
grey = white / 2;

% Open an on screen window and color it grey
if debugMode; PsychDebugWindowConfiguration(0,0.5); end
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Set the maximum priority number
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Get the size of the on screen window in pixels
% For help see: Screen WindowSize?
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window in pixels
% For help see: help RectCenter
[xCenter, yCenter] = RectCenter(windowRect);

% Define text size and font
Screen('TextSize', window, 80);
Screen('TextFont', window, 'Courier');

%% For sound

% Initialize Sounddriver
InitializePsychSound(1);

% Should we wait for the device to really start (1 = yes)
% INFO: See help PsychPortAudio
waitForDeviceStart = 1;

% Open Psych-Audio port, with the follow arguements
% (1) [] = default sound device
% (2) 1 = sound playback only
% (3) 1 = default level of latency
% (4) Requested frequency in samples per second
% (5) 2 = stereo putput
pahandle = PsychPortAudio('Open', [], 1, 1, fs, nrchannels);

% Generate some beep sound 1000 Hz, 0.1 secs, 50% amplitude and fill it
% in the buffer for preheting playback.
mynoise = 0.5 * MakeBeep(1000,0.1,fs);
mynoise = repmat(mynoise,nrchannels,1);
PsychPortAudio('FillBuffer',pahandle,mynoise);
% Preheat: run  audio device once silently, with volume set to zero.
PsychPortAudio('Volume',pahandle,0);
PsychPortAudio('Start',pahandle,1,0);
PsychPortAudio('Stop',pahandle,1);

PsychPortAudio('Volume',pahandle,1);

% Set the volume to half
%PsychPortAudio('Volume', pahandle, 0.5);