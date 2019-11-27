function [idx,stimKey] = pseudorandomize_stimuli(stimKey,varargin)

p = inputParser;
addRequired(p,'stimKey',...
            @(x) validateattributes(x,{'numeric'},{'vector','integer','positive'}));
% There has to be at least this many other stimuli between each repetition
% of the same stimulus. It seems to covnerge pretty quickly wihth n = 2,
% but it becomes too long after above that.
addOptional(p,'nConsecutive',2,...
            @(x) validateattributes(x,{'numeric'},{'scalar','integer','positive'}));
parse(p,stimKey,varargin{:});
stimKey = p.Results.stimKey;
nConsecutive = p.Results.nConsecutive;

while 1
    idx = randperm(numel(stimKey));
    temp = stimKey(idx);
    % % This is from MATLAB central: How to find the number of consecutive
    % % identical elements in array
    % d = [true, diff(X) ~= 0, true];  % TRUE if values change
    % n = diff(find(d));               % Number of repetitions
    isFailed = any(diff(find([true,diff(temp') ~= 0,true])) > nConsecutive);
    if all(~isFailed)
        break;
    end
end

stimKey = temp;

end