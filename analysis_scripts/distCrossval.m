function [result_all,result_within,result_between] = distCrossval(data,labels,varargin)

validDistMeasures = {'squaredeucledian','pearson'};
% Each index in the cell array must be a valid index of the time (3rd)
% dimension of the data
checkTimeIdx = @(x) all(cellfun(@(y) all(ismember(y,1:size(data,3))),x));
p = inputParser;

addRequired(p,'data',@(x) validateattributes(x,{'numeric'},{'finite'}));
addRequired(p,'labels',@(x) validateattributes(x,{'numeric'}, ...
            {'finite','size',[size(data,1),1]}));
addParameter(p,'distMeasure','squaredeucledian',@(x) ismember(x,validDistMeasures));
addParameter(p,'doNoiseNorm',true,@(x) validateattributes(x,{'logical'},{'scalar'}));
addParameter(p,'timeIdx',num2cell(1:size(data,3)),checkTimeIdx);

parse(p,data,labels,varargin{:});

data = p.Results.data;
labels = p.Results.labels;
distMeasure = p.Results.distMeasure;
doNoiseNorm = p.Results.doNoiseNorm;
timeIdx = p.Results.timeIdx;

result_within = withinClassCrossVal(data,labels,distMeasure,doNoiseNorm,timeIdx);
result_between = betweenClassCrossVal(data,labels,'leaveOneOut',distMeasure,doNoiseNorm,timeIdx);

% Merging the 
result_all = result_between;
for i = 1:size(result_within,3)
    temp = result_all(:,:,i);
    temp = triu(temp)+triu(temp)';
    temp(logical(eye(size(temp)))) = diag(result_within(:,:,i));
    result_all(:,:,i) = temp;
end

end

function result_cv = withinClassCrossVal(data,labels,distMeasure,doNoiseNorm,timeIdx)
% Computes within class crossvalidated distance measure

n_trials = histcounts(labels,'BinMethod','integers');
if numel(unique(n_trials)) > 1
    error('There must be equal number of trials per condition!');
end

conditions = unique(labels);
n_conditions = length(conditions);
n_sensors = size(data,2);
n_time = size(data, 3);

% Leave two out crossvalidation
n_perm = n_trials(1)/2;
temp = arrayfun(@randperm,ones(n_conditions,1)*n_trials(1),'UniformOutput',false);
permIdx = cat(2,temp{:})';
permIdx = mod(permIdx,n_perm);
permIdx(permIdx == 0) = n_perm;

n_time_orig = n_time;
n_time = numel(timeIdx);

result_cv = nan(n_perm, n_conditions, n_conditions, n_time);

