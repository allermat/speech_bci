function badTrials = rejecttrials(megData,artfData,winOfInt)
% Checks if trials meet various criteria
% 
% DETAILS:
%   Checks each trial found in the eegData whether: 
%       (1) the response is missing
%       (2) the response is early
%       (3) the response was made by wrong hand    
%       (4) there is an EEG artefact
%       (5) there is eyetracker data present for the trial
%       (6) there is an eyeblink
%       (7) there is a saccade
%       (8) the fixation is at the correct location
%       
% INPUT:
%   eegData: epoched fieldtrip data file
%   behavData: table of behavioural data (containing the whole dataset)
%   eyeData: structure array of eyetracker data (containing the whole 
%            dataset)
%   artfData: structure array of detected EEG artefacts (corresponding to
%       the fieldtrip data file)
%   trigDef: table of trigger code definitions
%   winOfInt: 1 x 2 vector with the start and end time of time window of 
%       interest with respect to the target event onset
%   minRespTime: scalar, minimum response time in seconds
%   saccadeThresholds: 1 x 3 vector of the threshold values for defining 
%       the saccades
%       thresholds(1) = minimum amplitude in degrees
%       thresholds(2) = minimum peak velocity in degrees/seconds
%       thresholds(3) = minimum duration in seconds
%   fixationCriteria: 1 x 3 vector of the criteria for accepting a fixation
%       event
%       criteria(1) = fixation cross x coordinate (in pixels)
%       criteria(2) = fixation cross y coordinate (in pixels)
%       criteria(3) = radius of the accepted area around the
%                     fixation cross (in pixels)
%   mode: 'normal', 'prestim'
% 
% OUTPUT: 
%   badTrials: vector of number of trials x 1 with the following codes
%       0 - good
%       1 - no response
%       2 - early response
%       3 - wrong hand
%       4 - EEG artefact
%       5 - missing eyetracker data
%       6 - eyeblink
%       7 - saccade
%       8 - wrong fixation location
% 
% Copyright (c) 2019 Mate Aller

%% Parsing input
p = inputParser;

% Input checking functions
checkFtData = @(x) ft_datatype(x,'raw');
checkArtfData = @(x) isstruct(x) && ...
    all(ismember({'artefact_muscle'},fieldnames(x)));

% Defining input
addRequired(p,'megData',checkFtData);
addRequired(p,'artfData',checkArtfData);
addRequired(p,'winOfInt',@(x) validateattributes(x,{'numeric'},...
    {'size',[1,2],'increasing'}));

% Parsing inputs
parse(p,megData,artfData,winOfInt);

% Assigning input to variables
megData = p.Results.megData;
artfData = p.Results.artfData;
winOfInt = p.Results.winOfInt;


%% Function body

% eeg data properties
trialInfo = megData.trialinfo;
nStimInFile = size(trialInfo,1);
actRun = trialInfo(1,1);

% Array for collecting rejection info
badTrials = zeros(nStimInFile,1);

for iStimInFile = 1:nStimInFile
    %% Checking EEG artefacts
    % Is there an EEG artefact?
    sampleInfo = megData.sampleinfo(iStimInFile,:);
    time = megData.time{iStimInFile};
    if checkartefacts(sampleInfo,time,megData.fsample,winOfInt,artfData)
        badTrials(iStimInFile) = 1;
        continue;
    end
    
end

end


function foundArtefact = checkartefacts(sampleInfo,time,Fs,winOfInt,artfData)
% Checks whether there is any artefact within the trial
% 
% INPUT: 
%   sampleInfo: 1 x 2 vector of the start and end samples of the trial of
%       interest
%   time: 1 x N vector of time values (in seconds) corresponding to the 
%       samples of the trial of interest, where N is the number of samples.
%   Fs: sampling frequency
%   winOfInt: 1 x 2 vector with the start and end time of time window of 
%       interest with respect to the target event onset
%   artfData: structure array of artefact definitions. Each field of the
%       array is an N x 2 matrix of artefact start and end samples, where N
%       is the number of artefacts. Different fields contain different
%       artefact types. 
% 
% OUTPUT:
%   foundArtefact: true if there is an artefact within the window of
%       interest of the trial
% 

foundArtefact = false;

artfTypes = fieldnames(artfData);
artfTypes = artfTypes(~cellfun(@isempty,regexp(artfTypes,'^artefact_','once')));

stimOnsetSample = sampleInfo(1)-(time(1)*Fs);
startSampleWinOfInt = stimOnsetSample+(winOfInt(1)*Fs);
endSampleWinOfInt = stimOnsetSample+(winOfInt(2)*Fs);

for i = 1:size(artfTypes,1)
    actArtfData = artfData.(artfTypes{i});
    
    % Skip if there are no artefacts
    if isempty(actArtfData)
        break;
    end
    
    % Find artefacts which:
    % begin within the window of interest
    crit1 = actArtfData(:,1) >= startSampleWinOfInt & ...
        actArtfData(:,1) <= endSampleWinOfInt;
    % end within the winow of interest
    crit2 = actArtfData(:,2) >= startSampleWinOfInt & ...
        actArtfData(:,2) <= endSampleWinOfInt;
    % cover the whole window of interest
    crit3 = actArtfData(:,1) <= startSampleWinOfInt & ...
        actArtfData(:,2) >= endSampleWinOfInt;
    
    % If there is an artefact which fall under either criteria, mark it and
    % break.
    foundArtefact = any(crit1 | crit2 | crit3);
    if foundArtefact
        break;
    end
end


end
