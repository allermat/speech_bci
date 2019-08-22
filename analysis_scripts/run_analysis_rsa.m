clearvars; 
% Defining parameters
% subID = {'meg19_0239','meg19_0251'};
subID = {'meg19_0233'};
analysis = {'noise','words'};
channel = {'all','megplanar'};
poolOverTime = [false,true];
for iSub = 1:numel(subID)
    % Loading data
    ftData = load(fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID{iSub}),...
                  sprintf('ftmeg_MVPA_%s.mat',subID{iSub})));
    ftData = ftData.ftDataClean;
    
    for iAnal = 2:numel(analysis)
        for iChan = 1:numel(channel)
            for iPool = 1:numel(poolOverTime)
                analysis_rsa(subID{iSub},...
                             'ftData',ftData,...
                             'analysis',analysis{iAnal},...
                             'channel',channel{iChan},...
                             'poolOverTime',poolOverTime(iPool));
            end
        end
    end
end
