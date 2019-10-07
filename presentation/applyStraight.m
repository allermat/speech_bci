function [synth_y] = applyStraight(audioIn)

floor_f0 = 50;         % set f0 range for a male voice
ceiling_f0 = 150;
y = audioIn.y;
fs = audioIn.Fs;

f0_track1 = MulticueF0v14(y,fs,floor_f0,ceiling_f0);
aperiodicity1 = exstraightAPind(y,fs,f0_track1);
spectrogram1 = exstraightspec(y,f0_track1,fs);

% resynthesise original speech
% synth_x1 = exstraightsynth(f0_track1,spectrogram1,aperiodicity1,fs)/32768; 
% sounds natural
% sound(synth_x1,fs);                                          

% resynthesise with maximum aperiodicity
synth_y = exstraightsynth(zeros(size(f0_track1)),spectrogram1,...
                                          zeros(size(aperiodicity1)),fs)/32768; 
% sounds whispered
% sound(synth_x1_noaperiodicity,fs);

% Pad with zeros if necessary
if numel(synth_y) < numel(y)
    temp = zeros(size(y));
    temp(1:numel(synth_y)) = synth_y;
    synth_y = temp;
end

synth_y = synth_y';

synth_y = synth_y./rms(synth_y);

end