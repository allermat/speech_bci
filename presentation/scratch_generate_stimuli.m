cfg = struct('noiseWordSelection',{},'stimulusType',{},'noiseLpCutoff',{},...
             'jitter',{});
cfg(1).noiseWordSelection = 'target';
cfg(1).stimulusType = 'non-pcentred_pilot_2_2';
cfg(1).noiseLpCutoff = 30;
% cfg(2).noiseWordSelection = 'target';
% cfg(2).stimulusType = 'non-pcentred_pilot_2_2';
% cfg(2).noiseLpCutoff = 30;
% cfg(2).jitter = 0.3;
% cfg(3).noiseWordSelection = 'target';
% cfg(3).stimulusType = 'non-pcentred_pilot_2_2';
% cfg(3).noiseLpCutoff = 5;
% cfg(3).jitter = 0.3;
[stim,stimKey] = deal(cell(size(cfg,2),1));
for i = 1:size(cfg,2)
    [stim(i),stimKey(i)] = BCI_generateAllStimuli('999','nRuns',1,'nTrialsPerRun', ...
        1,'randSeed',100,'stimulusType',cfg(i).stimulusType,...
        'noiseWordSelection',cfg(i).noiseWordSelection,...
        'noiseLpCutoff',cfg(i).noiseLpCutoff,...
        'vocodeMethod','STRAIGHT',...
        'saveFile',false);
end

save(fullfile(BCI_setupdir('stimuli'),'stimuli.mat'),'stim')