function [idx,stimKey] = pseudorandomize_stimuli(stimKey,varargin)

p = inputParser;
addRequired(p,'stimKey',...
            @(x) validateattributes(x,{'numeric'},{'vector','integer','positive'}));
% There has to be at least this many other stimuli between each repetition
% of the same stimulus. It seems to covnerge pretty quickly wihth n = 2,
% but it becomes too long after above that.
addOptional(p,'nBetween',2,...
            @(x) validateattributes(x,{'numeric'},{'scalar','integer','positive'}));
parse(p,stimKey,varargin{:});
stimKey = p.Results.stimKey;
nBetween = p.Results.nBetween;
 
while 1
    idx = randperm(numel(stimKey));
    temp = stimKey(idx);
    isFailed = arrayfun(@(x) any(diff(find(temp == x)) < nBetween),unique(stimKey));
    if all(~isFailed)
        break;
    end
end

stimKey = temp;

end