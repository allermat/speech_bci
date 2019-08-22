modality = 'eeg';
% modality = 'meg';
subID = 'meg19_0239';
% subID = 'meg19_0251';
if strcmp(modality,'meg')
    sourceDir = fullfile(BCI_setupdir('analysis_meg_sub_erp',subID));
    fileStem = 'ftmeg_ERP';
else
    sourceDir = fullfile(BCI_setupdir('analysis_eeg_sub_erp',subID));
    fileStem = 'fteeg_ERP';
end
load(fullfile(sourceDir, ...
              sprintf('%s_%s_all_nontarg.mat',fileStem,subID)));
ftDataAvg_nontarg = ftDataAvg;
load(fullfile(sourceDir, ...
              sprintf('%s_%s_all_nontarg_noise.mat',fileStem,subID)));
ftDataAvg_nontarg_noise = ftDataAvg;
load(fullfile(sourceDir, ...
              sprintf('%s_%s_all_targ.mat',fileStem,subID)));
ftDataAvg_targ = ftDataAvg;
load(fullfile(sourceDir, ...
              sprintf('%s_%s_noise.mat',fileStem,subID)));
ftDataAvg_noise = ftDataAvg;
load(fullfile(sourceDir, ...
              sprintf('%s_%s_all_words.mat',fileStem,subID)));
ftDataAvg_words = ftDataAvg;
cfg = struct();
if strcmp(modality,'meg')
    cfg.layout = 'neuromag306all';
    % cfg.channel = 'megplanar';
    cfg.channel = 'megmag';
else
    cfg.layout = 'cbu_meg_eeg70';
end
figure(); ft_multiplotER(cfg,ftDataAvg_targ,ftDataAvg_nontarg)
title('Target vs. non-target');
figure(); ft_multiplotER(cfg,ftDataAvg_targ,ftDataAvg_nontarg_noise)
title('Target vs. non-target (with noise)');
figure(); ft_multiplotER(cfg,ftDataAvg_words,ftDataAvg_noise)
title('Words vs. noise');
% ftDataAvg_targ_vs_nontarg = ftDataAvg_targ;
% ftDataAvg_targ_vs_nontarg.avg = ftDataAvg_targ.avg-ftDataAvg_nontarg.avg;
% figure(); ft_multiplotER(cfg,ftDataAvg_targ_vs_nontarg);


