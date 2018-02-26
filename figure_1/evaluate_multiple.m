function evaluate_multiple(diameter, wall_thickness, number_obs, scale_factor, slices_dir)
    % Curves diameters for evaluation
    % The first one is straight (and hence hard coded
    point_1 = [0,0];
    point_2 = [0,50];
    radii = [0; 400];
    num_radii = numel(radii);
    curve_matrix = {repmat(point_1, num_radii, 1), ...
        repmat(point_2, num_radii, 1), ...
        radii};
    % Produce diameter matrix (mx6, where the first column is the first
    % evaluation point, the second column is the semi major and the third
    % column is the semi minor axis, and columns 4-6 repeat (and refer to
    % the second evaluation point)
    eccentricity = [.5:.05:1]';
    num_eccentricity = length(eccentricity);
    semi_major_diameter = ones(num_eccentricity, 1) * diameter;
    semi_minor_diameter = diameter * eccentricity;
    diameter_matrix = [zeros(num_eccentricity, 1),...
        semi_major_diameter, ...
        semi_minor_diameter, ...
        ones(num_eccentricity, 1), ...
        semi_major_diameter, ...
        semi_minor_diameter];
    % Curvature Collector
    curvature_collector = zeros(num_eccentricity, num_radii);
    % Save matricies
    save(fullfile(slices_dir, 'curve_matrix'), 'curve_matrix');
    save(fullfile(slices_dir, 'diameter_matrix'), 'diameter_matrix');
    % For each row, let's process
    for y = 1:num_eccentricity
        % Diameter_matrix
        diameter_input = diameter_matrix(y, :);
        % Make this more elegant in the future
        diameter_input = [diameter_input(1:3); diameter_input(4:6)];
        % Now, let's process each curve
        for x = 2
            if x == 1
                % Here, the curve is hard coded
                crv = cscvn([0, curve_matrix{1}(x, :); 0,...
                    curve_matrix{2}(x, :)]');
            else
                % Otherwise, we generate the points
                pts = circular_arc_endpoints(curve_matrix{1}(x,:), ...
                    curve_matrix{2}(x, :), curve_matrix{3}(x));
                crv = cscvn([zeros(length(pts),1), pts]');
            end
            output = sectional_slice(crv, diameter_input, wall_thickness, ...
                scale_factor, number_obs, ...
                fullfile(slices_dir, ['slices_', num2str(y), '_', num2str(x)]), false);
            curvature_collector(y,x) = max(output.curvature);
        end
        % Save the curvature matrix
        save(fullfile(slices_dir, 'curvatures.mat'), 'curvature_collector');
    end
    disp('Completed!');
end
