% Get subject ID from folder name
temp = strsplit(pwd,'/');
subID = temp{end};
% Load data files
listing = dir;
fileNames = {listing.name}';
fileNames = fileNames(~cellfun(@isempty,regexp(fileNames,'subj[0-9]{3}_run[0-9]_.*.mat','once')));

for iFile = 1:numel(fileNames)
    load(fileNames{iFile});
    % Replace subID
    data.Subject = repmat({subID},size(data,1),1);
    % Save with new filename
    temp = regexp(fileNames(iFile),'\w*(_run[0-9]_.*.mat)','tokens','once');
    newFileName = [subID,temp{:}{:}];
    save(newFileName,'data');
end