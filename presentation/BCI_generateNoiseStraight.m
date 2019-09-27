function noiseSummed = BCI_generateNoiseStraight(audioIn,nCh,varargin)

p = inputParser;

addRequired(p,'audioIn',@(x) isstruct(x) && isfield(x,'y') && isfield(x,'Fs'));
addParameter(p,'lpCutoff',30,@(x) validateattributes(x,{'numeric'},{'scalar'}));
addParameter(p,'saveFile',false,@(x) validateattributes(x,{'logical'},{'scalar'}));

parse(p,audioIn,nCh,varargin{:});

audioIn = p.Results.audioIn;
lpCutoff = p.Results.lpCutoff;
saveFile = p.Results.saveFile;

% smoothing the spectrogram
mavgwin = round(1/lpCutoff*1000);       % 20ms with 1ms time-steps
% Kernel for smoothing trials with the given time wintow
kern = ones(1,mavgwin)./mavgwin;

floor_f0 = 50;         % set f0 range for a male voice
ceiling_f0 = 150;

[track,aperiod,spectr,conv_spectr,synth_y] = deal(cell(numel(audioIn),1));
for i = 1:numel(audioIn)
    
    y = audioIn(i).y;
    fs = audioIn(i).Fs;
    
    track{i} = MulticueF0v14(y,fs,floor_f0,ceiling_f0);
    aperiod{i} = exstraightAPind(y,fs,track{i});
    spectr{i} = exstraightspec(y,track{i},fs);
    for iChan = 1:size(spectr{i},1)
        conv_spectr{i}(iChan,:) = conv(spectr{i}(iChan,:),kern,'same');
    end
    synth_y{i} = exstraightsynth(zeros(size(track{i})),...
                                 conv_spectr{i},...
                                 zeros(size(aperiod{i})),fs)/32768;
                             
    % Pad with zeros if necessary
    if numel(synth_y{i}) < numel(y)
        temp = zeros(size(y));
        temp(1:numel(synth_y{i})) = synth_y{i};
        synth_y{i} = temp;
    end
end



noiseSummed = mean(cat(3,synth_y{:}),3)';

% if saveFile
%     audfiowrite(sprintf('%d_ch_noise.wav',nCh),noiseSummed,44100);
% end

end