% Clear the screen
clear Screen;

% Go back to normal priority
Priority(0);

% Makes it so characters typed do show up in the command window
ListenChar(0);

% Shows the cursor
ShowCursor();

% Close the audio device
PsychPortAudio('Close', pahandle);

% % Save data
% [dateNow,timeNow] = strtok(datestr(clock));
% timeNow = strrep(timeNow(2:end),':','');
% fileID = fopen(sprintf('subj%d_run%d_%s_%s.txt',subject,run,dateNow,timeNow),'w');
% fopen(fileID);
% [nrows,ncols] = size(data);
% formatSpec = repmat('%s\t',[1 ncols]);
% fprintf(fileID,[formatSpec '\n'],data{1,:}); % Save headers
% formatSpec = [];
% for col = 1:ncols
%     if isnumeric(data{2,col})
%         formatSpec = [formatSpec '%f\t'];
%     else
%         formatSpec = [formatSpec '%s\t'];
%     end
% end
% for row = 2:nrows
%     fprintf(fileID,[formatSpec '\n'],data{row,:}); % Save data
% end
% fclose(fileID);