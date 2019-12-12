s = subjSpec;
subID = {s.subjInfo.subID}';

for iSubj = 1:numel(subID)
    sourceFiles = fullfile(BCI_setupdir('analysis_meg_sub_mvpa',...
                           subID{iSubj}),'RSA','*.mat');
    destFolder = fullfile(BCI_setupdir('analysis_meg_sub_mvpa',...
                          subID{iSubj}),'RSA','stash_std');
    movefile(sourceFiles,destFolder);
end