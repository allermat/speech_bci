function extension = get_ext(filename)

%  GET_EXT - Get the extension from a file name
%

k = findstr(filename, '.');

if (length(k)>0) 
	extension = filename(k(length(k))+1:length(filename));
else extension = []; end;

