function [channels] = build_empty_channels(feat_list, descr_list)
    % loc_list: cell array of localizer constants
    % descr_list: cell array of descriptor constants
    pouet
    channels = {struct('feat_name', feat_list, ...  % Type of features detected
                       'feat', [], ...             % Matrix of n features: n*3
                       'descr', [] ...             % List of structures for descriptors
                       )}';
    
    for i=1:size(channels,1);
        channels{i}.descriptors = descr_list;
        channels{i}.descr = {struct('descr_name',descr_list,'descr',[])}';
    end
end