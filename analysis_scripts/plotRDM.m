function plotRDM(RDM,tickLabels,grid)

% Average across time figure
figure();
imagesc(RDM);
colormap(magma);
c = colorbar;
c.Label.String = 'Crossnobis distance';
% Adding grid if necessary
if ~isempty(grid)
    % Computing grid line coordinates
    width = size(RDM,1);
    x = (0:round(width/grid):width)+0.5;
    x([1,end]) = [];
    x = repmat(x,2,1);
    y = repmat([0,width+0.5]',1,size(x,2));
    % Drawing vertical grid lines
    line(x,y,'Color','w','LineWidth',1.5);
    % Drawing horizontal grid lines
    line(y,x,'Color','w','LineWidth',1.5);
end
set(gca,'XTick',1:numel(tickLabels),'YTick',1:numel(tickLabels));
set(gca,'XTickLabel',tickLabels,'YTickLabel',tickLabels)

axis square

end