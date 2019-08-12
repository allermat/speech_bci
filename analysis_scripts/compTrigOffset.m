function trigOffset = compTrigOffset(signal,fs,trig,varargin)

p = inputParser;

addRequired(p,'signal',@(x) validateattributes(x,{'numeric'}, ...
                            {'vector','finite'}));
addRequired(p,'fs',@(x) validateattributes(x,{'numeric'}, ...
                        {'scalar','integer','positive'}));
addRequired(p,'trig',@(x) validateattributes(x,{'numeric'}, ...
                        {'vector','integer','positive'}));
addParameter(p,'thres',0.02,@(x) validateattributes(x,{'numeric'}, ...
                        {'scalar','positive','finite'}));
addParameter(p,'minDist',0.1,@(x) validateattributes(x,{'numeric'}, ...
                        {'scalar','positive','finite'}));
parse(p,signal,fs,trig,varargin{:});
signal = p.Results.signal;
fs = p.Results.fs;
thres = p.Results.thres;
minDist = p.Results.minDist;

minDist = minDist*fs;
% The indices in the signal where it exceeds the threshold
temp = find(abs(signal) > thres);
% Compute how far apart these instances are 
dist = diff([1,temp]);
% Find where the distance is greater than a set minimum distance
idx = temp(find(dist > minDist)); %#ok<FNDSB>

% Check if the number of found stimulus onsets are matching with the number
% of triggers
if numel(idx) ~= numel(trig)
    error('compTrigOffset:arraySizeMismatch',...
         ['The number of triggers does not match the number of found ',...
         'stimulus onsets']);
end
trigOffset = (idx-trig)/fs;

end