function data = combine_hx_csv(data)
    % Combine hx values with csv values
    % Fieldnames first
    csv_names = fieldnames(data.stats);
    hx_names = fieldnames(data.hx_data);
    mismatched_count = 0;
    for x = 1:length(csv_names)
        % This rect name
        this_csv_name = csv_names{x};
        % Look for something similiar in hx 
        locate = find(strcmp(this_csv_name, hx_names));
        % Now, if locate isn't empty
        if ~isempty(locate)
            this_name = csv_names{x};
            % Well, let's try to find what lines go with what measurements
            this_hx_data = data.hx_data.(hx_names{locate});
            this_csv_data = data.stats.(this_name);
            % Load existing csv_data into the combined strcuture
            data.(this_name) = this_csv_data;
            % Add a hxdata field
            data.stats.(this_name).hxdata = struct();
            % And inner and outer fields
            data.stats.(this_name).hxdata.inner_major = [];
            data.stats.(this_name).hxdata.inner_minor = [];
            data.stats.(this_name).hxdata.outer_major = [];
            data.stats.(this_name).hxdata.outer_minor = [];
            % Okay, what's the challenge here? Well, we have XYZ data from
            % AVIZO that needs to get linked to the CSV data and all we
            % have to go by is the fact that most of the time the slices
            % were measured 3 2 1 0 (not always guaranteed) and the
            % calculated lengths (of which we only need the integer)
            % Get integer components of hx_data.lengths
            % Fuck it, let's use a for loop here, this is so stupid
            hx_lengths = this_hx_data.lengths;
            for idx = 1:length(hx_lengths)
                to_split = hx_lengths(idx);
                to_split = num2str(to_split);
                to_split = strsplit(to_split, '.');
                % Take the first (integer) componet
                this_hx_data.lengths(idx) = str2num(to_split{1});
            end
            for y = 1:length(this_csv_data.slices)
                % This slice
                this_slice = this_csv_data.slices(y);
                % Find inner line and extract data
                inner = this_csv_data.inner(this_csv_data.inner(:,1) == this_slice, 2:end);
                % Find outer line and extract data
                outer = this_csv_data.outer(this_csv_data.outer(:,1) == this_slice, 2:end);
                % Now, find matching lines for inner major and minor, outer
                % major and minor
                [data, mismatched_count] = find_and_insert(max(inner), this_hx_data, data, this_name, 'inner_major', mismatched_count);
                [data, mismatched_count] = find_and_insert(min(inner), this_hx_data, data, this_name, 'inner_minor', mismatched_count);
                [data, mismatched_count] = find_and_insert(max(outer), this_hx_data, data, this_name, 'outer_major', mismatched_count);
                [data, mismatched_count] = find_and_insert(min(outer), this_hx_data, data, this_name, 'outer_minor', mismatched_count);
                % Also add the circle centers
                data.(this_name).hxdata.centers = this_hx_data.circle_centers;
            end
        end
    end
    % Return data
    return
end

function [data, mismatched_count] = find_and_insert(measurement, hx_data, data, this_name, this_field, mismatched_count)
    found_idx = find(hx_data.lengths == measurement);
    % Only if we match do we move on (so we'll end up with
    % fewer than the true number of axes
    if ~isempty(found_idx)
        matching = hx_data.lines(found_idx, :, :);
        % Put this into the combined structure
        data.stats.(this_name).hxdata.(this_field) = [data.stats.(this_name).hxdata.(this_field); matching];
    else
        mismatched_count = mismatched_count + 1;
    end
end