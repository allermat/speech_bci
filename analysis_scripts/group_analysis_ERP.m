function group_analysis_ERP()
% Group level grand average ERPs

s = subjSpec;
subjList = sort({s.subjInfo.subID})';

ftFilesToAvg = cell(size(subjList));
matchStrTokens = 'fteeg_ERP_meg[0-9]{2}_[0-9]{4}(.*).mat';

% Finding match strings for conditions
saveDf = cd(BCI_setupdir('analysis_eeg_sub_erp',subjList{1}));
fileList = dir;
fileList = {fileList.name}';
cd(saveDf);
temp = regexp(fileList,matchStrTokens,'tokens');
temp = temp(~cellfun(@isempty,temp));
temp = [temp{:}]';
matchStrConds = [temp{:}]';

for i = 1:size(matchStrConds,1)
    
    for j = 1:size(subjList,1)
        
        saveDf = cd(BCI_setupdir('analysis_eeg_sub_erp',subjList{j}));
        fileList = dir;
        fileList = {fileList.name}';
        matchID = ~cellfun(@isempty,regexp(fileList,...
            ['fteeg_ERP_meg[0-9]{2}_[0-9]{4}',matchStrConds{i},'.mat']));
        
        if sum(matchID) == 0
            warning('No file, skipping this subject! ');
            cd(saveDf);
            continue;
        elseif sum(matchID) > 1
            warning('Multiple files, skipping this subject! ');
            cd(saveDf);
            continue;
        else
            ftFilesToAvg{j} = load(fileList{matchID});
            ftFilesToAvg{j} = ftFilesToAvg{j}.ftDataAvg;
        end
               
        cd(saveDf);
    end
    
    ftFilesToAvg = ftFilesToAvg(~cellfun(@isempty,ftFilesToAvg));
    
    % Taking grand average across subjects
    cfg = struct();
    cfg.keepindividual = 'yes';
    ftDataGrAvg = ft_timelockgrandaverage(cfg,ftFilesToAvg{:});
    % Getting rid of the unnecessary previous nested configs
    ftDataGrAvg.cfg.previous = [];
    % Saving data
    fprintf('\n\nSaving data...\n\n');
    fileName = ['fteeg_ERP_group',matchStrConds{i},'.mat'];
    savePath = fullfile(BCI_setupdir('analysis_eeg_sub_erp','group'),fileName);
    save(savePath,'ftDataGrAvg','-v7.3');
        
end

end