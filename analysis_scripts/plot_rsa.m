function plot_rsa(subID_list,matchStr)
% Function for plotting RSA results

for iSub = 1:numel(subID_list)
    
    subID = subID_list{iSub};
    
    saveDf = cd(fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subID_list{iSub}),'RSA'));
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
    if ismember(analysis,{'noise_sum','noise_ws'})
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
            xlim([-100 500]);
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
        
        % Target condition independent of word identity
        % Meaning of indices: 1 - N.A., 2 - within, 3 - between
        w = 2*ones(nCond);
        b = 3*ones(nCond);
        models{1} = [w,b,b,b,b,b;...
                     b,w,b,b,b,b;...
                     b,b,w,b,b,b;...
                     b,b,b,w,b,b;...
                     b,b,b,b,w,b;...
                     b,b,b,b,b,w];
        %     figure(); image(models{1}); colormap(cmap);
        
        % Word identity independent of target condition
        c = eye(nCond);
        c(c == 1) = 2;
        c(c == 0) = 3;
        models{2} = repmat(c,nCond,nCond);
        %     figure(); image(models{2}); colormap(cmap);
        
        % Target condition, same word
        % Meaning of indices: 1 - N.A., 2 - within, 3 - between
        [w,b] = deal(eye(nCond));
        w(w == 1) = 2;
        b(b == 1) = 3;
        models{3} = [w,b,b,b,b,b;...
                     b,w,b,b,b,b;...
                     b,b,w,b,b,b;...
                     b,b,b,w,b,b;...
                     b,b,b,b,w,b;...
                     b,b,b,b,b,w];
        %     figure(); image(models{3}); colormap(cmap);
        
        % Word identity same target condition
        n = ones(nCond);
        models{4} = [c,n,n,n,n,n;...
                     n,c,n,n,n,n;...
                     n,n,c,n,n,n;...
                     n,n,n,c,n,n;...
                     n,n,n,n,c,n;...
                     n,n,n,n,n,c];
        %     figure(); image(models{4}); colormap(cmap);
        
        % Target condition, different word
        % Meaning of indices: 1 - N.A., 2 - within, 3 - between
        [w,b] = deal(eye(nCond));
        w(w == 0) = 2;
        b(b == 0) = 3;
        models{5} = [w,b,b,b,b,b;...
                     b,w,b,b,b,b;...
                     b,b,w,b,b,b;...
                     b,b,b,w,b,b;...
                     b,b,b,b,w,b;...
                     b,b,b,b,b,w];
        %     figure(); image(models{5}); colormap(cmap);
        
        % Word identity different target condition
        models{6} = [n,c,c,c,c,c;...
                     c,n,c,c,c,c;...
                     c,c,n,c,c,c;...
                     c,c,c,n,c,c;...
                     c,c,c,c,n,c;...
                     c,c,c,c,c,n];
        %     figure(); image(models{6}); colormap(cmap);
        
        % P3 response: 1 = N.A; 2 = +/-; 3 = -/-; 4 = +/+
        temp = 3*ones(size(conditions,1));
        temp(:,1:(nCond+1):size(conditions,1)) = 2;
        temp(1:(nCond+1):size(conditions,1),:) = 2;
        temp(1:(nCond+1):size(conditions,1),...
             1:(nCond+1):size(conditions,1)) = 4;
        models{7} = temp;
        %     figure(); image(models{7}); colormap(cmap);
        
        % P3 | same word
        temp = models{7};
        temp(~logical(repmat(eye(nCond),nCond,nCond))) = 1;
        models{8} = temp;
        
        % P3 | same target
        mask = [ones(nCond),repmat(zeros(nCond),1,5);...
                zeros(nCond),ones(nCond),repmat(zeros(nCond),1,4);...
                repmat(zeros(nCond),1,2),ones(nCond),repmat(zeros(nCond),1,3);...
                repmat(zeros(nCond),1,3),ones(nCond),repmat(zeros(nCond),1,2);...
                repmat(zeros(nCond),1,4),ones(nCond),zeros(nCond);...
                repmat(zeros(nCond),1,5),ones(nCond)];
        temp = models{7};
        temp(~logical(mask)) = 1;
        models{9} = temp;
        
        % P3 | different word
        temp = models{7};
        temp(~logical(repmat(eye(nCond),nCond,nCond))) = 1;
        models{10} = temp;
        %     figure(); image(models{8}); colormap(cmap);
        
        % P3 | different target
        temp = models{7};
        temp(logical(mask)) = 1;
        models{11} = temp;
        
        titles = {'Target condition','Word identity', ...
                  'Target condition | same word','Word identity | same target',...
                  'Target condition | different word','Word identity | different target',...
                  'P3 response',...
                  'P3 response | same word','P3 response | same target'...
                  'P3 response | different word','P3 response | different target'};  
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
            set(gcf,'Units','Normalized','OuterPosition',[0,0.2,0.5,0.75]);
            for iModel = 1:6
                ax(iModel) = subplot(3,2,iModel);
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
                xlim([-100 500]);
                xlabel('Time [ms]');
                ylabel('Crossnobis distance');
                title(titles{iModel});
                % ax2(i) = axes('Position',[0.2,0.7,0.2,0.2]);
                pos = [ax(iModel).Position(1:2)+ax(iModel).Position(3:4).*[0.02,0.5],0.08,0.08];
                ax2 = axes('Position',pos);
                image(ax2,models{iModel}); colormap(ax2,cmap2);
                set(ax2,'XTick',[],'YTick',[]);
                axis(ax2,'square');
            end
            
            figure();
            set(gcf,'Units','Normalized','OuterPosition',[0,0.2,0.5,0.75]);
            for iModel = 7:11
                iSubPlot = [1,3:6];
                ax(iModel) = subplot(3,2,iSubPlot(iModel-6));
                hold on;
                if strcmp(subID,'group')
                    for j = 2:4
                        h(j-1) = shadedErrorBar(time,...
                            cellfun(@(x) mean(x(models{iModel} == j)),temp),...
                            sqrt(cellfun(@(x) mean(x(models{iModel} == j)),temp_var))./sqrt(nSubj),...
                            {'linewidth',2,'Color',cmap2(j,:)},1);
                    end
                    if iModel == 7
                        legend([h.mainLine],'P3+ vs. P3-','P3- vs. P3-',...
                            'P3+ vs. P3+','location','SouthEast');
                    end
                else
                    for j = 2:4
                        plot(time,cellfun(@(x) mean(x(models{iModel} == j)),temp),...
                            'linewidth',2,'Color',cmap2(j,:));
                    end
                    if iModel == 7
                        legend('P3+ vs. P3-','P3- vs. P3-','P3+ vs. P3+',...
                               'location','SouthEast');
                    end
                end
                xlim([-100 500]);
                xlabel('Time [ms]');
                ylabel('Crossnobis distance');
                title(titles{iModel});
                pos = [ax(iModel).Position(1:2)+ax(iModel).Position(3:4).*[0.02,0.5],0.08,0.08];
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
        wordId{end-1} = 'z';
        wordId{end} = 'x';
        if ismember(timeMode,'pooled')
            temp = cellfun(@(x) upper(wordId{condDef.condition == x}(1)),...
                table2cell(conditions),'UniformOutput',false);
            tickLabels = strcat(temp(:,1),'\_',temp(:,2));
            plotRDM(distAll,tickLabels,nCond);
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
            xlim([-100 500]);
            xlabel('Time [ms]');
            ylabel('Crossnobis distance');
            
            title(sprintf('Decoding presented word and noise\ntime resolved'));
            
            % RDM figure
            
            temp = cellfun(@(x) upper(wordId{condDef.condition == x}(1)),...
                table2cell(conditions),'UniformOutput',false);
            tickLabels = strcat(temp(:,1),'\_',temp(:,2));
            plotRDM(mean(distAll,3),tickLabels,nCond);
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