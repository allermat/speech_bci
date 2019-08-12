function saveallfigures(varargin)
% Saves all present Matlab figures to the current folder
% 
% INPUT:
%   format: string indicating the file format. ('fig', 'png', 'emf',
%       default: 'fig')
%   name: string indicating the name of the figures (if there are more than
%       one figures the name will be extended with a serial number as well)
% 
% OUTPUT: -
%

%% Parsing input, checking matlab
p = inputParser;

validFormats = {'fig','png','emf','svg'};
checkFormat = @(x) any(validatestring(x,validFormats));
addOptional(p,'format','fig',checkFormat);
addOptional(p,'name','figure',@(x)validateattributes(x,{'char'},{'nonempty'}));
addOptional(p,'hiRes',false,@(x)validateattributes(x,{'logical'},{'scalar'}));

parse(p,varargin{:});

name = p.Results.name;
format = p.Results.format;
hiRes = p.Results.hiRes;

%%
h = get(0,'children');
if verLessThan('matlab',' R2014b')
    h = sort(h);
else
    [~,idx] = sort([h.Number]);
    h = h(idx);
end
j = 0;
for i = 1:length(h)
    set(h(i),'PaperPositionMode','auto');
    
    fileName = [name,'_',num2str(i+j)];
    while exist([fileName,'.',format],'file')
        j = j+1;
        fileName = [name,'_',num2str(i+j)];
    end
    
    if strcmp(format,'svg')
        print(h(i),'-painters',fileName,'-dsvg');
    else
        if hiRes
            print(h(i),fileName,'-dpng','-r1200')
        else
            saveas(h(i),fileName,format);
        end
    end
     
end


