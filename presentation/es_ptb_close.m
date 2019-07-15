% Clear the screen
clear Screen;

% Go back to normal priority
Priority(0);

% Makes it so characters typed do show up in the command window
ListenChar(0);

% Shows the cursor
ShowCursor();

% Close the audio device
PsychPortAudio('Close');