for iPerm = 1:n_perm
    
    % 1. Select training and test data
    data_train = data(permIdx ~= iPerm,:,:);
    labels_train = labels(permIdx ~= iPerm,:,:);
    data_test = data(permIdx == iPerm,:,:);
    labels_test = labels(permIdx == iPerm,:,:);
    
    if doNoiseNorm
        % Whitening using the Epoch method
        sigma_ = nan(n_conditions, n_sensors, n_sensors);
        for c = 1:n_conditions
            % compute sigma for each time point, then average across time
            tmp_ = nan(n_time_orig, n_sensors, n_sensors);
            for t = 1:n_time_orig
                tmp_(t,:,:) = cov1para(data_train(labels_train == conditions(c),:,t));
            end
            sigma_(c,:,:) = mean(tmp_, 1);
        end
        sigma = squeeze(mean(sigma_,1));  % average across conditions
        sigma_inv = sigma^-0.5;
        for t = 1:n_time_orig
            data_train(:,:,t) = squeeze(data_train(:,:,t)) * sigma_inv;
            data_test(:,:,t) = squeeze(data_test(:,:,t)) * sigma_inv;
        end
    end
    
    % Reshaping time dimension if necessary
    if any(cellfun(@numel,timeIdx) > 1)
        [data_train_temp,data_test_temp] = deal(cell(n_time,1));
        for iTime = 1:n_time
            temp = data_train(:,:,timeIdx{iTime});
            s = size(temp);
            data_train_temp{iTime} = reshape(temp,s(1),s(2)*s(3));
            temp = data_test(:,:,timeIdx{iTime});
            s = size(temp);
            data_test_temp{iTime} = reshape(temp,s(1),s(2)*s(3));
        end
        data_train = cat(3,data_train_temp{:});
        data_test = cat(3,data_test_temp{:});
        % Free up space
        [data_train_temp,data_test_temp] = deal([]); %#ok<*ASGLU>
    end
    
    for t = 1:n_time
        for c1 = 1:n_conditions
            
            class = conditions(c1);
            X_train = data_train(ismember(labels_train,class),:,t);
            X_test = data_test(ismember(labels_test,class),:,t);
            
            switch distMeasure
                case 'squaredeucledian'
                    % Euclidean
                    % Apply distance measure to training data
                    dist_train_ec = mean(X_train(1:round(size(X_train,1)/2),:),1) - ...
                                    mean(X_train(round(size(X_train,1)/2)+1:end,:),1);
                    % Validate distance measure on testing data
                    dist_test_ec = mean(X_test(1:round(size(X_test,1)/2),:),1) - ...
                                   mean(X_test(round(size(X_test,1)/2)+1:end,:),1);
                    result_cv(iPerm, c1, c1, t) = dot(dist_train_ec, dist_test_ec);
                case 'pearson'
                    % Pearson
                    % Apply distance measure to training data
                    A1_ps = mean(X_train(1:round(size(X_train,1)/2),:),1);
                    B1_ps = mean(X_train(round(size(X_train,1)/2)+1:end,:),1);
                    var_A1_ps = var(A1_ps);
                    var_B1_ps = var(B1_ps);
                    denom_noncv_ps = sqrt(var_A1_ps * var_B1_ps);
                    % Validate distance measure on testing data
                    A2_ps = mean(X_test(1:round(size(X_test,1)/2),:),1);
                    B2_ps = mean(X_test(round(size(X_test,1)/2)+1:end,:),1);
                    cov_a1b2_ps = getfield(cov(A1_ps, B2_ps), {2});
                    cov_b1a2_ps = getfield(cov(B1_ps, A2_ps), {2});
                    cov_ab_ps = (cov_a1b2_ps + cov_b1a2_ps) / 2;
                    var_A12_ps = getfield(cov(A1_ps, A2_ps), {2});
                    var_B12_ps = getfield(cov(B1_ps, B2_ps), {2});
                    reg_factor_var = 0.1; reg_factor_denom = 0.25; % regularization
                    denom_ps = sqrt(max(reg_factor_var * var_A1_ps, var_A12_ps) * ...
                        max(reg_factor_var * var_B1_ps, var_B12_ps));
                    denom_ps = max(reg_factor_denom * denom_noncv_ps, denom_ps);
                    r_ps = cov_ab_ps / denom_ps;
                    r_ps = min(max(-1, r_ps), 1);
                    result_cv(iPerm, c1, c1, t) = 1 - r_ps;
                otherwise
                    error('Invalid distance measure! ');
            end
            
        end
    end
end

% average across permutations
result_cv = squeeze(nanmean(result_cv,1));

end

function result_cv = betweenClassCrossVal(data,labels,cvMethod,distMeasure,doNoiseNorm,timeIdx)
% Computes between class crossvalidated distance measure

n_trials = histcounts(labels,'BinMethod','integers');
conditions = unique(labels);
n_conditions = length(conditions);
n_sensors = size(data,2);
n_time = size(data, 3);

switch cvMethod
    case 'random'
        n_perm = 20;
    case 'leaveOneOut'
        if numel(unique(n_trials)) > 1
            error('There must be equal number of trials per condition!');
        end
        % Leave-one out crossvalidation
        n_perm = n_trials(1);
        temp = arrayfun(@randperm,ones(n_conditions,1)*n_perm,'UniformOutput',false);
        permIdx = cat(2,temp{:})';
end

n_time_orig = n_time;
n_time = numel(timeIdx);

result_cv = nan(n_perm, n_conditions, n_conditions, n_time);

