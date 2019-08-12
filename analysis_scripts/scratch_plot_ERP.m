load('ftmeg_ERP_meg19_0251_all_nontarg.mat')
ftDataAvg_nontarg = ftDataAvg;
load('ftmeg_ERP_meg19_0251_all_targ.mat')
ftDataAvg_targ = ftDataAvg;
cfg = struct();
cfg.layout = 'neuromag306all';
% cfg.channel = 'megplanar';
cfg.channel = 'megmag';
figure(); ft_multiplotER(cfg,ftDataAvg_nontarg,ftDataAvg_targ)
ftDataAvg_targ_vs_nontarg = ftDataAvg_targ;
ftDataAvg_targ_vs_nontarg.avg = ftDataAvg_targ.avg-ftDataAvg_nontarg.avg;
figure(); ft_multiplotER(cfg,ftDataAvg_targ_vs_nontarg);


