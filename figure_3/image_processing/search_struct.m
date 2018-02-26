function [exists] = search_struct(full_struct, search_list)
% Assumes that the search list is a top down hierarchy to iterate through
    % exists boolean
    exists = false;
    % First, define the searching stucture
    s_struct = full_struct;
    % Then, get the structure's fieldnames
    f_names = fieldnames(s_struct);
    % Number of levels
    levels = length(search_list);
    for x = 1:levels
        if ismember(search_list{x}, f_names)
            if x == levels
                exists = true;
                continue
            end
            % Set the searching struct
            s_struct = s_struct.(search_list{x});
            % Then, get field names
            f_names = fieldnames(s_struct);
        else
            % Well, the field doesn't exist
            break
        end
    end
end