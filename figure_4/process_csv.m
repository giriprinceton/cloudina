function data = process_csv(csv_location)
    % Declare the data structure
    data = struct();
    % The format structure is string, int float float float float, string,
    % string (boolean), int
    format_string = '%s %u %f %f %f %f %q %s %u';
    % Begin by opening the csv
    fid = fopen(csv_location);
    % Now, we want to read each line and append it to the structure
    % Now, let's textscan and produce lines
    lines = textscan(fid, format_string, 'HeaderLines', 1, 'Delimiter',',');
    num_lines = length(lines{1});
    % For each line, let's add to the data structure
    for x = 1:num_lines
        this_ind = lines{1}{x};
        % Does this field already exist in data?
        if ~isfield(data, this_ind)
            data.(this_ind) = struct();
            % Prepend the data
            data.(this_ind).inner = [];
            data.(this_ind).outer = [];
            data.(this_ind).slices = [];
            data.(this_ind).moved = [];
        end
        % Let's also set a moved field
        moved = nan;
        if strcmpi(lines{8}{x}, 'TRUE')
            moved = double(lines{9}(x));
        end
        % Now, if it does exist, add to the measurements
        data.(this_ind).inner = [data.(this_ind).inner; lines{2}(x), lines{3}(x), lines{4}(x)];
        data.(this_ind).outer = [data.(this_ind).outer; lines{2}(x), lines{5}(x), lines{6}(x)];
        data.(this_ind).slices = [data.(this_ind).slices; lines{2}(x)];
        data.(this_ind).moved = [data.(this_ind).moved; moved];
    end
    % Done! 
    % Exit!
    return
end