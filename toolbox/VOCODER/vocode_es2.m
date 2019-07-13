function [channels envelopes center] = vocode(exc, mapping, filters, rectify, smooth, nCh, InFile, OutFile)
%
%  NOTE: THIS VERSION WORKS ON A PC, AND MAY WELL *NOT* WORK ON A SUN
%
%  VOCODE - This program reconstructs speech as a sum of 'nCh'
%  noise bands, sinusoids, or filtered harmonic complexes.
%  The speech input is filtered into a nCh bands, and the envelope in each band 
%  is used to modulate a noise band, harmonic complex, or sinusoid, which  
%  is then bandpass filtered into that region
%
% It was mostly written by Stuart Rosen (stuart@phon.ucl.ac.uk) based on the 
% work of Philip  Loizou. Bob Carlyon persuaded Johannes Lyzenga 
% (j.lyzenga@azvu.nl) to add the harmonic complex bit, as a possible acoustic 
% analogue of the modulated pulse trains used to code speech in some cochlear 
% implants. See complexes.txt or complexes.doc for the rationale and for further 
% instructions. Philip Loizou's original notes are in readme.doc
%
%
% function vocode(exc, mapping, filters, rectify, smooth, nCh, InFile, OutFile)
%
%  exc - 'noise', 'sine', 'F0_value', or '-F0_value', in quotes
%   for: white noise, sinusoid, sine-, or alternating-phase harm. complexes
%   as excitation for the temporal envelopes of the filtered waveforms
%  mapping of channels - 'n'(ormal) or 'i'(nverted)
%  filters - 'greenwood', 'linear', 'mel' or 'log'
%  rectify - 'half' or 'full'
%  smooth - filter cutoff frequency
%  nCh - the number of channels
%  InFile - input filename in quotes, e.g., 'heed.wav'
%  OutFile- output filename in quotes, e.g., 'heed2.wav'
%
% For example, to get an interesting variety of outputs with 6 channels,
% do the following commands:
% vocode('noise','n','greenwood','half',320,6,'sent.wav','nn320.wav')
% vocode('noise','i','greenwood','half',320,6,'sent.wav','ni320.wav')
% vocode( 'sine','n','greenwood','half',320,6,'sent.wav','sn320.wav')
% vocode( 'sine','i','greenwood','half',320,6,'sent.wav','si320.wav')
% vocode('noise','n','greenwood','half', 30,6,'sent.wav', 'nn30.wav')
% vocode('noise','i','greenwood','half', 30,6,'sent.wav', 'ni30.wav')
% vocode( 'sine','n','greenwood','half', 30,6,'sent.wav', 'sn30.wav')
% vocode( 'sine','i','greenwood','half', 30,6,'sent.wav', 'si30.wav')
% These commands are contained in file 'run.m'
%
% For harmonic complexes, e.g. sine and alternating phase with F0= 100 Hz, type:
% vocode(  '100','n','greenwood','half', 30,6,'sent.wav', 'csn30.wav')
% vocode( '-100','n','greenwood','half', 30,6,'sent.wav', 'can30.wav')
% To specify the F0 and phase for each band separately you can do this:
% vocode( '-100 72 55 200 144 72','n','greenwood','half', 30,6,'sent.wav', 
% 'mixed30.wav')
% You can produce one or more "empty" channels by specifying an F0 of 0:
%  vocode( '-100 72 0 200 144 72','n','greenwood','half', 30,6,'sent.wav', 
% '1empty.wav')
% The output file is in .WAV format and can be played using whatever 
% package you like, or just type: play filename
%



DEBUG=0;

if nargin<7
  ['Type: help vocode for more help.']
  return;
end

if smooth<=0, ['Smoothing filter low pass cutoff must be greater than 0.']
  return;
end

% if nCh<2, ['The number of channels has to be greater than 1.']
%   return;
% end

fprintf('Processing %s -> %s\n', InFile, OutFile);

