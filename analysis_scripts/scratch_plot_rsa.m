%% Plotting RSA results
if strcmp(analysis,'noise')
    % Plotting noise
    if poolOverTime
        tickLabels = condDef.wordId(ismember(condDef.condition,conditions));
        plotRDM(distAll,tickLabels,3);
        title(sprintf('Decoding target word from noise\npooled over time'));
    else
        % Time resolved figure
        figure;
        hold on;
        plot(-100:4:500, squeeze(nanmean(nanmean(distBetween, 1), 2)), 'linewidth', 2);
        plot(-100:4:500, squeeze(nanmean(nanmean(distWithin, 1), 2)), 'linewidth', 2);
        xlim([-100 500]);
        xlabel('Time [ms]');
        ylabel('Crossnobis distance');
        legend('Between', 'Within', 'location', 'NorthWest');
        title(sprintf('Decoding target word from noise\ntime resolved'));
        
        % RDM figure
        tickLabels = cellstr(targets);
        plotRDM(mean(distAll,3),tickLabels,[]);
        title(sprintf('Decoding target word from noise\nmean across time'));
    end
else
    % Plotting words
    if poolOverTime
        tickLabels = condDef.wordId(ismember(condDef.condition,conditions));
        plotRDM(distAll,tickLabels,3);
        title(sprintf('Decoding presented word\npooled over time'));
    else
        % Time resolved figure
        figure;
        hold on;
        plot(-100:4:500, squeeze(nanmean(nanmean(distBetween, 1), 2)), 'linewidth', 2);
        plot(-100:4:500, squeeze(nanmean(nanmean(distWithin, 1), 2)), 'linewidth', 2);
        xlim([-100 500]);
        xlabel('Time [ms]');
        ylabel('Crossnobis distance');
        legend('Between', 'Within', 'location', 'NorthWest');
        title(sprintf('Decoding presented word\ntime resolved'));

        % RDM figure
        temp = cellfun(@(x) upper(condDef.wordId{condDef.condition == x}(1)),...
                       table2cell(conditions),'UniformOutput',false);
        tickLabels = strcat(temp(:,1),'\_',temp(:,2));
        plotRDM(mean(distAll,3),tickLabels,3);
        title(sprintf('Decoding presented word\nmean across time'));
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