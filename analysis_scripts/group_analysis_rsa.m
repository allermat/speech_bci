function group_analysis_rsa()

s = subjSpec;
subjList = sort({s.subjInfo.subID})';

temp = dir(fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subjList{1}),'RSA','*.mat'));
fileNames = {temp.name}';
fieldsToKeep = {'analysis','channel','condDef','conditions','condSelection',...
                'poolOverTime','timeLabel','timeMode'};

for i = 1:numel(fileNames)
    
    filePathList = collectFiles(subjList,fileNames{i},1);
    dataLoaded = cellfun(@load,filePathList);
    
    tempFields = fieldnames(dataLoaded);
    dataToSave = rmfield(dataLoaded(1),tempFields(~ismember(tempFields,fieldsToKeep)));
    dataToSave.subID = 'group';
    dataToSave.nSubj = numel(dataLoaded);
    dimToCat = ndims(dataLoaded(1).distAll)+1;
    
    dataToSave.distAll = nanmean(cat(dimToCat,dataLoaded.distAll),dimToCat);
    dataToSave.distAll_var = nanvar(cat(dimToCat,dataLoaded.distAll),0,dimToCat);
    dataToSave.distWithin = nanmean(cat(dimToCat,dataLoaded.distWithin),dimToCat);
    dataToSave.distWithin_var = nanvar(cat(dimToCat,dataLoaded.distWithin),0,dimToCat);
    dataToSave.distBetween = nanmean(cat(dimToCat,dataLoaded.distBetween),dimToCat);
    dataToSave.distBetween_var = nanvar(cat(dimToCat,dataLoaded.distBetween),0,dimToCat);
    
    savePath = fullfile(BCI_setupdir('analysis_meg_sub_mvpa','group'),...
                        'RSA',fileNames{i});
    save(savePath,'-struct','dataToSave');
end

end

function filePathList = collectFiles(subjList,fileMatchStr,nFilesExpected)

filePathList = {};
index = 1;
for i = 1:size(subjList,1)
    saveDf = cd(fullfile(BCI_setupdir('analysis_meg_sub_mvpa',subjList{i}),'RSA'));
    fileList = dir('*.mat');
    fileList = {fileList.name}';
    matchID = ~cellfun(@isempty,regexp(fileList,fileMatchStr));
    if sum(matchID) == 0
        warning('No file, skipping subject %s! ',subjList{i});
        cd(saveDf);
        continue;
    elseif sum(matchID) > nFilesExpected
        warning('More files than needed, skipping subject %s! ',subjList{i});
        cd(saveDf);
        continue;
    else
        fileName = fileList(matchID);
        if iscolumn(fileName)
            fileName = fileName';
        end
    end
    temp = cellfun(@fullfile,repmat({pwd},size(fileName)),fileName,'UniformOutput',false);
    filePathList = cat(1,filePathList,temp);
    index = index + 1;
    cd(saveDf);
end

if isrow(filePathList)
    filePathList = filePathList';
end

end