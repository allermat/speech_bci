function sineproc(nChannels,InputFile,OutputFile)

%  SINEPROC - This program reconstructs speech as a sum of 'nChannels' sinewaves
%
%   sineproc(nChannels, inputFile, outputFile)
%       nChannels - the number of channels has to be > 1
%       inputFile - input filename in quotes, e.g., 'heed.wav'
%       outputFile- output filename in quotes, e.g., 'heed2.wav'
%
%  To listen to the output file, just type: play OutputFile
%
%  Copyright (c) 1998 Philipos C. Loizou
%


if nargin<3
   fprintf('Usage: sineproc(nChannels,''Inputfile'',''OutputFile'') \n');
   fprintf('Type: help sineproc   for more help.\n\n');
   return;
end

if nChannels<2, fprintf('The number of channels has to be greater than 1.\n\n'); 
   return;
end

fpin=fopen(InputFile,'r');
if fpin<=0,
  fprintf('\nERROR! Could not open input file: %s\n',InputFile);
  return;
end

ind1=find(InputFile == '.');
if length(ind1)>1, ind=ind1(length(ind1)); else, ind=ind1; end;
ext = lower(InputFile(ind+1:length(InputFile))); % get the extension of filename

% -- read the header in the input file, and return the sampling frequency (Srate) --
%
[HDRSIZE,Srate,bpsa, ftype] =  gethdr(fpin,ext);


% --- read the whole data file ----
%
x=fread(fpin,inf,ftype);
n_samples=length(x);


duration=4; % duration (msec) of speech frames
fRate=round(duration*Srate/1000);
FFTlen=fRate;
rsln=Srate/FFTlen;	
nFrames=floor(n_samples/fRate); % number of speech frames



meen=mean(x);
x= x - meen; %----------remove the DC bias---

%---------------------Design the bandpass filters ----------------
%
  srat2=Srate/2;
  if srat2>6000, LPF=1; else, LPF=0; end;  % in case sampling freq > 12 kHz
  

  if nChannels<=8,
     [filterA,filterB,center]=estfilt(nChannels,'log',Srate); % use log spacing
    else
     [filterA,filterB,center]=estfilt(nChannels,'mel',Srate); % use mel spacing
   end



% ------- design the low-pass filter ---
%
[bl,al]=butter(2,400/(Srate/2));


%------- design the preemphasis filter ---------
%
bp = exp(-1200*2*pi/Srate);
ap = exp(-3000*2*pi/Srate);

     

if LPF==1, 
   [blpf, alpf]=ellip(6,0.5,50,6000/srat2);
   x=filter(blpf,alpf,x); 
end;

% ----- pre-emphasize first --------
%
x = filter([1 -bp],[1 -ap],x); 

% ---- bandpass-filter, rectify and extract envelope of signal x(n) --------
%
y=zeros(nChannels,n_samples);
for i=1:nChannels
	y1=filter(filterB(i,:),filterA(i,:),x)'; % filter signal
	y(i,:)=filter(bl,al,abs(y1)); % full-wave rectify filtered waveforms, and extract envelope
end





cnst=2*pi;
freq=center/Srate; % normalized center frequencies
indx3=round(center/rsln);
indx3=indx3+1;
Ac = 2/FFTlen;
ampl=zeros(1,nChannels);
yout=zeros(1,nFrames*fRate);



k=1;
for t=1:nFrames % ============= main loop ===============

	xin=x(k:k+fRate-1); Ein=norm(xin,2);
	seg=zeros(1,FFTlen);
   seg(1:fRate)=xin;
   yseg=fft(seg,FFTlen);
	phase=atan2(imag(yseg(indx3)),real(yseg(indx3))); % optional
	

	ampl=zeros(1,nChannels);  % compute the channel outputs
	for i=1:nChannels
	   yin=y(i,k:k+fRate-1); 
	   ampl(i)=norm(yin,2);
	end

	
	ytest=zeros(1,FFTlen);
	for i=1:nChannels % ------ sum up nChannels sinewaves ---------
	     y2=Ac*cos(cnst*freq(i)*[0:FFTlen-1]+phase(i));
	     ytest=ytest+ampl(i)*y2;  
	end
	
	Eout=norm(ytest,2);% scale so that output has same energy as input
	yout(k:k+fRate-1)=ytest*Ein/Eout;
	
	k=k+fRate;

	
end % ====== end of main loop ========


%-------------- finally, save output (yout) to a file ------------------
%
if LPF==1, yout=filter(blpf,alpf,yout); end;



fpout = fopen(OutputFile,'w+');
if fpout>=0
 savehder(fpin,fpout,ext,nFrames*fRate); % save the header information first
 fclose(fpin);
 fwrite(fpout,yout,'short');
 fclose(fpout);
else
 fprintf('ERROR in path! Could not save file.\n');
 fclose(fpout);
end



