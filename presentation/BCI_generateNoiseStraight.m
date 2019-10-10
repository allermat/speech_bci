function [noiseSummed,noiseWordShaped] = BCI_generateNoiseStraight(audioIn,nCh,varargin)

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

% Assuming all words are sampled at the same frequency
Fs = audioIn(1).Fs;
[track,aperiod,spectr,conv_spectr,synth_y] = deal(cell(numel(audioIn),1));
for i = 1:numel(audioIn)
    
    y = audioIn(i).y;
    
    track{i} = MulticueF0v14(y,Fs,floor_f0,ceiling_f0);
    aperiod{i} = exstraightAPind(y,Fs,track{i});
    spectr{i} = exstraightspec(y,track{i},Fs);
    for iChan = 1:size(spectr{i},1)
        conv_spectr{i}(iChan,:) = conv(spectr{i}(iChan,:),kern,'same');
    end
    synth_y{i} = exstraightsynth(zeros(size(track{i})),...
                                 conv_spectr{i},...
                                 zeros(size(aperiod{i})),Fs)/32768;
                             
    % Pad with zeros if necessary
    if numel(synth_y{i}) < numel(y)
        temp = zeros(size(y));
        temp(1:numel(synth_y{i})) = synth_y{i};
        synth_y{i} = temp;
    end
    
end

% noiseSummed = sum(cat(3,synth_y{:}),3)';

noiseSummed = mean(cat(3,synth_y{:}),3)';
noiseSummed = noiseSummed./rms(noiseSummed);

if nargout > 1
    noiseWordShaped = generateWordShapedNoise(synth_y,noiseSummed,Fs,lpCutoff);
end

% if saveFile
%     audfiowrite(sprintf('%d_ch_noise.wav',nCh),noiseSummed,44100);
% end

end

function z_env = generateWordShapedNoise(y,y_summed,Fs,lpFreq)

if isrow(y_summed)
    y_summed = y_summed';
    rowOut = true;
else
    rowOut = false;
end

% Concatenate words
y = cat(1,y{:});
y = y./rms(y);

% generate fourier transform
yy = fft(y);

% make noise and generate fft
n = rand(size(y));
n = n - mean(n);
N = fft(n);

% create speech shaped noise
z = real(ifft(abs(yy).*exp(1i.*angle(N))));

% Modulate envelope in time domain with the envelope of the average of
% words
% Compute the envelope of the input file, this is based on vocode.m
[blo,alo] = butter(2,lpFreq/(Fs/2));
env = filter(blo,alo,abs(y_summed));
env = env/max(env);
% Modulate 
z_env = z(1:numel(y_summed)).*env;
z_env = z_env./rms(z_env);
if rowOut
    z_env = z_env';
end

end