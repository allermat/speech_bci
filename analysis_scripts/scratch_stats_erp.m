% define the parameters for the statistical comparison
% load('fteeg_ERP_group_all_nontarg.mat');
% ftData_nontarg = ftDataGrAvg;
% load('fteeg_ERP_group_all_targ.mat');
% ftData_targ = ftDataGrAvg;

chanOfInterest = {'EEG018','EEG048'};
for i = 1:numel(chanOfInterest)
    cfg = [];
    cfg.channel     = chanOfInterest{i};
    cfg.latency     = [0.3 0.4];
    cfg.avgovertime = 'yes';
    cfg.parameter   = 'individual';
    cfg.method      = 'analytic';
    cfg.statistic   = 'ft_statfun_depsamplesT';
    cfg.alpha       = 0.05;
    cfg.correctm    = 'no';
    
    Nsub = 3;
    cfg.design(1,1:2*Nsub)  = [ones(1,Nsub) 2*ones(1,Nsub)];
    cfg.design(2,1:2*Nsub)  = [1:Nsub 1:Nsub];
    cfg.ivar                = 1; % the 1st row in cfg.design contains the independent variable
    cfg.uvar                = 2; % the 2nd row in cfg.design contains the subject number
    
    stat(i) = ft_timelockstatistics(cfg,ftData_nontarg,ftData_targ);   % don't forget the {:}!
end