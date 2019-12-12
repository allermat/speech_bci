clearvars; 
% Defining parameters
subID = {'meg19_0428','meg19_0432','meg19_0436','meg19_0439'};
% subID = {'meg19_0439'};
analysis = {'noise','words','all'};
% analysis = {'words','all'};
% channel = {'all','megplanar'};
channel = {'all'};
% timeMode = {'resolved','pooled','movingWin'};
timeMode = {'resolved','movingWin'};
for iSub = 1:numel(subID)
    % Loading data
    ftData = load(fullfile(BCI_setupdir('analysis_meg_sub_mvpa_preproc',subID{iSub}),...
                  sprintf('ftmeg_MVPA_%s.mat',subID{iSub})));
    ftData = ftData.ftDataClean;
    for iAnal = 1:numel(analysis)
        for iChan = 1:numel(channel)
            for iTimeMode = 1:numel(timeMode)
                analysis_rsa(subID{iSub},...
                             'ftData',ftData,...
                             'analysis',analysis{iAnal},...
                             'channel',channel{iChan},...
                             'timeMode',timeMode{iTimeMode},...
                             'equalizeNtoAvg',true);
            end
        end
    end
end
