% subID = 'meg19_0239';
subID = 'meg19_0251';
load(fullfile(BCI_setupdir('analysis_meg_sub_erp',subID), ...
              sprintf('ftmeg_ERP_%s_all_nontarg.mat',subID)));
ftDataAvg_nontarg = ftDataAvg;
load(fullfile(BCI_setupdir('analysis_meg_sub_erp',subID), ...
              sprintf('ftmeg_ERP_%s_all_nontarg_noise.mat',subID)));
ftDataAvg_nontarg_noise = ftDataAvg;
load(fullfile(BCI_setupdir('analysis_meg_sub_erp',subID), ...
              sprintf('ftmeg_ERP_%s_all_targ.mat',subID)));
ftDataAvg_targ = ftDataAvg;
load(fullfile(BCI_setupdir('analysis_meg_sub_erp',subID), ...
              sprintf('ftmeg_ERP_%s_noise.mat',subID)));
ftDataAvg_noise = ftDataAvg;
load(fullfile(BCI_setupdir('analysis_meg_sub_erp',subID), ...
              sprintf('ftmeg_ERP_%s_all_words.mat',subID)));
ftDataAvg_words = ftDataAvg;
cfg = struct();
cfg.layout = 'neuromag306all';
% cfg.channel = 'megplanar';
cfg.channel = 'megmag';
figure(); ft_multiplotER(cfg,ftDataAvg_targ,ftDataAvg_nontarg)
title('Target vs. non-target');
figure(); ft_multiplotER(cfg,ftDataAvg_targ,ftDataAvg_nontarg_noise)
title('Target vs. non-target (with noise)');
figure(); ft_multiplotER(cfg,ftDataAvg_words,ftDataAvg_noise)
title('Words vs. noise');
% ftDataAvg_targ_vs_nontarg = ftDataAvg_targ;
% ftDataAvg_targ_vs_nontarg.avg = ftDataAvg_targ.avg-ftDataAvg_nontarg.avg;
% figure(); ft_multiplotER(cfg,ftDataAvg_targ_vs_nontarg);


