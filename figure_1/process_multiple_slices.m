function complete = process_multiple_slices(slices_directory, number_view, montage_size, scale_factor)
    close all
    complete = false;
    % Check to see if a to_montage directory exists
    to_montage_dir = fullfile(slices_directory, 'to_montage');
    if ~isdir(to_montage_dir)
        mkdir(to_montage_dir);
    end
    % Do the same with all_feret_diameters directory
    all_feret_dia_dir = fullfile(slices_directory, 'all_feret_dia');
    if ~isdir(all_feret_dia_dir)
        mkdir(all_feret_dia_dir);
    end
    % First, load the diameter, curvature, and curve matricies
    % load(fullfile(slices_directory, 'curve_matrix.mat'));
    load(fullfile(slices_directory, 'curvatures.mat'));
    load(fullfile(slices_directory, 'diameter_matrix'));
    % Let's go through all the slices
    [rows, cols] = size(curvature_collector);
    % Here, let's introduce a collector which will be mx7 where m is the
    % total number of variations (rows * cols). Column 1 will be the true
    % area, column 2 is the cross section eccentricity, column 3 is the
    % curvature, column 4 is the avg semi minor diameter, coumn 5 is the
    % median semi minor diameter, column 6 is the avg area error, and column 7
    % is the median area error
    data_collector = zeros(rows*cols, 7);
    for y = 1 : rows
        % This diameter matrix, 1x6
        % cols 2 and 3 are semi major and semi minor axis, respectively
        diameters = diameter_matrix(y, :);
        % The true area of a cross section
        true_area = pi * (diameters(2)/2) * (diameters(3)/2);
        % The eccentricity of this cross section - semi minor over semi
        % major
        eccentricity = diameters(3)/diameters(2);
        for x = 1 : cols
            this_count = ((y - 1) * cols) + x;
            dir_to_process = fullfile(slices_directory, ['slices_', ...
                num2str(y), '_', num2str(x)]);
            tic
            [avg_dia, ...
                median_dia, all_feret_diameters, ...
                to_montage] = process_slices(dir_to_process, number_view, scale_factor);
            toc
            % Save to_montage
            save(fullfile(to_montage_dir, ['to_montage_', num2str(y), '_', ...
                    num2str(x)]), 'to_montage');
            % Save all feret diameters
            save(fullfile(all_feret_dia_dir, ['all_feret_dia_', num2str(y), '_', ...
                    num2str(x)]), 'all_feret_diameters');
            % avg_dia area
            avg_area = pi * (avg_dia/2)^2;
            % median_dia area
            median_area = pi * (median_dia/2)^2;
            % avg area error
            avg_error = 1 - avg_area/true_area;
            % median_dia area
            median_error = 1 - median_area/true_area;
            % Update data collector
            data_collector(this_count, :) = [true_area, eccentricity, ...
                curvature_collector(y,x), avg_dia, median_dia, avg_error, ...
                median_error];
            save(fullfile(slices_directory, 'data_collector'), 'data_collector');
            % Display completed
            disp(['Finished slice: ', num2str(y), '_', num2str(x)]);
            %}
        end
    end
    complete = true;
end