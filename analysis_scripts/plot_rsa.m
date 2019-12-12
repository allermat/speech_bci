function plot_rsa(subID_list,matchStr,varargin)
% Function for plotting RSA results

% Parsing input
p = inputParser;

addRequired(p,'subID_list',@(x) validateattributes(x,{'cell'},...
            {'vector','nonempty'}));
addRequired(p,'matchStr',@(x) validateattributes(x,{'char'},{'nonempty'}));
addOptional(p,'subFolder','',@(x) validateattributes(x,{'char'},{'nonempty'}));

parse(p,subID_list,matchStr,varargin{:});

subID_list = p.Results.subID_list;
matchStr = p.Results.matchStr;
subFolder = p.Results.subFolder;

for iSub = 1:numel(subID_list)
    
    subID = subID_list{iSub};
    
    if isempty(subFolder)
        saveDf = cd(fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subID_list{iSub}),'RSA'));
    else
        saveDf = cd(fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subID_list{iSub}),...
                    'RSA',subFolder));
    end
    fileList = dir('*.mat');
    fileList = {fileList.name}';
    matchID = ~cellfun(@isempty,regexp(fileList,matchStr));
    if sum(matchID) == 0
        warning('No file, skipping subject %s! ',subID_list{iSub});
        cd(saveDf);
        continue;
    elseif sum(matchID) > 1
        warning('More files than needed, skipping subject %s! ',subID_list{iSub});
        cd(saveDf);
        continue;
    else
        fileName = fileList{matchID};
        load(fileName);
        cd(saveDf);
    end
    
    % Taking care of variables from older version of the script
    if exist('timeLabel','var')
        time = timeLabel;
    elseif ~exist('time','var')
        time = -100:4:500;
    end
    
    if ~exist('timeMode','var')
        if poolOverTime 
            timeMode = 'pooled';
        else
            timeMode = 'resolved';
        end
    end
    
    if ~exist('subID','var')
        subID = subID_list{iSub};
    end
    % Mapping of colors
    % cmap = [0,1,0;1,0,0;0,0,1];
    cmap2 = [77,175,74;228,26,28;55,126,184;152,78,163]./255;
    
    nCond = numel(condSelection);
    % Plotting RSA results
    if strcmp(analysis,'noise')
        % Plotting noise
        if ismember(timeMode,'pooled')
            tickLabels = condDef.wordId(ismember(condDef.stimType,'word'));
            plotRDM(distAll,tickLabels,[]);
            title(sprintf('Decoding target word from noise\npooled over time'));
        else
            % Time resolved figure
            figure;
            hold on;
            if strcmp(subID,'group')
                h1 = shadedErrorBar(time,squeeze(nanmean(nanmean(distBetween,1),2)),...
                                    sqrt(squeeze(nanmean(nanmean(distBetween_var,1),2)))./sqrt(nSubj),...
                                    {'linewidth',2,'Color',cmap2(3,:)},1);
                h2 = shadedErrorBar(time,squeeze(nanmean(nanmean(distWithin,1),2)),...
                                    sqrt(squeeze(nanmean(nanmean(distWithin_var,1),2)))./sqrt(nSubj),...
                                    {'linewidth',2,'Color',cmap2(2,:)},1);
                legend([h1.mainLine,h2.mainLine],'Between','Within',...
                       'location','NorthWest');
            else
                plot(time, squeeze(nanmean(nanmean(distBetween, 1), 2)), 'linewidth', 2);
                plot(time, squeeze(nanmean(nanmean(distWithin, 1), 2)), 'linewidth', 2);
                legend('Between', 'Within', 'location', 'NorthWest');
            end
            % xlim([-100 500]);
            xlabel('Time [ms]');
            ylabel('Crossnobis distance');
            title(sprintf('Decoding target word from noise\ntime resolved'));
            
            % RDM figure
            tickLabels = condDef.wordId(ismember(condDef.stimType,'word'));
            plotRDM(mean(distAll,3),tickLabels,[]);
            title(sprintf('Decoding target word from noise\nmean across time'));
        end
    elseif strcmp(analysis,'words')
        % Plotting words
        
        % Word identity
        c = eye(3);
        c(c == 1) = 2;
        c(c == 0) = 3;
        models{1} = c;
        %     figure(); image(models{2}); colormap(cmap);
        
        titles = {'Word identity'};  
        if ismember(timeMode,'pooled')
            temp = cellfun(@(x) upper(condDef.wordId{condDef.condition == x}(1)),...
                table2cell(conditions),'UniformOutput',false);
            tickLabels = strcat(temp(:,1),'\_',temp(:,2));
            plotRDM(distAll,tickLabels,[]);
            title(sprintf('Decoding presented word\npooled over time'));
        else
            % Time resolved figures
            s = size(distAll);
            temp = squeeze(mat2cell(distAll,s(1),s(2),ones(s(3),1)));
            if strcmp(subID,'group')
                temp_var = squeeze(mat2cell(distAll_var,s(1),s(2),ones(s(3),1)));
            end
            figure();
            % set(gcf,'Units','Normalized','OuterPosition',[0,0.2,0.5,0.75]);
            for iModel = 1:numel(models)
                % ax(iModel) = subplot(3,2,iModel);
                ax(iModel) = axes;
                hold on;
                if strcmp(subID,'group')
                    h1 = shadedErrorBar(time,...
                            cellfun(@(x) mean(x(models{iModel} == 3)),temp),...
                            sqrt(cellfun(@(x) mean(x(models{iModel} == 3)),temp_var))./sqrt(nSubj),...
                            {'linewidth',2,'Color',cmap2(3,:)},1);
                    h2 = shadedErrorBar(time,...
                            cellfun(@(x) mean(x(models{iModel} == 2)),temp),...
                            sqrt(cellfun(@(x) mean(x(models{iModel} == 2)),temp_var))./sqrt(nSubj),...
                            {'linewidth',2,'Color',cmap2(2,:)},1);
                    if iModel == 1
                        legend([h1.mainLine,h2.mainLine],'Between','Within',...
                            'location','SouthEast');
                    end
                else
                    plot(time,cellfun(@(x) mean(x(models{iModel} == 3)),temp),...
                        'linewidth',2,'Color',cmap2(3,:));
                    plot(time,cellfun(@(x) mean(x(models{iModel} == 2)),temp),...
                        'linewidth',2,'Color',cmap2(2,:));
                    if iModel == 1
                        legend('Between', 'Within', 'location', 'SouthEast');
                    end
                end
                % xlim([-100 500]);
                xlabel('Time [ms]');
                ylabel('Crossnobis distance');
                title(titles{iModel});
                % ax2(i) = axes('Position',[0.2,0.7,0.2,0.2]);
                pos = [ax(iModel).Position(1:2)+ax(iModel).Position(3:4).*[0.04,0.7],0.2,0.2];
                ax2 = axes('Position',pos);
                image(ax2,models{iModel}); colormap(ax2,cmap2);
                set(ax2,'XTick',[],'YTick',[]);
                axis(ax2,'square');
            end
            
            YLims = cat(1,ax.YLim);
            for i = 1:numel(models)
                ylim(ax(i),[min(YLims(:,1)),max(YLims(:,2))]);
            end
            %         suplabel(strrep(subID,'_','\_'),'t',[.08 .08 .84 .84]);
            % RDM figure
            temp = cellfun(@(x) upper(condDef.wordId{condDef.condition == x}(1)),...
                table2cell(conditions),'UniformOutput',false);
            tickLabels = strcat(temp(:,1),'\_',temp(:,2));
            plotRDM(mean(distAll,3),tickLabels,nCond);
            title(sprintf('Decoding presented word\nmean across time'));
        end
        
    elseif strcmp(analysis,'all')
        % Plotting words
        wordId = condDef.wordId;
        wordId{end} = 'x';
        if ismember(timeMode,'pooled')
            temp = cellfun(@(x) upper(wordId{condDef.condition == x}(1)),...
                table2cell(conditions),'UniformOutput',false);
            tickLabels = strcat(temp(:,1),'\_',temp(:,2));
            plotRDM(distAll,tickLabels,2);
            title(sprintf('Decoding presented word and noise\npooled over time'));
        else
            % Time resolved figure
            figure;
            hold on;
            if strcmp(subID,'group')
                h1 = shadedErrorBar(time,squeeze(nanmean(nanmean(distBetween,1),2)),...
                                    sqrt(squeeze(nanmean(nanmean(distBetween_var,1),2)))./sqrt(nSubj),...
                                    {'linewidth',2,'Color',cmap2(3,:)},1);
                h2 = shadedErrorBar(time,squeeze(nanmean(nanmean(distWithin,1),2)),...
                                    sqrt(squeeze(nanmean(nanmean(distWithin_var,1),2)))./sqrt(nSubj),...
                                    {'linewidth',2,'Color',cmap2(2,:)},1);
                legend([h1.mainLine,h2.mainLine],'Between','Within',...
                       'location','NorthWest');
            else
                plot(time, squeeze(nanmean(nanmean(distBetween, 1), 2)), 'linewidth', 2);
                plot(time, squeeze(nanmean(nanmean(distWithin, 1), 2)), 'linewidth', 2);
                legend('Between', 'Within', 'location', 'NorthWest');
            end
            % xlim([-100 500]);
            xlabel('Time [ms]');
            ylabel('Crossnobis distance');
            
            title(sprintf('Decoding presented word and noise\ntime resolved'));
            
            % RDM figure
            
            temp = cellfun(@(x) upper(wordId{condDef.condition == x}(1)),...
                table2cell(conditions),'UniformOutput',false);
            tickLabels = strcat(temp(:,1),'\_',temp(:,2));
            plotRDM(mean(distAll,3),tickLabels,2);
            title(sprintf('Decoding presented word and noise\nmean across time'));
        end
    end
end

end

% % Plotting number of noise trials per target
% clear g
% g(1,1) = gramm('x',temp.Fun_target,'y',temp.GroupCount,'color',temp.iRun);
% g(1,2) = gramm('x',temp.iRun,'y',temp.GroupCount,'color',temp.Fun_target);
% %Jittered scatter plot
% g(1,1).geom_jitter('width',0.4,'height',0);
% g(1,1).set_title('Noise trials per target');
% g(1,1).set_names('x','Target word','y','Number of noise trials',...
%                  'color','Run number');
% 
% g(1,2).geom_jitter('width',0.4,'height',0);
% g(1,2).set_title('Noise trials per target');
% g(1,2).set_names('x','Run number','y','Number of noise trials',...
%                  'color','Target word');
% figure();
% g.draw();