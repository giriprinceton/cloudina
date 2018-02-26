function data = compile_measurements(data, voxel_dims)
    %% NOTE THAT LENGTH IS IN PIXELS AND MIGHT NOT BE SCALED, SO CHECK THIS
    % Here, we compile measurements in a structure and append it with: inner
    % and outer measurements, 
    % Individuals refers to each individual of a population measured
    individuals = fieldnames(data);
    % For each individual
    for x = 1:length(individuals)
        this_individual = data.(individuals{x});
        % First, is rect_data a part of this?
        if isfield(this_individual, 'rect_data')
            % If so, let's produce a struct called compiled measurements
            compiled_measurements = struct();
            % First, let's calculate the spline length
            % This is a for loop. Forgive me!
            spline_length = 0;
            spline_points = this_individual.rect_data.evaluated_points;
            for y = 1:size(spline_points, 2) - 1
                % The two points
                spline_length = spline_length + ...
                    pdist([spline_points(:,y), spline_points(:,y+1)]', 'euclidean');
            end
            compiled_measurements.spline_length = spline_length;
            % Let's also define the curvature, using frenet frames
            [spline_tangents, ~, ~, spline_curvature, ~] = frenet(spline_points(1,:),spline_points(2,:),spline_points(3,:));
            compiled_measurements.spline_curvature = spline_curvature;
            % Next, we want to produce compiled inner and outer
            % measurements
            this_ind_outer = this_individual.outer(:, 2:end);
            this_ind_inner = this_individual.inner(:, 2:end);
            % compiled_measurements.mean_outer = mean(this_ind_outer);
            % compiled_measurements.std_outer = std(double(this_ind_outer));
            compiled_measurements.median_outer = median(this_ind_outer);
            compiled_measurements.max_outer = max(this_ind_outer);
            compiled_measurements.min_outer = min(this_ind_outer);
            % compiled_measurements.mean_inner = mean(this_ind_inner);
            % compiled_measurements.std_inner = std(double(this_ind_inner));
            compiled_measurements.median_inner = median(this_ind_inner);
            compiled_measurements.max_inner = max(this_ind_inner);
            compiled_measurements.min_inner = min(this_ind_inner);
            % Now, we want plunge and trend
            % Multiply slice numbers by 20 -> because slices taken at 20,
            % 40, 60, 80 (one day make this a variable)
            slice_evaluation = (this_individual.slices + 1) .* 20;
            % Determine which positions to replace
            to_replace = find(~isnan(this_individual.moved));
            slice_evaluation(to_replace) = this_individual.moved(to_replace) + 1;
            % Produce vectors
            slice_normals = spline_points(:, slice_evaluation + 1) - spline_points(:, slice_evaluation);
            compiled_measurements.trend_plunge = [];
            % Calculate plunge and trend
            for y = 1:length(slice_evaluation)
                [trend, plunge] = calculate_plunge_trend(slice_normals(:, y)');
                compiled_measurements.trend_plunge = [compiled_measurements.trend_plunge; trend, plunge];
            end
            compiled_measurements.outer_major_trend_plunge = [];
            compiled_measurements.outer_minor_trend_plunge = [];
            % Calculate the orientation and direction of the semi-major
            % axis
            outer_major = this_individual.hxdata.outer_major;
            outer_minor = this_individual.hxdata.outer_minor;
            % To calculate this vector, subtract the first point (:,:,1)
            % from the second point (:,:,2) (the third is the center)
            outer_major_vector = outer_major(:,:,2) - outer_major(:,:,1);
            outer_minor_vector = outer_minor(:,:,2) - outer_minor(:,:,1);
            % Now, loop through each vector
            for y = 1:size(outer_major_vector, 1)
                [maj_trend, maj_plunge] = calculate_plunge_trend(outer_major_vector(y, :));
                compiled_measurements.outer_major_trend_plunge = [compiled_measurements.outer_major_trend_plunge; maj_trend, maj_plunge];
            end
            for y = 1:size(outer_minor_vector, 1)
                [min_trend, min_plunge] = calculate_plunge_trend(outer_minor_vector(y, :));
                compiled_measurements.outer_minor_trend_plunge = [compiled_measurements.outer_minor_trend_plunge; min_trend, min_plunge];
            end
            % Next, calculate growth rate (as a percentage)
            % Sort by the first column of this_individual.outer
            sorted_outer_dims = double(sortrows(this_individual.outer, 1));
            % Prepare a collector array
            num_slices = length(this_individual.slices);
            percent_growth = zeros(num_slices - 1, 1);
            for y = 1:num_slices - 1
                percent_growth(y) = abs(sorted_outer_dims(y + 1, 2) - sorted_outer_dims(y, 2)) / sorted_outer_dims(y, 2) * 100;
            end
            compiled_measurements.percent_growth = percent_growth;
            % Finally, let's save it to the main structure
            data.(individuals{x}).compiled_measurements = compiled_measurements;
        end
    end
end