clearvars; 
% Defining parameters
subID = {'meg19_0233','meg19_0239','meg19_0251'};
% subID = {'meg19_0233'};
% analysis = {'noise','words','all'};
analysis = {'noise'};
% channel = {'all','megplanar'};
channel = {'all'};
% timeMode = {'resolved','pooled','movingWin'};
timeMode = {'movingWin'};
for iSub = 1:numel(subID)
    % Loading data
    ftData = load(fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID{iSub}),...
                  sprintf('ftmeg_MVPA_%s.mat',subID{iSub})));
    ftData = ftData.ftDataClean;
    for iAnal = 1:1 %numel(analysis)
        for iChan = 1:numel(channel)
            for iTimeMode = 1:numel(timeMode)
                analysis_rsa(subID{iSub},...
                             'ftData',ftData,...
                             'analysis',analysis{iAnal},...
                             'channel',channel{iChan},...
                             'timeMode',timeMode{iTimeMode});
            end
        end
    end
end
