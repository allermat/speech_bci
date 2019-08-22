% I only take t
layoutTemp = load('/imaging/local/software/fieldtrip/fieldtrip-20160629/template/layout/easycapM1.mat');
layoutTemp = layoutTemp.lay;
layout = layoutTemp;
montage = load('/imaging/local/spm/spm5/EEGtemplates/cbu_meg_70eeg_montage.mat');

layout.pos = montage.Cpos(:,1:70)';
layout.label = strcat('EEG',pad(montage.Cnames(1:70),3,'left','0'));
% shifting positions so Cz is at 0,0 
temp = layout.pos;
for i = 1:2, temp(:,i) = temp(:,i)-temp(34,i); end
% Scaling up a little bit
temp = temp*1.1;
% shifting positions after scaling so electrode locations line up nicely
% with the outline
shift = [-0.02,layoutTemp.pos(35,2)];
for i = 1:2, temp(:,i) = temp(:,i)+shift(1,i); end
layout.pos = temp;
layout.width(71:end) = [];
layout.height(71:end) = [];

figure(); ft_plot_layout(layout);
    
