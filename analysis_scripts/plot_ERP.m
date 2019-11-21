function plot_ERP(subID,varargin)
% Function to plot ERP results
% Parsing input
p = inputParser;

validModalities = {'meg','eeg'};

addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
addOptional(p,'modality','meg',@(x) ismember(x,validModalities));
addOptional(p,'childDir','',@ischar);

parse(p,subID,varargin{:});

subID = p.Results.subID;
modality = p.Results.modality;
childDir = p.Results.childDir;

if ~iscell(subID), subID = {subID}; end

for iSub = 1:numel(subID)
    if strcmp(modality,'meg')
        sourceDir = fullfile(BCI_setupdir('analysis_meg_sub_erp',subID{iSub}),childDir);
        fileStem = 'ftmeg_ERP';
    else
        sourceDir = fullfile(BCI_setupdir('analysis_eeg_sub_erp',subID{iSub}),childDir);
        fileStem = 'fteeg_ERP';
    end
    
    matchStr = {'all_nontarg','all_targ','noise_sum','noise_ws','all_words'};
%     matchStr = {'yes_nontarg','yes_targ','noise','all_words'};
    for iStr = 1:numel(matchStr)
        load(fullfile(sourceDir, ...
            sprintf('%s_%s_%s.mat',fileStem,subID{iSub},matchStr{iStr})));
        if strcmp(subID{iSub},'group')
            ftDataToPlot.(matchStr{iStr}) = ftDataGrAvg;
        else
            ftDataToPlot.(matchStr{iStr}) = ftDataAvg;
        end
    end

    cfg = struct();
    if strcmp(modality,'meg')
        cfg.layout = 'neuromag306all';
        % cfg.channel = 'megplanar';
        cfg.channel = 'megmag';
    else
        cfg.layout = 'cbu_meg_eeg70';
    end
%     figure(); ft_multiplotER(cfg,ftDataToPlot.yes_targ,ftDataToPlot.yes_nontarg)
    figure('units','normalized','outerposition',[0 0 0.6 0.8]);
    ft_multiplotER(cfg,ftDataToPlot.all_targ,ftDataToPlot.all_nontarg)
    title('Target vs. non-target');
    
    cfg1 = struct();
    cfg1.operation = 'subtract';
    if strcmp(subID,'group')
        cfg1.parameter = 'individual';
    else
        cfg1.parameter = 'avg';
    end
    diff_targ_nontarg = ft_math(cfg1,ftDataToPlot.all_targ,ftDataToPlot.all_nontarg);
    figure('units','normalized','outerposition',[0 0 0.6 0.8]);
    ft_multiplotER(cfg,diff_targ_nontarg);
    title('Target minus non-target');
    
    % figure(); ft_multiplotER(cfg,ftDataAvg_targ,ftDataAvg_nontarg_noise)
    % title('Target vs. non-target (with noise)');
    figure('units','normalized','outerposition',[0 0 0.6 0.8]);
    ft_multiplotER(cfg,ftDataToPlot.all_words,ftDataToPlot.noise_sum,...
                             ftDataToPlot.noise_ws)
    title('Words vs. noise');
    
    cfg1 = struct();
    cfg1.operation = 'subtract';
    if strcmp(subID,'group')
        cfg1.parameter = 'individual';
    else
        cfg1.parameter = 'avg';
    end
    diff_words_noisesum = ft_math(cfg1,ftDataToPlot.all_words,ftDataToPlot.noise_sum);
    figure('units','normalized','outerposition',[0 0 0.6 0.8]);
    ft_multiplotER(cfg,diff_words_noisesum);
    title('Words minus noise\_sum');
    
    cfg1 = struct();
    cfg1.operation = 'subtract';
    if strcmp(subID,'group')
        cfg1.parameter = 'individual';
    else
        cfg1.parameter = 'avg';
    end
    diff_noisesum_words = ft_math(cfg1,ftDataToPlot.noise_sum,ftDataToPlot.all_words);
    figure('units','normalized','outerposition',[0 0 0.6 0.8]);
    ft_multiplotER(cfg,diff_noisesum_words);
    title('Noise\_sum minus words');
    
    cfg1 = struct();
    cfg1.operation = 'subtract';
    if strcmp(subID,'group')
        cfg1.parameter = 'individual';
    else
        cfg1.parameter = 'avg';
    end
    diff_noisews_words = ft_math(cfg1,ftDataToPlot.noise_ws,ftDataToPlot.all_words);
    figure('units','normalized','outerposition',[0 0 0.6 0.8]);
    ft_multiplotER(cfg,diff_noisews_words);
    title('Noise\_ws minus words');
    
    % ftDataAvg_targ_vs_nontarg = ftDataAvg_targ;
    % ftDataAvg_targ_vs_nontarg.avg = ftDataAvg_targ.avg-ftDataAvg_nontarg.avg;
    % figure(); ft_multiplotER(cfg,ftDataAvg_targ_vs_nontarg);
    
    if strcmp(modality,'eeg')
        % Channel clusters
        cfg = struct();
        cfg.legend = {'target','non-target'};
        cfg.titleStr = 'Target vs non-target';
        plotERPperChannels(cfg,ftDataToPlot.all_targ,ftDataToPlot.all_nontarg);
        
        cfg = struct();
        cfg.legend = {'words','noise\_sum','noise\_ws'};
        cfg.titleStr = 'Words vs noise';
        plotERPperChannels(cfg,ftDataToPlot.all_words,ftDataToPlot.noise_sum,...
                           ftDataToPlot.noise_ws);
    end
end

end

function plotERPperChannels(cfg,varargin)

data = varargin;
chanClusters = {...
    {'EEG012','EEG011','EEG010','EEG022','EEG021','EEG020'},...
    {'EEG014','EEG015','EEG016','EEG024','EEG025','EEG026'};...
    {'EEG033','EEG032','EEG031','EEG044','EEG043','EEG042'},...
    {'EEG035','EEG036','EEG037','EEG046','EEG047','EEG048'};...
    {'EEG071','EEG067','EEG066','EEG055','EEG054','EEG053'},...
    {'EEG073','EEG069','EEG070','EEG057','EEG058','EEG059'}}';    
clusterNames = repmat({'Frontal','Central','Occipital'},2,1);
side = repmat({'Left','Right'},3,1)';
subPlotOrder = [1,2,3,4,5,6];

figure('units','normalized','outerposition',[0 0 0.4 0.8]);
if isfield(cfg,'colormap')
    colormap(cfg.colormap)
end
for iPlot = 1:numel(chanClusters)
    
    ax(iPlot) = subplot(3,2,subPlotOrder(iPlot));
    cfg.colorbar = 'yes';
    cfg.ylim = 'maxabs';
    % cfg.xlim = [-0.1,0.8];
    cfg.channel = chanClusters{iPlot};
    ft_singleplotER(cfg,data{:});
    if ismember(iPlot,[5,6])
        xlabel(side{iPlot});
    end
    if ismember(iPlot,[1,3,5])
        ylabel(clusterNames{iPlot});
    end
    if isfield(cfg,'legend')
        if iPlot == numel(chanClusters)
            legend(cfg.legend,'Location','SouthEast');
        end
    end
    title('');
end
% Setting color limits uniform across subplots
temp = arrayfun(@(x) get(ax(x),'ylim'),1:numel(chanClusters),'UniformOutput',false);
temp = cat(2,temp{:});
ylim = max(abs(min(temp)),abs(max(temp)));
arrayfun(@(x) set(ax(x),'ylim',[-ylim,ylim]),1:numel(chanClusters));

suplabel(cfg.titleStr, 't');

end