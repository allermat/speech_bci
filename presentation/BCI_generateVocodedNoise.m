function noiseSummed = BCI_generateVocodedNoise(audio2vocode,nCh,varargin)

p = inputParser;

addRequired(p,'audio2vocode',@(x) isstruct(x) && isfield(x,'y') && isfield(x,'Fs'));
addRequired(p,'nCh',@(x) validateattributes(x,{'numeric'},{'scalar','integer'}));
addParameter(p,'lpCutoff',30,@(x) validateattributes(x,{'numeric'},{'scalar'}));
addParameter(p,'saveFile',false,@(x) validateattributes(x,{'logical'},{'scalar'}));


parse(p,audio2vocode,nCh,varargin{:});

audio2vocode = p.Results.audio2vocode;
nCh = p.Results.nCh;
lpCutoff = p.Results.lpCutoff;
saveFile = p.Results.saveFile;

env_all = [];
for f=1:size(audio2vocode,1)
    [~,envelopes,~,~,levels] = vocode_ma('noise', 'n', 'greenwood', ...
        'half', lpCutoff, nCh, audio2vocode(f), '');
%     for i=1:nCh
%         envelopes(i,:) = envelopes(i,:)*levels(i)/norm(envelopes(i,:),2);
%     end
    env_all(:,:,f) = envelopes;
    levels_all(:,f) = levels;
end

nSmp = size(env_all,2);

env_mean = mean(env_all,3);
levels_mean = mean(levels_all,2);

[filterA,filterB]=estfilt(nCh,'greenwood',44100,0);

noise_all = [];
for i=1:nCh
   noise = sign(rand(1,nSmp)-0.5);
   noise = filter(filterB(i,:),filterA(i,:),noise);
   noise = noise .* env_mean(i,:);
   noise = noise*levels_mean(i)/norm(noise,2);
   noise_all(i,:) = noise;
end

noiseSummed = sum(noise_all,1);

% if saveFile
%     audfiowrite(sprintf('%d_ch_noise.wav',nCh),noiseSummed,44100);
% end

end