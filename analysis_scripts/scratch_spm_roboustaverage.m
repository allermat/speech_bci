% Removing standalone FieldTrip from path
p = strsplit(path,':');
idx = (~cellfun(@isempty,regexp(p,'/fieldtrip/','once')));
if ~isempty(idx)
    rmpath(p{idx});
end
% Adding SPM12 to path
addpath('/imaging/local/software/spm_cbu_svn/releases/spm12_latest')

% Load FieldTrip data
fileName = 'fteeg_MVPA_meg19_0378.mat';
load(fileName,'ftDataClean');
% Convert FT dataset to SPM format
D = spm_eeg_ft2spm(ftDataClean,strrep(fileName,'fteeg_','spmeeg_'));
% Add condition tags to trials
trialinfo = struct2table(cat(1,ftDataClean.trialinfo{:}));
temp = cellfun(@num2str,num2cell(trialinfo.condition),'UniformOutput',false);
D = D.conditions(1:numel(temp),temp);
D.save;

