function BCI_generateSubjectSpec(varargin)
% Creates the structure array with subject specific info. 
p = inputParser;

addOptional(p,'update',false,@islogical)

parse(p,varargin{:});

update = p.Results.update;

s = subjSpec();
%%
subID = 'meg19_0233';
if ~s.subjPresent(subID) || update
    % Subject ID
    if ~update, s.addSubj(subID); end
    % MEG files to be included
    fileName = {...
        'run1'
        'run2'
        'run3'
        'run4'
        'run5'};
    % The number of sessions started in the files
    nRunsInFile = ones(size(fileName));
    % The serial number within the files of the runn(s) to be excluded
    exclude = num2cell(NaN(size(fileName)));
    % The overall running index of not excluded runs within the files
    % accounting for the behavioural only first day as well. 
    iRunOverall = num2cell(1:numel(fileName))';
    s.addField(subID,'meg_files',table(fileName,nRunsInFile,exclude,iRunOverall));
    % Pre-processing parameters that can change individually
    s.addField(subID,'preproc_param',...
        orderfields(struct('cutoff_zval',10,'hp_freq',0.1)));
    % Notes
    s.addField(subID,'notes',sprintf(''));
end

%%
subID = 'meg19_0239';
if ~s.subjPresent(subID) || update
    % Subject ID
    if ~update, s.addSubj(subID); end
    % MEG files to be included
    fileName = {...
        'run1'
        'run2'
        'run3'
        'run4'
        'run5'
        'run6'};
    % The number of sessions started in the files
    nRunsInFile = ones(size(fileName));
    % The serial number within the files of the runn(s) to be excluded
    exclude = num2cell(NaN(size(fileName)));
    % The overall running index of not excluded runs within the files
    % accounting for the behavioural only first day as well. 
    iRunOverall = num2cell(1:numel(fileName))';
    s.addField(subID,'meg_files',table(fileName,nRunsInFile,exclude,iRunOverall));
    % Pre-processing parameters that can change individually
    s.addField(subID,'preproc_param',...
        orderfields(struct('cutoff_zval',10,'hp_freq',0.1)));
    % Notes
    s.addField(subID,'notes',sprintf(''));
end

%%
subID = 'meg19_0251';
if ~s.subjPresent(subID) || update
    % Subject ID
    if ~update, s.addSubj(subID); end
    % MEG files to be included
    fileName = {...
        'run1'
        'run2'
        'run3'
        'run4'
        'run5'
        'run6'};
    % The number of sessions started in the files
    nRunsInFile = ones(size(fileName));
    % The serial number within the files of the runn(s) to be excluded
    exclude = num2cell(NaN(size(fileName)));
    % The overall running index of not excluded runs within the files
    % accounting for the behavioural only first day as well. 
    iRunOverall = num2cell(1:numel(fileName))';
    s.addField(subID,'meg_files',table(fileName,nRunsInFile,exclude,iRunOverall));
    % Pre-processing parameters that can change individually
    s.addField(subID,'preproc_param',...
        orderfields(struct('cutoff_zval',10,'hp_freq',0.1)));
    % Notes
    s.addField(subID,'notes',sprintf(''));
end

%% Checking data for consistency
subjInfo = s.getAllSpec;
for i = 1:size(subjInfo,2)
    actFileSpec = subjInfo(i).meg_files;
    
%     % Check iRunOverall
%     actIrunOverall = actFileSpec.iRunOverall;
%     if size(horzcat(actIrunOverall{:}),2) ~= 40
%         warning('iRunOverall for subject %d does not match the expected value!',...
%             subjInfo(i).subID);
%     end
    
    % Check if nRunsInFile and iRunOverall match
    for j = 1:size(actFileSpec,1)
        actNruns = actFileSpec.nRunsInFile(j);
        if isnan(actFileSpec.exclude{j})
            nExclude = 0;
        else
            nExclude = size(actFileSpec.exclude{j},2);
        end
        if actNruns-nExclude ~= size(actFileSpec.iRunOverall{j},2)
            error('nRunsInFile and iRunOverall don''t match for subject %d',...
                subjInfo(i).subID);
        end
    end
    
end


end

