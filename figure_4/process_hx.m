function measurement_structure = process_hx(hx_file)
    % We take in an hx file and process the measurements
    % Declare the measurement structure
    measurement_structure = struct();
    % Some collectors
    current_rect = '';
    current_line = '';
    current_circle = '';
    current_line_pts = [];
    % Okay, let's begin by opening the .hx file
    fid = fopen(hx_file);
    % Now, let's textscan and produce lines
    lines = textscan(fid,'%s', 'Delimiter','\n');
    % Set lines to lines{1}
    lines = lines{1};
    % Great, now let's loop through the lines
    for x = 1:length(lines)
        %% TURN ALL OF THESE REGEXP INTO FUNCTIONS!
        % Declare this line
        this_line = lines{x};
        % Okay, we're looking for "create HxMeasure "
        create_measure = '^create HxMeasure "';
        [~, created_e_idx] = regexp(this_line, create_measure);
        if ~isempty(created_e_idx)
            % Rectangle name
            current_rect = this_line(created_e_idx + 1 : end - 1);
            % Let's santize this to use as a fieldname
            current_rect_field = current_rect;
            % Look for spaces
            current_rect_spaces = isspace(current_rect_field);
            % If spaces, then do something
            if max(current_rect_spaces) ~= 0
                % Where?
                locs = find(current_rect_spaces);
                % For each location, cut up and reassemble the string
                for l = 1:length(locs)
                    current_rect_field = [current_rect_field(1:locs(l) - 1), ...
                        current_rect_field(locs(l) + 1:end)];
                end
            end
            measurement_structure.(current_rect_field) = struct();
            measurement_structure.(current_rect_field).line_names = {};
            measurement_structure.(current_rect_field).lines = [];
            measurement_structure.(current_rect_field).lengths = [];
            measurement_structure.(current_rect_field).circle_centers = [];
        end
        % Okay, next, we want to be looking for "rect_XXXXXX" GUI addMeasure Line
        add_measure = ['"', current_rect, '" GUI addMeasure Line "'];
        [~, add_measure_e_idx] = regexp(this_line, add_measure);
        if ~isempty(add_measure_e_idx)
            current_line = this_line(add_measure_e_idx + 1 : end - 1);
            measurement_structure.(current_rect_field).line_names = ...
                [measurement_structure.(current_rect_field).line_names; current_line];
        end
        % Now, we want to store lines and circles
        % The idea is, every two pairs of lines correspond to a outer inner
        % axis pair
        % So, we're looking for: "Line XX" points  setValue 0 8895.75 15887.3 1543.75
        line_value = ['"', current_line, '" points  setValue '];
        [~, line_value_e_idx] = regexp(this_line, line_value);
        if ~isempty(line_value_e_idx)
            pt_string = this_line(line_value_e_idx + 1 : end);
            % Split string
            split = strsplit(pt_string, ' ');
            % Now, convert to numbers
            pts = cellfun(@str2num, split);
            current_line_pts(1, :, pts(1) + 1) = pts(2:end);
        end
        % Next, let's save the current_line_pts once we know things are
        % good to go
        line_finish = ['"', current_line, '" finishCreation'];
        finish = regexp(this_line, line_finish, 'match');
        if ~isempty(finish)
            % Save current_line_pts
            measurement_structure.(current_rect_field).lines = ...
                [measurement_structure.(current_rect_field).lines; current_line_pts];
            % Calculate the length
            axis_length = pdist([current_line_pts(:,:,1); current_line_pts(:,:,2)], 'euclidean');
            measurement_structure.(current_rect_field).lengths = ...
                [measurement_structure.(current_rect_field).lengths; axis_length];
            % Reset current line pts
            current_line_pts = [];
        end
        % Finally, let's save any circles we might encounter
        % "rect_XXXXXX" GUI addMeasure Circle "Circle X"
        circle_start = ['"', current_rect, '" GUI addMeasure Circle "'];
        [~, circle_start_e_idx] = regexp(this_line, circle_start);
        if ~isempty(circle_start_e_idx)
            % Set current circle
            current_circle = this_line(circle_start_e_idx + 1 : end -1);
        end
        % Look for the first point
        % "Circle X" points  setValue 0 9137.53 14252.9 2815.49
        circle_point = ['"', current_circle, '" points  setValue 0 '];
        [~, circle_point_e_idx] = regexp(this_line, circle_point);
        if ~isempty(circle_point_e_idx)
            circle_center = this_line(circle_point_e_idx + 1 : end);
            circle_center = strsplit(circle_center, ' ');
            circle_center = cellfun(@str2num, circle_center);
            measurement_structure.(current_rect_field).circle_centers = ...
                [measurement_structure.(current_rect_field).circle_centers; circle_center];
        end
    end
    fclose(fid);
end