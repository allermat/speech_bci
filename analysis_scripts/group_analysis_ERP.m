function group_analysis_ERP(varargin)
% Group level grand average ERPs

% Parsing input, checking matlab
p = inputParser;

validModalities = {'meg','eeg'};

addOptional(p,'modality','meg',@(x) ismember(x,validModalities));

parse(p,varargin{:});

modality = p.Results.modality;

if strcmp(modality,'eeg')
    fileTag = 'fteeg';
    dirID = 'analysis_eeg_sub_erp';
else
    fileTag = 'ftmeg';
    dirID = 'analysis_meg_sub_erp';
end

s = subjSpec;
subjList = sort({s.subjInfo.subID})';

matchStrTokens = [fileTag,'_ERP_meg[0-9]{2}_[0-9]{4}(.*).mat'];

% Finding match strings for conditions
saveDf = cd(BCI_setupdir(dirID,subjList{1}));
fileList = dir;
fileList = {fileList.name}';
cd(saveDf);
temp = regexp(fileList,matchStrTokens,'tokens');
temp = temp(~cellfun(@isempty,temp));
temp = [temp{:}]';
matchStrConds = [temp{:}]';

for i = 1:size(matchStrConds,1)
    
    ftFilesToAvg = cell(size(subjList));
    
    for j = 1:size(subjList,1)
        
        saveDf = cd(BCI_setupdir(dirID,subjList{j}));
        fileList = dir;
        fileList = {fileList.name}';
        matchID = ~cellfun(@isempty,regexp(fileList,...
            [fileTag,'_ERP_meg[0-9]{2}_[0-9]{4}',matchStrConds{i},'.mat']));
        
        if sum(matchID) == 0
            warning('No file, skipping subject %s! ',subjList{j});
            cd(saveDf);
            continue;
        elseif sum(matchID) > 1
            warning('Multiple files, skipping subject %s! ',subjList{j});
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
    fileName = [fileTag,'_ERP_group',matchStrConds{i},'.mat'];
    savePath = fullfile(BCI_setupdir(dirID,'group'),fileName);
    save(savePath,'ftDataGrAvg','-v7.3');
        
end

end