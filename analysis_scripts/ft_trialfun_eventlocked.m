function [trl,event] = ft_trialfun_eventlocked(cfg)
% Trial definition function to be used with FieldTrip's ft_redefinetrial
% 
% Based on example FieldTrip trialfunction 
% Copyrigth (C) 2019, Mate Aller

hdr = ft_read_header(cfg.headerfile);
event = ft_read_event(cfg.headerfile);
evValues = [event.value]';
evTypes = {event.type}';
evSamples = [event.sample]';

isReqType = strcmp(evTypes,cfg.trialdef.eventtype);
evValues = evValues(isReqType);
evSamples = evSamples(isReqType);

% trigger values
trStim = cfg.trialdef.trigdef.trig(ismember(cfg.trialdef.trigdef.type,{'stim'}));
trTrialStart = cfg.trialdef.trigdef.trig(cfg.trialdef.trigdef.type == 'trialstart');

% Correcting for trigger delay with respect to visual onset
temp = evSamples(ismember(evValues,[trStim',trTrialStart']));
temp = temp+round(cfg.trialdef.trig_audioonset_corr*hdr.Fs);
evSamples(ismember(evValues,[trStim',trTrialStart'])) = temp;

trialStartEvSamples = evSamples(ismember(evValues,trTrialStart));
stimEvSamples = evSamples(ismember(evValues,trStim));
stimEvValues = evValues(ismember(evValues,trStim));

nStimuli = numel(stimEvSamples);
[begSamples,endSamples] = deal(NaN(nStimuli,1));
[run,iTrialInRun,iStimInTrial,cond] = deal(NaN(nStimuli,1));

actRunInFile = 1;
actTrialInFile = 1; 
actTrialInRun = 1;
actStimInTrial = 1;

for i = 1:nStimuli
    
    % Find actual stimulus event sample
    actStimEvSampl = stimEvSamples(i);
    % Updating actual trial in the file
    if actTrialInFile ~= find(actStimEvSampl > trialStartEvSamples,1,'last')
        actTrialInFile = find(actStimEvSampl > trialStartEvSamples,1,'last');
        actTrialInRun = actTrialInRun + 1;
        actStimInTrial = 1;
    end
    
    % Beginning and ending samples of stimulus
    begSamples(i) = actStimEvSampl-round(cfg.trialdef.prestim*hdr.Fs);
    endSamples(i) = actStimEvSampl+round(cfg.trialdef.poststim*hdr.Fs);
    % Run number
    run(i) = cfg.trialdef.fileSpec.iRunOverall{:}(actRunInFile);
    % Serial number of trial in the run
    iTrialInRun(i) = actTrialInRun;
    % Stimulus condition
    cond(i) = cfg.trialdef.trigdef.cond(...
        ismember(cfg.trialdef.trigdef.trig,stimEvValues(i)));
    % Stimulus in trial
    iStimInTrial(i) = actStimInTrial;
    actStimInTrial = actStimInTrial+1;
end

% Creating the offset array
offset = -round(cfg.trialdef.prestim*hdr.Fs)*ones(size(begSamples));

trl = [begSamples,endSamples,offset,run,iTrialInRun,iStimInTrial,cond];

end