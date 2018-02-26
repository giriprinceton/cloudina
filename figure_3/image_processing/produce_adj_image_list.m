function [prev_img, next_img] = produce_adj_image_list(image_name, prefix, offsets)
    % Get the file parts
    [directory, file_name, ext] = fileparts(image_name);
    % Now, increment and decrement the last digit of the file name
    % First, find the trailing number substring
    file_prefix_length = length(prefix);
    starting_idx = strfind(file_name, prefix);
    trailing_number = str2num(file_name(starting_idx + file_prefix_length:end));
    % Then, produce new trailing numbers
    offset_trailing = offsets + trailing_number;
    prev_trailing = sort(offset_trailing(offset_trailing < trailing_number), 'descend');
    next_trailing = sort(offset_trailing(offset_trailing > trailing_number), 'ascend');
    % Produce final list
    prev_img = produce_final(directory, prefix, prev_trailing, ext);
    next_img = produce_final(directory, prefix, next_trailing, ext);
end

function out = produce_final(directory, prefix, trailing_numbers, ext)
    number_process = length(trailing_numbers);
    out = {};
    for x = 1:number_process;
        file_path = fullfile(directory, [prefix, num2str(trailing_numbers(x)), ext]);
        % If the file exists, add it to the list
        if exist(file_path, 'file') == 2
            out = [out; file_path];
        end
    end
end