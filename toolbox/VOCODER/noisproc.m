function noiseproc(nChannels,InputFile,OutputFile)

%  NOISEPROC - This program reconstructs speech as a sum of 'nChannels' noise bands
%
%   noiseproc(nChannels, inputFile, outputFile)
%       nChannels - the number of channels
%       inputFile - input filename in quotes, e.g., 'heed.wav'
%       outputFile- output filename in quotes, e.g., 'heed2.wav'
%
%   To listen to the output file, just type: play OutputFile
%
%  Copyright (c) 1998 Philipos C. Loizou
%


if nargin<3
   fprintf('Usage: noiseproc(nChannels,''Inputfile'',''OutputFile'') \n');
   fprintf('Type: help noiseproc   for more help.\n\n');
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


meen=mean(x);
x= x - meen; %----------remove any DC bias---


%---------------------Design the filters ----------------
%

  if nChannels<=8,
     [filterA,filterB,center]=estfilt(nChannels,'log',Srate); % use log spacing
    else
     [filterA,filterB,center]=estfilt(nChannels,'mel',Srate); % use mel spacing
   end

	srat2=Srate/2;
   
   % -- pre-emphasis filter coefficients
   %
   bp = exp(-1200*2*pi/Srate);   
   ap = exp(-3000*2*pi/Srate);


   % --- design low-pass filter ----------
   %
   [blo,alo]=butter(2,160/srat2);

   if srat2>6000,  % in case sampling freq > 12 kHz
      LPF=1; 
      [blpf, alpf]=ellip(6,0.5,50,6000/srat2); 
   else, LPF=0; 
   end;  
	
	
	


% --- in case sampling freq > 12 kHz, bandlimit singal to 6 kHz ----
%
if LPF==1, x=filter(blpf,alpf,x); end;

%----Pre-emphasize first ----------
%
x = filter([1 -bp],[1 -ap],x); 

y1=zeros(1,n_samples);
yout=zeros(1,n_samples);
y2=zeros(1,n_samples);

     %-----------Generate the modulating noise------
     % 
	   mpy=zeros(1,n_samples);
	   ns=rand(1,n_samples)-0.5;
	   mpy=sign(ns);  % 1 or -1 with a prob of 0.5


for i=1:nChannels  % ========= Main loop ========================
	y1=filter(filterB(i,:),filterA(i,:),x)';
	ein=norm(y1,2);
	y2=filter(blo,alo,0.5*(abs(y1)+y1)); %-- half-wave rectify filtered signal
	
	y1=y2.*mpy; % ----- excite with noise and reconstruct ------------
   y2=filter(filterB(i,:),filterA(i,:),y1);
	eout=norm(y2,2);
   
   y2=y2*ein/eout; % scale output waveform

	yout=yout+y2;  % accumulate waveforms

   
end % end of main loop


if LPF==1, yout=filter(blpf,alpf,yout); end;


% ------------ now save output to a file -----------
%

fpout = fopen(OutputFile,'w+');
if fpout>=0
 savehder(fpin,fpout,ext,n_samples)
 fclose(fpin);
 fwrite(fpout,yout,'short');
 fclose(fpout);
else
 fprintf('ERROR in path! Could not save file.\n');
 fclose(fpout);
end





