% signal = stimAll{1}(1:115000);
signal = stimAll{1};
fs = 44100;
minDist = 0.1*fs;
thres = 0.02;
% The indices in signal where it exceeds the threshold
temp = find(abs(signal) > thres);
% Compute how far apart these instances are 
dist = diff([1,temp]);
% Find where the distance is greater than a set minimum distance
idx = temp(find(dist > minDist));

wordFreq = 1.6;
incr = round(1/wordFreq*fs);
[marker,trig] = deal(zeros(size(signal)));
marker(idx) = 1;
trig(mod(1:size(trig,2),incr) == 1) = 1;
time = (1:size(signal,2))/fs;
figure(); plot(time,signal); hold on;
plot(time,marker,'r');
plot(time,trig,'g');