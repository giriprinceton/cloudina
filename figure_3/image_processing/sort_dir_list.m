function [sorted_list] = sort_dir_list(directory, prefix)
    % First, turn directory.name into a cell array
    names = {directory.name};
    % How many names
    number_names = length(names);
    % Loop through to build a matrix that consists of trailing numbers
    % first define the matrix
    trailing_number = zeros(number_names, 1);
    for x = 1:number_names
        % File name element
        el = names{x};
        % Get name only
        [~, file_name, ~] = fileparts(el);
        % Get length of prefix
        prefix_length = length(prefix);
        % Get starting index of prefix
        starting_idx = strfind(file_name, prefix);
        % Store the trailing number into the matrix
        trailing_number(x) = str2num(file_name(starting_idx + prefix_length:end));
    end
    [~, idx] = sort(trailing_number, 'ascend');
    sorted_list = names(idx);
end