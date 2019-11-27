function trigDef = generateTrigDef(condDef)

% First defining stimulus triggers
trig = (1:size(condDef,1))';
type = repmat({'stim'},size(condDef,1),1);
trig = cat(1,trig,[10,11,13,20,21,22,23]');
type = cat(1,type,{'trialstart','trialend','respcue'}',...
           repmat({'resp'},4,1));
type = categorical(type);
cond = cat(1,condDef.condition,NaN(7,1));

trigDef = table(trig,type,cond);

% Making sure we don't generate trigger values higher than allowed
maxTrig = 255;
if any(trigDef.trig > maxTrig)
    error('The maximum allowed trigger value is %d',maxTrig);
end

end
