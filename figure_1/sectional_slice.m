function output = sectional_slice(input_spline, diameter_matrix, wall_thickness, scale_factor, number_obs, storage, plot_bool)
    rng(500)
    close all
    
    % We produce a series of arbitrary slices given a spline structure and
    % a mx3 matrix where the first column is the evaluation point (0-1) and
    % the second is the major axis diameter, and the third is the minor axis diameter
    % at that point (in mm)
    % Note this is a refactor of sectional_slice_deprecated, so there is no
    % longer an option for a elliptical cross section (instead, circular
    % cross sections are possible by just feeding in equal semi major and
    % semi minor axes
    
    %% ASSERTS
    % Check to see if output directory exists, if not, create it
    if ~isdir(storage)
        mkdir(storage);
    end
    % Here, determine number of diameters
    num_diameters = size(diameter_matrix, 2) - 1;
    assert(num_diameters == 2,'Diameter matrix does not match specifications.');
    % Declare the number of significant digits
    num_significant_digits = -1;
    % Declare the eval spacing
    eval_spacing = 1*(10^num_significant_digits);
    % Let's check the diameter matrix and ensure that the evaluation points
    % are >= 0 and <= 1
    % Sort diameter_matrix by the first column (ascending)
    % Round the eval points to the nearest eval spacing (in this case, .1)
    % Note that we have to multiply by -1 because of how round works
    % (negative numbers round to the left of the decimal space)
    diameter_matrix(:, 1) = round(diameter_matrix(:, 1), -1 * num_significant_digits);
    diameter_matrix = sortrows(diameter_matrix, 1);
    [dia_rows, ~] = size(diameter_matrix);
    assert(diameter_matrix(1, 1) >= 0 & diameter_matrix(end, 1) <=1,...
        'Evaluation points must >= 0 and <= 1!');    
    % Great, now, let's ensure that we have diameter values at 0 and 1
    if diameter_matrix(1, 1) ~= 0
        % Essentially, calculate a linearly spaced value based on the next
        % two points
        % If only one row, the update diameter is 1
        if dia_rows == 1
            updated = diameter_matrix(1, 2:end);
        else
            slope = dia_slope(diameter_matrix(1,:), diameter_matrix(2,:));
            % Here, since the distance will always be that of 0 to the
            % first point, we can just use the first evaluation value *
            % slope to figure out how much smaller/larger the first point
            % is than the second
            updated = diameter_matrix(1, 2:end) - (diameter_matrix(1, 1) * slope);
        end
        % Update the diameter_matrix
        diameter_matrix = [0, updated; diameter_matrix];
    end
    
    if diameter_matrix(end, 1) ~= 1
        % Just like previous... we can turn the second part into 
        if dia_rows == 1
            updated = diameter_matrix(1, 2:end);
        else
            slope = dia_slope(diameter_matrix(end, :), diameter_matrix(end - 1, :));
            % Now, we want to take the last point and add the slope times
            % the distance between the last point and 1
            updated = diameter_matrix(end, 2:end) + ((1 - diameter_matrix(end, 1)) * slope);
        end
        diameter_matrix = [diameter_matrix; 1, updated];
    end
    
    %% PRE-FORM DATA
    
    % Now, the diameter matrix is fully formed
    % Next, let's linearly fill in the diameters 
    evaluation_points = [];
    diameters = [];
    inner_diameters = [];
    half_eval = [];
    half_diameters = [];
    half_inner_diameters = [];
    
    % For loop at present
    for count = 1:size(diameter_matrix, 1) - 1
        steps = diameter_matrix(count, 1) : eval_spacing : diameter_matrix(count + 1, 1);
        % To do linspacing for multiple points, we need to create another
        % for loop (maybe this could be solved using bsx or cellfun)
        spaced_dia = [];
        for x = 1:num_diameters
            spaced_dia = [spaced_dia;...
                linspace(diameter_matrix(count, 1+x), diameter_matrix(count + 1, 1+x), length(steps))];
        end
        spaced_inner = spaced_dia - wall_thickness;
        half_eval = (steps(1:end-1) + (eval_spacing / 2))';
        half_step_start = spaced_dia(:,1) + ((spaced_dia(:, 2) - spaced_dia(:, 1)) / 2);
        half_step_end = spaced_dia(:, end -1) + ((spaced_dia(:, end) - spaced_dia(:, end - 1)) / 2);
        % Once again, because of multiple diameters
        half_spaced_dia = [];
        for x = 1:num_diameters
            half_spaced_dia = [half_spaced_dia; 
                linspace(half_step_start(x), half_step_end(x), length(half_eval))];
        end
        half_spaced_inner = half_spaced_dia - wall_thickness;
        if count ~= 1
            % To deal with overlaps, we remove the first point (which is
            % the same as the previous iteration's last point, after the
            % first iteration)
            steps = steps(2:end);
            spaced_dia = spaced_dia(:, 2:end);
            spaced_inner = spaced_inner(:, 2:end);
        end
        evaluation_points = [evaluation_points; steps'];
        diameters = [diameters; spaced_dia'];
        half_diameters = [half_diameters; half_spaced_dia'];
        inner_diameters = [inner_diameters; spaced_inner'];
        half_inner_diameters = [half_inner_diameters; half_spaced_inner'];
    end
    % Great, now diameters, inner_diameters, and eval points are completed
    % Now, calculate the normal at each evaluation point
    % This output is 3xn where the rows are x,y,z respectively
    xyz_points = fnval(input_spline, evaluation_points .* input_spline.breaks(end));
    half_xyz_points = fnval(input_spline, half_eval .* input_spline.breaks(end));    
    % Generate normal, and binormal at each point (i.e.
    % frenet frames)
    [normal, binormal, curvature] = generate_frenet_data(xyz_points);
    [half_normal, half_binormal, ~] = generate_frenet_data(half_xyz_points);
    keyboard
    %% GENERATE EXTENTS AND XYZ POINTS    
    % Get extents of points
    max_points = max(xyz_points, [], 2);
    min_points = min(xyz_points, [], 2);
    max_diameter = max(diameters(:));
    % Wonky, but should work, even for elliptical
    mesh_coords = [min_points - (2 * max_diameter), max_points + (2 * max_diameter)];
    % THIS BECOMES THE SCALE FACTOR TO CONVERT BETWEEN PIXEL AND WHATEVER
    % UNITS YOU INPUT AT THE BEGINNING!
    mesh_spacing = scale_factor;
    % Now, create a meshgrid
    [x, y, z] = meshgrid(mesh_coords(1,1):mesh_spacing:mesh_coords(1,2),...
        mesh_coords(2,1):mesh_spacing:mesh_coords(2,2), mesh_coords(3,1):mesh_spacing:mesh_coords(3,2));
    mesh_size = size(x);
    % Produce the xyz coordinate list for a given slice (start at 1)
    point_list = [reshape(x, [], 1), reshape(y, [],1), reshape(z, [], 1)];    
    if plot_bool
        %% PLOT
        figure
        fnplt(input_spline, 'black');
        grid on;
        hold on;
        axis equal;
        % Some plotting
        for count = 1:length(evaluation_points)
            theta = 0:.1:(2*pi);
            this_radius = diameters(count, :)/2;
            % Plot the cross sections along the spline
            line_points = repmat(xyz_points(:, count), [1, length(theta)])...
                + this_radius(1) .* (normal(count, :)' * cos(theta))...
                + this_radius(2) .* (binormal(count, :)' * sin(theta));
            plot3(line_points(1,:), line_points(2,:), line_points(3,:), 'black');
        end
    end
    keyboard
    %% EVALUATE POINTS WITHIN    
    % Declare a solid collector
    solid_collector = nan(size(point_list, 1), 1);
    % And a hollow collector
    hollow_collector = nan(size(point_list, 1), 1);
    % And a step_merged_solid_collector
    step_merged_solid_collector = solid_collector;
    % And a step_merged_hollow_collector
    step_merged_hollow_collector = hollow_collector;
    % Collectors for full steps
    [solid_collector_step, hollow_collector_step] = test_points(xyz_points, diameters,...
    inner_diameters, point_list, solid_collector, ...
    hollow_collector, normal, binormal);
    % Collectors for half steps
    [solid_collector_half_step, hollow_collector_half_step] = test_points(half_xyz_points, half_diameters,...
        half_inner_diameters, point_list, hollow_collector,...
        hollow_collector, half_normal, half_binormal);
    step_merged_solid_collector(solid_collector_step == 1 | solid_collector_half_step == 1) = 1;    
    step_merged_hollow_collector(hollow_collector_step == 1 | hollow_collector_half_step == 1) = 1;  
    % Reformat step_merged_solid_collector into an output volume that will
    % be used to select points as origins for slicing
    solid_output_volume = reshape(step_merged_solid_collector, mesh_size(1), mesh_size(2), mesh_size(3));
    % Get all non nan from the hollow volume
    x_solid = x(~isnan(solid_output_volume));
    y_solid = y(~isnan(solid_output_volume));
    z_solid = z(~isnan(solid_output_volume)); 
    % Reformat step_merged_hollow_collector into an output volume for
    % visualization purposes
    hollow_output_volume = reshape(step_merged_hollow_collector, mesh_size(1), mesh_size(2), mesh_size(3));
    % Get all non nan from the hollow volume
    x_hollow = x(~isnan(hollow_output_volume));
    y_hollow = y(~isnan(hollow_output_volume));
    z_hollow = z(~isnan(hollow_output_volume));
    if plot_bool
        % Plot point cloud
        figure
        hold on
        % Properly plot this!
        tube_cloud = pointCloud([x_hollow, y_hollow, z_hollow]);
        pcshow(pcdownsample(tube_cloud,'gridAverage',.25));
    end
    %% RANDOM SLICING
    % Pick a number of points that will serve as the origin of the slice
    point_idxs = datasample(1:length(x_solid), number_obs);
    origin_points = [x_solid(point_idxs), y_solid(point_idxs), z_solid(point_idxs)];
    % Next, we're going to gernerate random numbers on a sphere -> to be
    % treated as normal vectors for a slicing plane
    normal_vectors = produce_random_normals(number_obs);
    % Let's produce a sectional slice that is 2 * max_dim by 2 *
    % second_max_dim
    % First, get the size of hollow volume, and sort descending 
    size_hollow_volume = sort([max(x_hollow(:)) - min(x_hollow(:)), ...
        max(y_hollow(:)) - min(y_hollow(:)), ...
        max(z_hollow(:)) - min(z_hollow(:))], 'descend');
    [slice_x, slice_y] = meshgrid(-size_hollow_volume(1):scale_factor:size_hollow_volume(1), ...
        -size_hollow_volume(1):scale_factor:size_hollow_volume(1));
    % Zeros z
    slice_z = zeros(size(slice_x));
    % Four corners of surface (for slice visualization)
    min_slice_x = min(slice_x(:));
    max_slice_x = max(slice_x(:));
    min_slice_y = min(slice_y(:));
    max_slice_y = max(slice_y(:));
    four_corners = [min_slice_x, min_slice_y, 0; ...
        min_slice_x, max_slice_y, 0; ...
        max_slice_x, max_slice_y, 0; ... 
        max_slice_x, min_slice_y, 0; ...
        ];
    % Declare normal vector
    slice_normal = [0 0 1];
    % Gridded interpolant
    p = [2 1 3];
    x_p = permute(x,p);
    y_p = permute(y,p);
    z_p = permute(z,p);
    vol_p = permute(hollow_output_volume, p);
    gridded_func = griddedInterpolant(x_p, y_p, z_p, vol_p);
    diff_collector = 0;
    for pt = 1:number_obs
        % First, the origin and normal vector of this pt
        this_origin = origin_points(pt, :);
        this_normal = normal_vectors(pt, :);
        % Next, figure out rotation from slice_normal to this_normal
        rot = vrrotvec(slice_normal, this_normal);
        % Define a surface
        %slice_surf = surf(slice_x, slice_y, slice_z);
        slice_surf = surf(slice_x + this_origin(1), slice_y  + this_origin(2), slice_z + this_origin(3));
        % Rotate this surface
        rotate(slice_surf, rot(1:3), rad2deg(rot(4)), this_origin); 
        slice_surf_x = slice_surf.XData;
        slice_surf_y = slice_surf.YData;
        slice_surf_z = slice_surf.ZData;
        delete(slice_surf);
        sliced_interp = gridded_func(slice_surf_x, slice_surf_y, slice_surf_z);
        sliced_interp_surf = surf(slice_surf_x, slice_surf_y, sliced_interp);
        sliced_interp_img = sliced_interp_surf.CData;
        delete(sliced_interp_surf);
        % Old code, diff shows the two to be the same, but speed up is 10x
        %{
        sliced = slice(x,y,z,hollow_output_volume, slice_surf_x, slice_surf_y, slice_surf_z);
        sliced_img = sliced.CData;
        delete(sliced);
        diff = sliced_interp_img - sliced_img;
        if max(diff(:)) > 0 || min(diff(:)) < 0
           diff_collector = diff_collector + 1;
        end
        %}
        sliced_interp_img(isnan(sliced_interp_img)) = 0;
        % Closing holes
        structuring = strel('disk',5);
        % Close it
        sliced_interp_img = imclose(sliced_interp_img, structuring);
        parsave(fullfile(storage, ['slice_', num2str(pt), '.mat']), sliced_interp_img);
        slice_collector(:,:,pt) = sliced_interp_img;
        % Visualizing sections
        axis image
        % Convert rot rotation into a matrix
        rot_m = vrrotvec2mat(rot);
        % Apply matrix rotation to four corners
        rot_corners = four_corners * rot_m';
        % Translate
        rot_corners = rot_corners + repmat(this_origin, 4, 1);
        % Add first row to bottom (in order to close the plane
        rot_corners = [rot_corners; rot_corners(1,:)];
        plot3(rot_corners(:,1), rot_corners(:,2), rot_corners(:,3));
        patch(rot_corners(:,1), rot_corners(:,2), rot_corners(:,3), [0 0 0], 'FaceAlpha',.25);
    end
    %% OUTPUT STRUCTURE
    % Here, we put things into an output structure
    output = struct();
    output.curvature = curvature;
end

function s = dia_slope(first, second)
    % Here, we handle multiple diameter values (i.e., for
    % elliptical cross sections)
    s = (second(2:end) - first(2:end)) / (second(1) - first(1));
end

function [normal, binormal, curvature] = generate_frenet_data(data_points)
    % All of this from: https://www.mathworks.com/matlabcentral/fileexchange/11169-frenet
    dx = gradient(data_points(1, :));
    dy = gradient(data_points(2, :));
    dz = gradient(data_points(3, :));
    dr = [dx', dy', dz'];
    % Second derivative of the curve
    ddx = gradient(dx);
    ddy = gradient(dy);
    ddz = gradient(dz);
    ddr = [ddx', ddy', ddz'];
    % Calculate tangent
    tangent = dr ./ mag(dr, 3);
    % Derivative of the tangent
    dtx = gradient(tangent(:,1));
    dty = gradient(tangent(:,2));
    dtz = gradient(tangent(:,3));
    dt = [dtx, dty, dtz];
    % Calculate curve normal
    normal = dt./mag(dt,3);
    % Okay, now, wherever the tangent is all zeros (i.e. we have 0
    % curvature), we need to assign a Normal and Binormal
    % First, check to see which rows of dt have all zeros (i.e., no normal
    % exists)
    no_normal = find(~any(dt,2));
    % Okay, for each of the no normal, we will a) treat the tangent as
    % normal to a 3d plane and b) the data point as the origin for the
    % plane
    % This way, we can define the normal as [1 0 0] (unit x) and project it
    % on the plane by calculating U = V - (V dot N) * N where N is the unit
    % vector normal to the plane (i.e., normal to plane vector/norm of
    % normal to plane vector)
    % This is currently a loop
    for x = 1:length(no_normal)
        idx = no_normal(x);
        % Tangent vector, which should be a unit vector already
        unit_tangent_vector = tangent(idx,:);
        normal_vector = [1,0,0];
        projected_normal = normal_vector - ...
            (dot(normal_vector, unit_tangent_vector) * unit_tangent_vector);
        normal(idx,:) = projected_normal;
    end
    % Calculate curve binormal -> produced using a cross product
    binormal = cross(tangent, normal);
    % Finally, calculate the curvature
    % curvature = mag(dt,1);
	curvature = mag(cross(dr,ddr),1)./((mag(dr,1)).^3);
end

function N = mag(T, n)
    % Magnitude of a vector
    N = sum(abs(T).^2, 2) .^ (1/2);
    % Replace zeros with a very very tiny number
    N(N == 0) = eps;
    % repmat
    N = repmat(N, [1, n]);
end

function [valid_points_idx] = transform_check(first_point, second_point, diameters,...
    normal, binormal, points_to_test)
    % First, let's calculate the transform matrix to make the
    % arbitrarly oriented elliptic cylinder into a unit radius and
    % height cylinder
    % The translation matrix, which is: [1 0 0 Cx; 0 1 0 Cy; 0 0 1
    % Cz; 0 0 0 1]
    t = [1, 0, 0, first_point(1); ...
        0, 1, 0, first_point(2);...
        0, 0, 1, first_point(3);...
        0, 0, 0, 1];
    % Rotation matrix, which is [ax bx cx 0; ay by cy 0; az bz cz 0;
    % 0 0 0 1] where a is the x vector, b is the y vector, and z is
    % the z vector that defines the cylinder IN LOCAL SPACE
    % in order to do this, we should define a b and c
    a = diameters(1)/2 * normal;
    u_a = a/norm(a);
    b = diameters(2)/2 * binormal;
    u_b = b/norm(b);
    c = second_point - first_point;
    u_c = c/norm(c);
    r = [u_a(1), u_b(1), u_c(1), 0;...
        u_a(2), u_b(2), u_c(2), 0;...
        u_a(3), u_b(3), u_c(3), 0;...
        0, 0, 0, 1];
    % Scale matrix, which is: [norm(a) 0 0 0; 0 norm(b) 0 0; 0 0 0
    % norm(c) 0; 0 0 0 1]
    s = [norm(a), 0, 0, 0;...
        0, norm(b), 0, 0;...
        0, 0, norm(c), 0;...
        0, 0, 0, 1];
    transform_matrix = t * r * s;
    % Now, let's take each good point and transform it into unit
    % coordinates
    % inv(A*B) is the same as A\B
    transformed_test_points = transform_matrix\...
        [points_to_test'; ones(1, size(points_to_test, 1))];
    % Define the transformed center
    transformed_center = transform_matrix\[first_point,1]';
    % Subtract the center from the points to set them to the origin
    subtracted = transformed_test_points - transformed_center;
    % Remove bottom row
    subtracted = subtracted(1:3, :);
    % Find all points with a z less than 0 and greater than one
    valid_z_idx = find(subtracted(3,:) >= 0 & subtracted(3,:) <= 1);
    % Define a matrix that contains all subtracted points with valid z
    subtracted_valid_z = subtracted(:,valid_z_idx);
    % Unit height
    unit_h = [0;0;1];
    % Subtracted evaluated is effectively norm squared of all points minus
    % the dot product squared of subtracted points and unit_h
    subtracted_valid_z_evaluated = sqrt(sum(subtracted_valid_z.^2)).^2 - sum(subtracted_valid_z.*unit_h).^2;
    % Now, valid points are those that are greater 
    % than 0 but less than 1
    points_within = find(subtracted_valid_z_evaluated >= 0 ...
        & subtracted_valid_z_evaluated <= 1);
    % We use those valid indicies to find the indicies of valid points (the
    % logic here is first we found those points in subtracted, which is
    % directly related to points_to_test, that had valid z coordinates and
    % then we found points that had a valid xy relationship as well). <-
    % confusing. 
    valid_points_idx = valid_z_idx(points_within);
end

function [solid_collector, hollow_collector] = test_points(xyz_points, diameters,...
    inner_diameters, point_list, solid_collector,...
    hollow_collector, normal, binormal)
    for count = 1:size(xyz_points, 2) - 1
        % Here, a cylinder is defined as the circle around this point to
        % the circle around the next point, using this point's diameter
        % So, first, declare the first point, the second point, and the
        % cylinder length (this is common to both circular and elliptical
        % cross sections
        first_point = xyz_points(:, count)';
        second_point = xyz_points(:, count + 1)';
        cyl_length_sqd = pdist([first_point; second_point], 'euclidean') ^ 2;
        % Now, determine which points sit outside the caps -> this is
        % common to both types of cross section and provides a way to
        % reduce the number of points to test
        % Vector from the first point of the cylinder to all points of
        % interest
        vec_from = bsxfun(@minus, point_list, first_point);
        % Vector from point one to point two of the cylinder
        vec_cyl = second_point - first_point;
        % Dot product to determine if points lie behind the cylinder cap 
        dot_prod = vec_from(:, 1) .* vec_cyl(1) + vec_from(:, 2) .* vec_cyl(2) + vec_from(:, 3) .* vec_cyl(3);
        % Now, if the dot product is less than 0 or greater than the
        % cylinder axis line segment length squared, then the point is
        % not within the cylinder
        % So, separate out the points that don't fulfill either requirement
        good_idx = find(dot_prod > 0 & dot_prod < cyl_length_sqd); 
        % Define points to test
        points_to_test = point_list(good_idx, :);
        % Find points that are located within the outer diameter
        outer_dim_idx = transform_check(first_point, second_point, diameters(count,:),...
            normal(count,:), binormal(count,:), points_to_test);
        % Update solid collector, as this contains all points located
        % within the outer diameter
        solid_collector(good_idx(outer_dim_idx)) = 1;
        % Find points that are located within the inner diameter
        inner_dim_idx = transform_check(first_point, second_point, inner_diameters(count, :),...
            normal(count,:), binormal(count,:), points_to_test);
        % Update the hollow collector, which is all points that are in
        % outer_dim_idx but not in inner_dim_idx (set difference)
        hollow_collector(good_idx(setdiff(outer_dim_idx,inner_dim_idx))) = 1;
    end
end

function [normal_vectors] = produce_random_normals(num)
    % Taken from https://www.mathworks.com/help/matlab/math/numbers-placed-randomly-within-volume-of-sphere.html
    % Calculate elevation angles -> NOT UNIFORM
    rvals = 2*rand(num,1)-1;
    elevation = asin(rvals);
    % Calculate azimuth angles -> UNIFORM
    azimuth = 2*pi*rand(num,1);
    % Radius of 1
    radius = 1;
    [x,y,z] = sph2cart(azimuth,elevation,radius);
    normal_vectors = [x,y,z];
end