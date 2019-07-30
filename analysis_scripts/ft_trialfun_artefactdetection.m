function [trl,event] = ft_trialfun_artefactdetection(cfg)

% Finding the actual trials in the data based on the specified event values
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
trRespCue = cfg.trialdef.trigdef.trig(cfg.trialdef.trigdef.type == 'respcue');

% Correcting for trigger delay with respect to visual onset
temp = evSamples(ismember(evValues,[trStim',trTrialStart',trRespCue']));
temp = temp+round(cfg.trialdef.trig_audioonset_corr*hdr.Fs);
evSamples(ismember(evValues,[trStim',trTrialStart',trRespCue'])) = temp;

trialStartEvSamples = evSamples(ismember(evValues,trTrialStart));
respCueEvSamples = evSamples(ismember(evValues,trRespCue));

% Generating fake trials of length ~cfg.trialdef.trllength just for the 
% efficient artefact reviewing.
trlLengthSampl = cfg.trialdef.faketrllength*hdr.Fs;

% Number of artificial trials for each run. 
nTrialArtf = ...
    ceil((respCueEvSamples(end)-trialStartEvSamples(1))/trlLengthSampl);

trl = zeros(nTrialArtf,3);

iTrial = 1;

startIdx = trialStartEvSamples(1);

for iTrialArtfPerRun = 1:nTrialArtf
    
    % Marking the beginning and ending samples of trials for artefact
    % reviewing. The offset remains always zero.
    trl(iTrial,1) = startIdx;
    trl(iTrial,2) = startIdx+(trlLengthSampl-1);
    startIdx = startIdx+trlLengthSampl;
    iTrial = iTrial+1;
    
end
% Making sure we don't run over the file
if trl(end,2) > respCueEvSamples(end)
    trl(end,2) = respCueEvSamples(end);
end

end