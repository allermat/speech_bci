% Maxfilter 2.2 Matlab script for AD project (R Henson Jan 2013)
%
% This version has three options for running on our Compute machines, based
% on setting of ParType variable below: 0 = run on Login in serial; 1 = run
% one Compute core (using spmd); 2 = run on multiple Compute cores
% (using parfor) - with one core per subject (though could switch parfor
% loop across experiments if running one subject (NB: cannot parfor across
% runs, because they depend on same origin fitting)
%
% Note that have turned off "movecomp" option via "mvcomp_fail" matrix, because
% this caused apparent random MF2.2 crashes for the pilot subject. Could
% set to 0 for next subject, in case specific to pilot.
%
% This version does 2-3 steps, with 1-2 outputs:
%
%   1. SSS with autobad on, to detect bad channels and write out move parameters
%   2. tSSS, downsample by factor 4 (250Hz), and trans to first file if multiple runs
%   3. trans to default helmet position (if flag below set) (note trans'ing
%   direct to default space without realigning runs within subject does not
%   work so well)

clear  % May not want/need to!

es_batch_init; % es edit

dat_wd = rawpathstem;
bas_wd = pathstem; % <-- change to yours

groups = {
    ''
    };

cbu_codes{1} = subjects;

% Experiments
expts = {'';
    };

% Run labels per experiment (not actually needed with new filenames from Pilot2 onwards)
% runs{1} = {'run1' 'run2' 'run3' 'run4' 'run5' 'run6'};
runs{1} = blocksin{1};
runsout{1} = blocksout{1};
% note by es- 'trans_run' variable not actually used in script (even the
% original version from wiki). So I've edited script to trans runs to first file
% specified (if 'TransRunFlag' set to 1)
%trans_run = [2 2 1];  % Which run WITHIN an experiment to trans too (1 for rest if only one rest run)
%trans_run = [0 0 0];   % If want to skip this step, eg trans default only

%% Bad runs:
%badrun = zeros(5,50,3,2);  % Assume all runs ok, unless indicated next
badrun = zeros(length(groups),length(subjects),length(expts),length(runs{1}));  % es edit

% subid = find(strcmp(cbu_codes{2},'meg14_0024'));
% badrun(2,subid,1,2) = 1; % meg14_0024, object, run 2 cannot be maxfiltered "The origin is only 4 cm from nearest coil!"
% badrun(2,subid,2,1) = 1; % meg14_0024, scene,  run 1 cannot be maxfiltered "The origin is only 4 cm from nearest coil!"


% Set up directory structures (only needs to be done once)
for e=1:length(expts)
    eval(sprintf('!mkdir %s',fullfile(bas_wd,expts{e})));
    for g=1:length(groups)
        eval(sprintf('!mkdir %s',fullfile(bas_wd,expts{e},groups{g})));
        for s = 1:length(cbu_codes{g})
%            eval(sprintf('!mkdir %s',fullfile(bas_wd,expts{e},groups{g},sprintf('Sub%02d',s))));
            %eval(sprintf('!mkdir %s',fullfile(bas_wd,expts{e},groups{g},cbu_codes{g}{s})));
            mkdir(fullfile(bas_wd,expts{e},groups{g},cbu_codes{g}{s})); % es edit
        end
    end
end

% Any use bad channels? (This option not implemented yet)
% user_bad{1}{3} = [1218 1278];

basestr = ' -ctc /neuro/databases/ctc/ct_sparse.fif -cal /neuro/databases/sss/sss_cal.dat';
basestr = [basestr ' -linefreq 50 -hpisubt amp'];
basestr = [basestr ' -force'];
maxfstr = '!/neuro/bin/util/x86_64-pc-linux-gnu/maxfilter-2.2 '

addpath /imaging/local/meg_misc
addpath /neuro/meg_pd_1.2/

%mvcomp_fail = zeros(length(groups),length(subjects),length(expts),length(runs{1})); % do mvcomp
%mvcomp_fail(1,1,1,2) = 1; % Pilot1 object second run
%mvcomp_fail(1,1,2,2) = 1; % Pilot1 scene second run
mvcomp_fail = ones(length(groups),length(subjects),length(expts),length(runs{1}));  % Turn off all mvcomp, since seems to fail randomly!

movfile = 'trans_move.txt'; % This file will record translations between runs

ParType = 0;  % Fun on Login machines (not generally advised!)
%ParType = 1;   % Run maxfilter call on Compute machines using spmd (faster)
%ParType = 2;   % Run on multiple Compute machines using parfar (best, but less feedback if crashes)

%% open matlabpool if required
% matlabpool close force CBU_Cluster
if ParType
    if matlabpool('size')==0;
        MaxNsubs = 1;
        if ParType == 2
            for g=1:length(cbu_codes)
                MaxNsubs = max([MaxNsubs length(cbu_codes{g})]);
            end
        end
        P = cbupool(MaxNsubs);
        matlabpool(P);
    end
end

TransDefaultFlag = 1;
TransRunFlag = 1; % es edit

%% Main loop (can comment/uncomment lines below if want to parallelise over expts rather than subjects)
for g = 1:length(groups)
    fprintf('\n\n%s\n\n',groups{g})
    if ParType == 2 % parfor loop
        parfor s = 1:length(cbu_codes{g})
            raw_wd    = dir(fullfile(dat_wd,cbu_codes{g}{s},'1*'));  % Just to get date directory (assuming between 20*1*0 and 20*1*9Q!)
            raw_wd    = raw_wd.name;

%        parfor e = 1:length(expts)  % If doing a single subject (note: cannot embed parfor loops unfortunately)
            for e = 1:length(expts)

                transfstfile = ''; orig = []; rad=[]; fit=[]; transtr = {}; raw_stem = {};

                % Output directory
                sub_wd = fullfile(bas_wd,expts{e},groups{g},cbu_codes{g}{s}), cd(sub_wd)
                %try eval(sprintf('!mkdir %s',sub_wd)); end  % Try not allowed n parfor, so make directories in advance above

                eval(sprintf('!touch %s',movfile));

                for r = 1:length(runs{e})

                    %raw_file = dir(fullfile(dat_wd,cbu_codes{g}{s},raw_wd,sprintf('%s*%s_raw*',expts{e},runs{e}{r})));  % Get raw FIF file
                    %raw_file = dir(fullfile(dat_wd,cbu_codes{g}{s},raw_wd,sprintf('%s%s_raw*',expts{e},runs{e}{r}))); % es edit
                    raw_file = dir(fullfile(dat_wd,cbu_codes{g}{s},raw_wd,sprintf('%s%s*',expts{e},runs{e}{r}))); % es edit
                    
                    if isempty(raw_file)
                        error('Could not find run %d for grp %s, sub %s, exp %s',r,groups{g},cbu_codes{g}{s},expts{e})
                    else
                        % raw_stem = raw_file.name(1:(end-4)); % MA edit
                        raw_stem = runsout{e}{r}; % MA edit
                        raw_file = fullfile(dat_wd,cbu_codes{g}{s},raw_wd,raw_file.name);
                    end

                    if badrun(g,s,e,r)  % Care: need to note that this run not trans'ed (despite name), not sss, etc
                        outfile = fullfile(sub_wd,sprintf('%s_NoSSS',raw_stem));
                        filestr = sprintf(' -f %s -o %s.fif',raw_file,outfile);
                        %finstr = [maxfstr filestr ' -nosss -ds 4' sprintf(' -v | tee %s.log',outfile)];
                        finstr = [maxfstr filestr ' -nosss' sprintf(' -v | tee %s.log',outfile)]; % es edit, no downsampling
                        eval(finstr);
                        %eval(sprintf('!cp %s %s',raw_file,outfile));
                    else

                        %% Fit sphere (since better than MaxFilter does)
                        if r == 1  % fit sphere doesn't change with run!
                            incEEG = 0;
                            if exist(fullfile(sub_wd,'fittmp.txt')); delete(fullfile(sub_wd,'fittmp.txt')); end
                            if exist(fullfile(sub_wd,sprintf('run_%02d_hpi.txt',r))); delete(fullfile(sub_wd,sprintf('run_%02d_hpi.txt',r)));  end
                            [orig,rad,fit] = meg_fit_sphere(raw_file,sub_wd,sprintf('%s_hpi.txt',raw_stem),incEEG);
                            delete(fullfile(sub_wd,'fittmp.txt'));
                        end
                        origstr = sprintf(' -origin %d %d %d -frame head',orig(1),orig(2),orig(3))

                        badstr  = sprintf(' -autobad %d -badlimit %d',900,7); % 900s is 15mins - ie enough for whole recording!


                        %% 1. Bad channel detection (this email says important if doing tSSS later https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=NEUROMEG;d3f363f3.1205)

                        outfile = fullfile(sub_wd,sprintf('%s_bad',raw_stem));
                        filestr = sprintf(' -f %s -o %s.fif',raw_file,outfile);

                        % Write out movements too...
                        posfile = fullfile(sub_wd,sprintf('%s_headpos.txt',raw_stem));
                        compstr = sprintf(' -headpos -hpistep 10 -hp %s',posfile);

                        finstr = [maxfstr filestr origstr basestr badstr compstr sprintf(' -v | tee %s.log',outfile)]
                        eval(finstr);
                        delete(sprintf('%s.fif',outfile));

                        % Pull out bad channels from logfile:
                        badfile = sprintf('%s.txt',outfile); delete(badfile);
                        eval(sprintf('!cat %s.log | sed -n -e ''/Detected/p'' -e ''/Static/p'' | cut -f 5- -d '' '' > %s',outfile,badfile));
                        
                        try % es edit- if there are no bad channels detected, this will jump to 'catch' part
                            tmp=dlmread(badfile,' '); Nbuf = size(tmp,1);
                            tmp=reshape(tmp,1,prod(size(tmp)));
                            tmp=tmp(tmp>0); % Omit zeros (padded by dlmread):
                        catch
                            tmp = [];
                        end

                        % Get frequencies (number of buffers in which chan was bad):
                        [frq,allbad] = hist(tmp,unique(tmp));

                        % Mark bad based on threshold (currently ~5% of buffers (assuming 500 buffers)):
                        badchans = allbad(frq>0.05*Nbuf);
                        if isempty(badchans)
                            badstr = '';
                        else
                            badstr = sprintf(' -bad %s',num2str(badchans))
                        end


                        %% 2. tSSS and trans to first file (ie, align within subject if multiple runs)

                        tSSSstr = ' -st 10 -corr 0.98'; %'tSSSstr = '';

                        if mvcomp_fail(g,s,e,r) == 1
                            compstr = '';
                        else
                            compstr = sprintf(' -movecomp inter');
                        end

                        outfile = fullfile(sub_wd,sprintf('%s_trans1st',raw_stem))
                        if TransRunFlag % es edit
                            if length(runs{e})>1 & r>1
                                transtr = sprintf(' -trans %s ',transfstfile)
                            else
                                transfstfile = [outfile '.fif'];
                                transtr = '';
                            end
                        else
                            transtr = '';
                        end

                        %dsstr = ' -ds 4';   % downsample to 250Hz
                        dsstr = '';   % es edit, no downsampling

                        filestr = sprintf(' -f %s -o %s.fif',raw_file,outfile);
                        finstr = [maxfstr filestr basestr badstr tSSSstr compstr origstr transtr dsstr sprintf(' -v | tee %s.log',outfile)]
                        eval(finstr);

                        eval(sprintf('!echo ''Trans 1st...'' >> %s',movfile));
                        eval(sprintf('!cat %s.log | sed -n ''/Position change/p'' | cut -f 7- -d '' '' >> %s',outfile,movfile));


                        %% 3. trans to default helmet space (align across subjects)

                        if TransDefaultFlag
                            transdeffile = fullfile(sub_wd,sprintf('%s_trans1stdef',raw_stem))
                            transtr = sprintf(' -trans default -origin %d %d %d -frame head -force',orig+[0 -13 6])
                            filestr = sprintf(' -f %s.fif -o %s.fif',outfile,transdeffile);
                            finstr = [maxfstr filestr transtr sprintf(' -v | tee %s.log',outfile)]
                            eval(finstr);
                            eval(sprintf('!echo ''Trans def...'' >> %s',movfile));
                            eval(sprintf('!cat %s.log | sed -n ''/Position change/p'' | cut -f 7- -d '' '' >> %s',outfile,movfile));
                        end

                    end
                end
            end
        end

    else  %% non parfor...

        for s = 1:length(cbu_codes{g})
            raw_wd    = dir(fullfile(dat_wd,cbu_codes{g}{s},'1*'));  % Just to get date directory (assuming between 20*1*0 and 20*1*9Q!)
            raw_wd    = raw_wd.name;

            for e = 1:length(expts)

                transfstfile = ''; orig = []; rad=[]; fit=[]; transtr = {}; raw_stem = {};

                % Output directory
                sub_wd = fullfile(bas_wd,expts{e},groups{g},cbu_codes{g}{s}), cd(sub_wd)
                %try eval(sprintf('!mkdir %s',sub_wd)); end  % Try not allowed n parfor, so make directories in advance above

                eval(sprintf('!touch %s',movfile));

                for r = 1:length(runs{e})

                    %raw_file = dir(fullfile(dat_wd,cbu_codes{g}{s},raw_wd,sprintf('%s*%s_raw*',expts{e},runs{e}{r})));  % Get raw FIF file
                    % raw_file = dir(fullfile(dat_wd,cbu_codes{g}{s},raw_wd,sprintf('%s%s_raw*',expts{e},runs{e}{r})));  % Get raw FIF file
                    raw_file = dir(fullfile(dat_wd,cbu_codes{g}{s},raw_wd,sprintf('%s%s.fif',expts{e},runs{e}{r})));  % Get raw FIF file
                    

                    if isempty(raw_file)
                        error('Could not find run %d for grp %s, sub %s, exp %s',r,groups{g},cbu_codes{g}{s},expts{e})
                    else
                        % raw_stem = raw_file.name(1:(end-4)); MA edit
                        raw_stem = runsout{e}{r};
                        raw_file = fullfile(dat_wd,cbu_codes{g}{s},raw_wd,raw_file.name);
                    end

                    if badrun(g,s,e,r)  % Care: need to note that this run not trans'ed (despite name), not sss, etc
                        outfile = fullfile(sub_wd,sprintf('%s_NoSSS',raw_stem));
                        filestr = sprintf(' -f %s -o %s.fif',raw_file,outfile);
                        %finstr = [maxfstr filestr ' -nosss -ds 4' sprintf(' -v | tee %s.log',outfile)];
                        finstr = [maxfstr filestr ' -nosss' sprintf(' -v | tee %s.log',outfile)]; % es edit, no downsampling
                        eval(finstr);
                        %eval(sprintf('!cp %s %s',raw_file,outfile));
                    else
                        %% Fit sphere (since better than MaxFilter does)
                        if r == 1  % fit sphere doesn't change with run!
                            % if headpoints are missing use EEG
                            % incEEG = 0;
                            incEEG = 1;
                            if exist(fullfile(sub_wd,'fittmp.txt')); delete(fullfile(sub_wd,'fittmp.txt')); end
                            if exist(fullfile(sub_wd,sprintf('run_%02d_hpi.txt',r))); delete(fullfile(sub_wd,sprintf('run_%02d_hpi.txt',r)));  end
                            [orig,rad,fit] = meg_fit_sphere(raw_file,sub_wd,sprintf('%s_hpi.txt',raw_stem),incEEG);
                            delete(fullfile(sub_wd,'fittmp.txt'));
                        end
                        origstr = sprintf(' -origin %d %d %d -frame head',orig(1),orig(2),orig(3))

                        badstr  = sprintf(' -autobad %d -badlimit %d',900,7); % 900s is 15mins - ie enough for whole recording!


                        %% 1. Bad channel detection (this email says important if doing tSSS later https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=NEUROMEG;d3f363f3.1205)

                        outfile = fullfile(sub_wd,sprintf('%s_bad',raw_stem));
                        filestr = sprintf(' -f %s -o %s.fif',raw_file,outfile);

                        % Write out movements too...
                        posfile = fullfile(sub_wd,sprintf('%s_headpos.txt',raw_stem));
                        compstr = sprintf(' -headpos -hpistep 10 -hp %s',posfile);

                        finstr = [maxfstr filestr origstr basestr badstr compstr sprintf(' -v | tee %s.log',outfile)]
                        if ParType==1
                            spmd; eval(finstr); end
                        else
                            eval(finstr);
                        end
                        delete(sprintf('%s.fif',outfile));

                        % Pull out bad channels from logfile:
                        badfile = sprintf('%s.txt',outfile); delete(badfile);
                        eval(sprintf('!cat %s.log | sed -n -e ''/Detected/p'' -e ''/Static/p'' | cut -f 5- -d '' '' > %s',outfile,badfile));

                        try % es edit- if there are no bad channels detected, this will jump to 'catch' part
                            tmp=dlmread(badfile,' '); Nbuf = size(tmp,1);
                            tmp=reshape(tmp,1,prod(size(tmp)));
                            tmp=tmp(tmp>0); % Omit zeros (padded by dlmread):
                            % Get frequencies (number of buffers in which chan was bad):
                            [frq,allbad] = hist(tmp,unique(tmp));
                            % Mark bad based on threshold (currently ~5% of buffers (assuming 500 buffers)):
                            badchans = allbad(frq>0.05*Nbuf);
                        catch
                            badchans = [];
                        end

                        if isempty(badchans)
                            badstr = '';
                        else
                            badstr = sprintf(' -bad %s',num2str(badchans))
                        end


                        %% 2. tSSS and trans to first file (ie, align within subject if multiple runs)

                        tSSSstr = ' -st 10 -corr 0.98';%'tSSSstr = '';

                        if mvcomp_fail(g,s,e,r) == 1
                            compstr = '';
                        else
                            compstr = sprintf(' -movecomp inter');
                        end

                        outfile = fullfile(sub_wd,sprintf('%s_trans1st',raw_stem))
                        if TransRunFlag % es edit
                            if length(runs{e})>1 & r>1
                                transtr = sprintf(' -trans %s ',transfstfile)
                            else
                                transfstfile = [outfile '.fif'];
                                transtr = '';
                            end
                        else
                            transtr = '';
                        end

                        %dsstr = ' -ds 4';   % downsample to 250Hz
                        dsstr = '';   % % es edit, no downsampling, no downsampling

                        filestr = sprintf(' -f %s -o %s.fif',raw_file,outfile);
                        finstr = [maxfstr filestr basestr badstr tSSSstr compstr origstr transtr dsstr sprintf(' -v | tee %s.log',outfile)]
                        if ParType==1
                            spmd; eval(finstr); end
                        else
                            eval(finstr);
                        end

                        eval(sprintf('!echo ''Trans 1st...'' >> %s',movfile));
                        eval(sprintf('!cat %s.log | sed -n ''/Position change/p'' | cut -f 7- -d '' '' >> %s',outfile,movfile));


                        %% 3. trans to default helmet space (align across subjects)

                        if TransDefaultFlag
                            transdeffile = fullfile(sub_wd,sprintf('%s_trans1stdef',raw_stem))
                            transtr = sprintf(' -trans default -origin %d %d %d -frame head -force',orig+[0 -13 6])
                            filestr = sprintf(' -f %s.fif -o %s.fif',outfile,transdeffile);
                            finstr = [maxfstr filestr transtr sprintf(' -v | tee %s.log',outfile)]
                            if ParType==1
                                spmd; eval(finstr); end
                            else
                                eval(finstr);
                            end
                            eval(sprintf('!echo ''Trans def...'' >> %s',movfile));
                            eval(sprintf('!cat %s.log | sed -n ''/Position change/p'' | cut -f 7- -d '' '' >> %s',outfile,movfile));
                        end
                    end
                end
            end
        end
    end
end

if ParType
    matlabpool close force CBU_Cluster
end