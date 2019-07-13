function file_root = xcz_ext(filename)

%  XCZ_EXT - Excise the extension from a path name
%
% A reasonable default
file_root = filename;

% find all occurences of '.', and excise its final occurence, as long
% as it does not occur in a directory name

k = findstr(filename, '.');
j = findstr(filename, '\');

% Need to check that there is not a '\' after the last '.'
if (length(k)>0) 
	if (k(length(k))>j(length(j))) 
		file_root = filename(1:k(length(k))-1);
	end
end