for iPerm = 1:n_perm
    
    switch cvMethod
        case 'random'
            % 1. Compute pseudo-trials for training and test
            n_speudo = 5;
            dataPseudo_train = {};
            labelsPseudo_train = [];
            dataPseudo_test = {};
            labelsPseudo_test = [];
            for iCond = 1:n_conditions
                trlIdx = mod(randperm(n_trials(iCond)),n_speudo);
                trlIdx(trlIdx == 0) = n_speudo;
                tempData = cell(n_speudo,1);
                tempLabels = NaN(n_speudo,1);
                for iTrial = 1:n_speudo
                    temp = find(labels == conditions(iCond));
                    actSelection = temp(trlIdx == iTrial);
                    tempData{iTrial} = mean(data(actSelection,:,:),1);
                    tempLabels(iTrial) = conditions(iCond);
                end
                dataPseudo_train = cat(1,dataPseudo_train,tempData(1:end-1));
                labelsPseudo_train = cat(1,labelsPseudo_train,tempLabels(1:end-1));
                dataPseudo_test = cat(1,dataPseudo_test,tempData(end));
                labelsPseudo_test = cat(1,labelsPseudo_test,tempLabels(end));
            end
            data_train = cat(1,dataPseudo_train{:});
            labels_train = cat(1,labelsPseudo_train(:));
            data_test = cat(1,dataPseudo_test{:});
            labels_test = cat(1,labelsPseudo_test(:));
        case 'leaveOneOut'
            % 1. Select training and test data
            data_train = data(permIdx ~= iPerm,:,:);
            labels_train = labels(permIdx ~= iPerm);
            data_test = data(permIdx == iPerm,:,:);
            labels_test = labels(permIdx == iPerm);
        otherwise
            error('Invalid cross-validation method! ');
    end
    
    if doNoiseNorm
        % Whitening using the Epoch method
        sigma_ = nan(n_conditions, n_sensors, n_sensors);
        for c = 1:n_conditions
            % compute sigma for each time point, then average across time
            tmp_ = nan(n_time_orig, n_sensors, n_sensors);
            for t = 1:n_time_orig
                tmp_(t,:,:) = cov1para(data_train(labels_train == conditions(c),:,t));
            end
            sigma_(c,:,:) = mean(tmp_, 1);
        end
        sigma = squeeze(mean(sigma_,1));  % average across conditions
        sigma_inv = sigma^-0.5;
        for t = 1:n_time_orig
            data_train(:,:,t) = squeeze(data_train(:,:,t)) * sigma_inv;
            data_test(:,:,t) = squeeze(data_test(:,:,t)) * sigma_inv;
        end
    end
    
    % Reshaping time dimension if necessary
    if any(cellfun(@numel,timeIdx) > 1)
        [data_train_temp,data_test_temp] = deal(cell(n_time,1));
        for iTime = 1:n_time
            temp = data_train(:,:,timeIdx{iTime});
            s = size(temp);
            data_train_temp{iTime} = reshape(temp,s(1),s(2)*s(3));
            temp = data_test(:,:,timeIdx{iTime});
            s = size(temp);
            data_test_temp{iTime} = reshape(temp,s(1),s(2)*s(3));
        end
        data_train = cat(3,data_train_temp{:});
        data_test = cat(3,data_test_temp{:});
        % Free up space
        [data_train_temp,data_test_temp] = deal([]); %#ok<*ASGLU>
    end
    
    for t = 1:n_time
        for c1 = 1:n_conditions-1
            for c2 = c1+1:n_conditions
                
                classes = conditions([c1,c2]);
                X_train = data_train(ismember(labels_train,classes),:,t);
                y_train = labels_train(ismember(labels_train,classes));
                X_test = data_test(ismember(labels_test,classes),:,t);
                y_test = labels_test(ismember(labels_test,classes));
                
                switch distMeasure
                    case 'squaredeucledian'
                        % Euclidean
                        % Apply distance measure to training data
                        dist_train_ec = mean(X_train(y_train == classes(1),:),1) - ...
                                        mean(X_train(y_train == classes(2),:),1);
                        % Validate distance measure on testing data
                        dist_test_ec = mean(X_test(y_test == classes(1),:),1) - ...
                                       mean(X_test(y_test == classes(2),:),1);
                        result_cv(iPerm, c1, c2, t) = dot(dist_train_ec, dist_test_ec);
                    case 'pearson'
                        % Pearson
                        % Apply distance measure to training data
                        A1_ps = mean(X_train(y_train==classes(1), :), 1);
                        B1_ps = mean(X_train(y_train==classes(2), :), 1);
                        var_A1_ps = var(A1_ps);
                        var_B1_ps = var(B1_ps);
                        denom_noncv_ps = sqrt(var_A1_ps * var_B1_ps);
                        % Validate distance measure on testing data
                        A2_ps = mean(X_test(y_test==classes(1), :), 1);
                        B2_ps = mean(X_test(y_test==classes(2), :), 1);
                        cov_a1b2_ps = getfield(cov(A1_ps, B2_ps), {2});
                        cov_b1a2_ps = getfield(cov(B1_ps, A2_ps), {2});
                        cov_ab_ps = (cov_a1b2_ps + cov_b1a2_ps) / 2;
                        var_A12_ps = getfield(cov(A1_ps, A2_ps), {2});
                        var_B12_ps = getfield(cov(B1_ps, B2_ps), {2});
                        reg_factor_var = 0.1; reg_factor_denom = 0.25; % regularization
                        denom_ps = sqrt(max(reg_factor_var * var_A1_ps, var_A12_ps) * ...
                                        max(reg_factor_var * var_B1_ps, var_B12_ps));
                        denom_ps = max(reg_factor_denom * denom_noncv_ps, denom_ps);
                        r_ps = cov_ab_ps / denom_ps;
                        r_ps = min(max(-1, r_ps), 1);
                        result_cv(iPerm, c1, c2, t) = 1 - r_ps;
                    otherwise
                        error('Invalid distance measure! ');
                end
            end
        end
    end
end

% average across permutations
result_cv = squeeze(nanmean(result_cv,1));

end