% fpin=fopen(InFile,'r');
% if fpin<=0
%   ['ERROR! Could not open input file: ' InFile]
%   return;
% end
% 
% % get the extension of filename
% ext=get_ext(lower(InFile));
% 
% % read header in the input file, and return the sampling frequency (Srate) --
% [HDRSIZE, Srate, bpsa, ftype]=gethdr(fpin,ext);
% 
% % --- read the whole data file ----
% if HDRSIZE<0                    %  Byte swapping for MSDOS .WAV files
%   a=fread(fpin,inf,'int8');
%   nSmp=fix(length(a)/2);
%   x=(1:nSmp); y=(1:nSmp);
%   for i=(1:nSmp), x(i)=a(2*i-1); y(i)=a(2*i); end
%   for i=(1:nSmp), if(x(i)>=0) a(i)=x(i); else a(i)=255+x(i); end, end
%   x=(y(1:nSmp)'*256)+(a(1:nSmp));
% else
%   x=fread(fpin,inf,ftype);
%   nSmp=length(x);
% end
[x,Srate] = audioread(InFile);
nSmp = length(x);
meen=mean(x);
x=x-meen; %----------remove any DC bias---
%figure(1), plot(x)             %###

%---------------------Design the filters ----------------
[filterA,filterB,center]=estfilt(nCh,filters,Srate,DEBUG);
srat2=Srate/2;

% -- pre-emphasis filter coefficients - NOT USED HERE
% bp=exp(-1200*2*pi/Srate);
% ap=exp(-3000*2*pi/Srate);

% --- design low-pass envelope filter ----------
[blo,alo]=butter(3, smooth/srat2);

% --- in case sampling freq > 12 kHz, bandlimit signal to 6 kHz ----
if srat2>6000,  % in case sampling freq > 12 kHz, limit input signal to 6 kHz
  LPF=1;
  [blpf, alpf]=ellip(6,0.5,50,6000/srat2);
  x=filter(blpf,alpf,x);
else LPF=0;
end;

% PRE-EMPHASIS NOT USED IN THIS VERSION
%----Pre-emphasize first ----------
%x=filter([1 -bp],[1 -ap],x);

% create buffers for the necessary waveforms
% 'y' contains a single output waveform,
%     the original after filtering through a bandpass filter
% 'ModC' contains the complete set of nChannel modulated white noises
%        or sine waves, created by low-pass filtering the 'y' waveform,
%        and multiplying the resultant by an appropriate carrier
% 'band' contains the waveform associated with a single output channel,
%        the modulated white noise or sinusoid after filtering
% 'wave' contains the final output waveform constructing by adding together
%        the ModC, which are first filtered by a filter matched to
%        the input filter
%
ModC=zeros(nCh,nSmp);
y=zeros(1,nSmp);
wave=zeros(1,nSmp);
band=zeros(1,nSmp);
cmpl=zeros(1,nSmp);

% rms levels of original filter-bank outputs are stored in the vector 'levels'
levels=zeros(1, nCh);

%figure(2), plot(0,0), hold on  %###
% ----------------------------------------------------------------------%
% First construct the component modulated carriers for all channels  	%
% ----------------------------------------------------------------------%
fcnt=1; fold=0;
for i=1:nCh
  y=filter(filterB(i,:),filterA(i,:),x)';
  level(i)=norm(y,2);
  if strcmp(rectify,'half')==1
    %-- half-wave rectify and smooth the filtered signal
    y=filter(blo,alo,0.5*(abs(y)+y));
  elseif strcmp(rectify,'full')==1
    %-- full-wave rectify and smooth the filtered signal
    y=filter(blo,alo,abs(y));
  else fprintf('\nERROR! Rectification must be half or full\n');
    return;
  end
  %plot(y)                      %###

  envelopes(i,:) = y;
  
  if strcmp(exc,'noise')==1
    % -- excite with noise ---
    ModC(i,:)=y.*sign(rand(1,nSmp)-0.5);
  elseif strcmp(exc,'sine')==1
    % ---- multiply by a sine wave carrier of the appropriate carrier ----
    if strcmp(mapping,'n')==1
      ModC(i,:)=y.*sin(center(        i)*2.0*pi*[0:(nSmp-1)]/Srate);
    elseif strcmp(mapping,'i')==1
      ModC(i,:)=y.*sin(center((nCh+1)-i)*2.0*pi*[0:(nSmp-1)]/Srate);
    else fprintf('\nERROR! Mapping must be n or i\n');
      return;
    end
  elseif sum(abs(str2num(exc)))~=0   % Check for harmonic complexes
    f0=str2num(exc); fmax=size(f0); fmax=fmax(2);
    % [i fcnt f0(fcnt)]
    if f0(fcnt)~=fold
      cmpl=zeros(1,nSmp);
      if f0(fcnt)>0
        % ---- cmpl is with sine-phase complex of fundamental f0 ----
        for j=(1:fix(srat2/f0(fcnt)))
          cmpl=cmpl+sin(j*f0(fcnt)*2.0*pi*[0:(nSmp-1)]/Srate);
        end
      elseif f0(fcnt)<0
        % ---- cmpl is alternating-phase complex of fundamental f0 ----
        for j=(1:fix(-srat2/f0(fcnt)))
          if rem(j,2)==1
            cmpl=cmpl+sin(-j*f0(fcnt)*2.0*pi*[0:(nSmp-1)]/Srate);
          else
            cmpl=cmpl+cos(-j*f0(fcnt)*2.0*pi*[0:(nSmp-1)]/Srate);
          end
        end
      end
      fold=f0(fcnt);
    end
    if (fcnt<fmax) fcnt=fcnt+1; end
    % ---- multiply with sine- or alt-phase harm. complex ----
    ModC(i,:)=y.*cmpl;
  else fprintf('\nERROR! Excitation must be sine, noise, or +/-F0\n');
    return;
  end
end
%figure(2), hold off            %###
%figure(3), plot(ModC')         %###

% ----------------------------------------------------------------------%
% Now filter the components (whatever they are), and add together
% into the appropriate order, scaling for equal rms per channel
% ----------------------------------------------------------------------%
for i=1:nCh
  if sum(abs(ModC(i,:)))>0
    if strcmp(mapping,'n')==1
      band=filter(filterB(i,:),filterA(i,:),ModC(i,:));
      % scale component output waveform to have
      % equal rms to input component
      band=band*level(i)/norm(band,2);
    elseif strcmp(mapping,'i')==1
      band=filter(filterB((nCh+1)-i,:),filterA((nCh+1)-i,:),ModC(i,:));
      % scale component output waveform to have
      % equal rms to input component
      band=band*level((nCh+1)-i)/norm(band,2);
    end
    wave=wave+band;  % accumulate waveforms
    channels(i,:)=band;
  end
end

if LPF==1, wave=filter(blpf,alpf,wave); end;
%figure(4), plot(wave)          %###

% % ------------ now save output to a file ----------
% % --- first check that no sample point leads to an overload
% max_sample=max(abs(wave));
% if max_sample > 32767	% ---- !! OVERLOAD !! -----
%   % figure out degree of attenuation necessary
%   ratio=32760/max_sample;
%   wave=wave * ratio;
% %  fprintf('!! WARNING -- OVERLOAD !!');
%   fprintf(' File scaled by %f = %f dB\n', ratio, 20*log10(ratio));
% end
% 
% fpout=fopen(OutFile,'w+');
% if fpout>=0
%   savehder(fpin,fpout,ext,nSmp,HDRSIZE)
%   fclose(fpin);
%   if HDRSIZE<0                    %  Byte swapping for MSDOS .WAV files
%     x=(1:nSmp); y=(1:2*nSmp);
%     x=fix(wave/256); wave=wave-256*x;
%     for i=(1:nSmp), if(x(i)<0) x(i)=255+x(i); end, end
% %   [min(x) max(x)], [min(wave) max(wave)]
%     for i=(1:nSmp), y(i*2-1)=wave(i); y(i*2)=x(i); end
%     fwrite(fpout,y,'int8');
%     fclose(fpout);
%   else
%     fwrite(fpout, wave,'short');
%     fclose(fpout);
%   end
% else
%   fprintf('ERROR in path! Could not save file.\n');
%   fclose(fpout);
% end

max_sample=max(abs(wave));
if max_sample > 32767	% ---- !! OVERLOAD !! -----
  % figure out degree of attenuation necessary
  ratio=32760/max_sample;
  wave=wave * ratio;
%  fprintf('!! WARNING -- OVERLOAD !!');
  fprintf(' File scaled by %f = %f dB\n', ratio, 20*log10(ratio));
end
audiowrite(OutFile,wave,Srate);
