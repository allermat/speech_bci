function play(InputFile)

%  PLAY - This program plays back a file.
%
%    play(infile)
%       infile -  the input file name
%  
%  Depending on the extension of the filename (e.g., .wav), the program extracts 
%  the sampling frequency from the header of the file. Its very important that
%  the extension of the filename is preserved when renaming or copying files.
%  
%  Copyright (c) 1998 Philipos C. Loizou
%


if nargin<1
   fprintf('Usage: play Inputfile \n');
   fprintf('Type: help play  for more help.\n\n');
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
fclose(fpin);

meen=mean(x);
x= x - meen; %----------remove any DC bias---

%sound(x,Srate);
%sound(x,Srate); if you are using MATLAB 4.x version, uncomment this line
soundsc(x,Srate,16);

