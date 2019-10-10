% read the files and play them
words = {'cold.wav','help.wav','hot.wav','no.wav','pain.wav','yes.wav'};
[y,Fs] = cellfun(@audioread,words,'UniformOutput',false);
% Average words 
y_avg = mean(cat(3,y{:}),3);
y_avg = y_avg./rms(y_avg);
% Concatenate words
y = cat(1,y{:});
y = y./rms(y);
Fs = Fs{1};

% soundsc(y,Fs)

% plot spectrogram of speech
figure(1);specgram(y,2^8,Fs)

% generate fourier transform
yy = fft(y);

% make noise and generate fft
py = rand(size(yy)); 
py = py + fliplr(py);
n = rand(size(y));
n = n - mean(n);
N = fft(n);

% create speech shaped noise
z = real(ifft(abs(yy).*exp(i.*angle(N))));

% plot spectrogram and play back
figure;specgram(z,2^8,Fs)

soundsc(z(1:numel(y_avg)),Fs)

% compute and plot frequency profiles
f = linspace(0,Fs,length(y)); 
ind = find(f>100 & f< 6e3);
Y = 20*log10(abs(fft(y)));
Z = 20*log10(abs(fft(z)));

figure;plot(f(ind),Y(ind),'b') ; hold on ; plot(f(ind),Z(ind)+50,'r')

% Modulate envelope in time domain
% First compute the envelope of the input file, this is based on vocode.m
lpFreq = 30;
[blo,alo] = butter(2,lpFreq/(Fs/2));
env = filter(blo,alo,abs(y_avg));
env = env/max(env);
figure(); plot(env);
z_env = z(1:numel(y_avg)).*env;
z_env = z_env./rms(z_env);

figure(); 
subplot(3,1,1);
plot(y_avg);
subplot(3,1,2);
plot(z(1:numel(y_avg)));
subplot(3,1,3);
plot(z_env);

soundsc(z_env,Fs);

%% Compare spectrum of a truncated noise (first ~630ms) to the spectrum of the original concatenated 
% compute and plot frequency profiles
z_short = z(1:numel(y_avg));
f = linspace(0,Fs,length(y)); 
ind = find(f>100 & f< 6e3);
f_short = linspace(0,Fs,length(y_avg)); 
ind_short = find(f_short>100 & f_short< 6e3);
Y = 20*log10(abs(fft(y)));
Z = 20*log10(abs(fft(z_short)));

figure;
subplot(2,1,1);
plot(f(ind),Y(ind),'b');
subplot(2,1,2);
plot(f_short(ind_short),Z(ind_short),'r')