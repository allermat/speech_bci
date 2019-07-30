function trialInfoOut = buildtrialinfo(trialInfo,behavData,fileSpec)
% Builds trialInfo from the available behavioural information
% 
% DETAILS:
%   Converts the trialinfo field provided by FieldTrip to a
%   cellarray of structures, which makes the various pieces of
%   information more intuitive to access.
%       
% INPUT:
%   trialInfo (matrix): the trialinfo field of the FieltTrip data
%       structure
%   behavData: sturcture array of behavioural data (each array
%       element contains data from one run)
%   fileSpec: structure with information about the MEG file
%
% OUTPUT: 
%   trialInfoOut (cell): cell array of structures as containing
%       trial informaiton
% 
% Copyright(C) 2019, Mate Aller

% Parsing input
p = inputParser;

% Input checking functions
checkBehavData = @(x) istable(x);
checkFileSpec = @(x) istable(x) && all(ismember({'fileName',...
                    'nRunsInFile','exclude','iRunOverall'},...
                      x.Properties.VariableNames));
% Defining input
addRequired(p,'trialInfo',@(x) validateattributes(x,{'numeric'},{'2d'}));
addRequired(p,'behavData',checkBehavData);
addRequired(p,'fileSpec',checkFileSpec);
% Parsing inputs
parse(p,trialInfo,behavData,fileSpec);

% Assigning input to variables
trialInfo = p.Results.trialInfo;
behavData = p.Results.behavData;
fileSpec = p.Results.fileSpec;

trialInfoOut = array2table(trialInfo,'VariableNames',...
    {'iRun','iTrialInRun','iStimInTrial','condition','badTrials'});
temp = varfun(@(x) size(x,1),trialInfoOut,'InputVariables','iRun',...
       'GroupingVariables',{'iTrialInRun'});
nStimPerTrial = temp.GroupCount;
temp = table;
for i = 1:numel(nStimPerTrial)
    temp = cat(1,temp,repmat(behavData(i,{'Target_word','Response','Correct_response'}),...
        nStimPerTrial(i),1));
end
temp.Properties.VariableNames = {'target','resp','respCorrect'};
temp.isRespCorrect = temp.resp == temp.respCorrect;
trialInfoOut = cat(2,trialInfoOut,temp);
trialInfoOut = movevars(trialInfoOut,'badTrials','After',size(trialInfoOut,2));
trialInfoOut = sortrows(trialInfoOut,{'iRun','iTrialInRun','iStimInTrial'});

% % Sanity check between behav and trialinfo
% if any(trialInfoOut.condition ~= trialInfo(:,4))
%     error('buildTrialInfo:dataMismatch',...
%         'Behavioural data does not match the trialinfo in EEG data! ');
% end
trialInfoOut = mat2cell(table2struct(trialInfoOut),ones(size(trialInfoOut,1),1));

end