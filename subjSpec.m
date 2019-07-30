classdef subjSpec < handle
    
    properties (SetAccess = private)
        subjInfo
        nSubj
        validFields = {'subID','meg_files','preproc_param','notes'};
        savePath = fileparts(mfilename('fullpath'));
        fileName = 'subj_spec.mat';
    end
    
    methods
        
        function obj = subjSpec()
        % Class for subject info results
        % 
        % DETAILS: 
        %   This class implements all methods for interacting with
        %   the subject specification structure. 
        % USAGE: 
        %   obj = subjSpec
        % INPUT: - 
        % OUTPUT: 
        %   obj (object): subjSpec object
        
        % Copyright(C) 2019, Mate Aller
        % allermat@gmail.com
        
        % Initializing variables
        if exist(obj.fileName,'file')
            obj.subjInfo = load(obj.fileName);
            obj.subjInfo = obj.subjInfo.subjInfo;
            obj.nSubj = size(obj.subjInfo,2);
        else
            obj.subjInfo = struct();
            obj.nSubj = 0;
            obj.save;
            fprintf([obj.fileName, ' not found, creating blank file\n']);
        end
        
        end
        
        
        function addSubj(obj,subID)
        % Method for adding a subject
        p = inputParser;
        addRequired(p,'obj');
        addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
        parse(p,obj,subID);
        obj = p.Results.obj;
        subID = p.Results.subID;
        
        % Check if subject is present
        if obj.subjPresent(subID)
            error('subjSpec:addSubj:subjectExists', ...
                  'This subject already exist!');
        end
        
        obj.nSubj = obj.nSubj+1;
        obj.subjInfo(obj.nSubj).subID = subID;
        % Initializing fields
        obj.addField(subID,'meg_files',table);
        obj.addField(subID,'preproc_param',table);
        obj.addField(subID,'notes',table);
        obj.save;
        end
            
        
        function addField(obj,subID,fieldName,val)
        % Method for adding data field to a subject
        p = inputParser;
        addRequired(p,'obj');
        addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
        addRequired(p,'fieldName',@(x) ismember(x,obj.validFields));
        addRequired(p,'val');
        parse(p,obj,subID,fieldName,val);
        obj = p.Results.obj;
        subID = p.Results.subID;
        fieldName = p.Results.fieldName;
        val = p.Results.val;
        
        % If subject is not in the dataset, add them first
        if ~subjPresent(obj,subID)
            addSubj(obj,subID);
        end
        % Add field to sujbect
        obj.subjInfo(ismember({obj.subjInfo.subID},subID)).(fieldName) = val;
        obj.save;
        end
        
        
        function val = subjPresent(obj,subID)
        % Mothod for checking if a subject is part of the dataset
        p = inputParser;
        addRequired(p,'obj');
        addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
        parse(p,obj,subID);
        obj = p.Results.obj;
        subID = p.Results.subID;
        if obj.nSubj == 0 || ~ismember(subID,{obj.subjInfo.subID})
            val = false;
        elseif ismember(subID,{obj.subjInfo.subID})
            val = true;
        end
        
        end
                
        function val = getField(obj,subID,fieldName)
        % Method for accessing a field value of a subject
        p = inputParser;
        addRequired(p,'obj');
        addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
        addRequired(p,'fieldName',@(x) ismember(x,obj.validFields));
        parse(p,obj,subID,fieldName);
        obj = p.Results.obj;
        subID = p.Results.subID;
        fieldName = p.Results.fieldName;
        
        if ~subjPresent(obj,subID)
            warning('The specified subject is not part of the dataset');
            val = [];
        elseif ~ismember(fieldName,fieldnames(obj.subjInfo))
            warning('The specified field is not part of the dataset');
            val = [];
        else
            val = obj.subjInfo(ismember({obj.subjInfo.subID},subID)).(fieldName);
        end
        
        end
        
        
        function val = getAllSpec(obj)
        % Method for accessing all subject specifications at once
        val = obj.subjInfo;
        end
        
        
        function deleteSubj(obj,subID)
        p = inputParser;
        addRequired(p,'obj');
        addRequired(p,'subID',@(x)validateattributes(x,{'char'},{'nonempty'}));
        parse(p,obj,subID);
        obj = p.Results.obj;
        subID = p.Results.subID;
        
        if ~subjPresent(obj,subID)
            warning('The specified subject is not part of the dataset');
        else
            warning(['You have deleted a subject, changes are not ' ...
                     'yet saved to disk. Plese call the save method ' ...
                     'to save the changes! ']);
            obj.subjInfo(ismember({obj.subjInfo.subID},subID)) = [];
            obj.nSubj = obj.nSubj-1;
        end
        
        end
        
        
        function save(obj)
        % Method for saving data on disk
        subjInfo = obj.subjInfo; %#ok
        save(fullfile(obj.savePath,obj.fileName),'subjInfo');
        end
    
    end
    
end