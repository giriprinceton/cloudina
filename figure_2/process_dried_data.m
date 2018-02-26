function process_dried_data(directory, location_points, location_contours, location_mounds, location_reef_trace)
    % This function processes the dried survey data and produces:
    % A: an interpolated map
    % B: Pie charts illustrating the presence of certain facies
    % combinations
    % C: Finally, a table that represents the data present in B
    close all
    % Grid Spacing (in m)
    spacing = 5;
    % First, load the shapefile
    info = shapeinfo(fullfile(directory, location_points));
    [data, attributes] = shaperead(fullfile(directory, location_points));
    % Data X and Data Y
    data_x = [data.X];
    data_y = [data.Y];
    % First, zero and rotate data, so that you can produce a mesh that
    % covers all the data
    % Center (zero) data
    center_data_x = mean(data_x);
    center_data_y = mean(data_y);
    data_x_zeroed = data_x - center_data_x;
    data_y_zeroed = data_y - center_data_y;
    % First, get the comment column
    comments = {attributes.Comment};
    % Split by '_'
    split_comments = regexp(comments, '_', 'split');
    line_num = arrayfun(@(n) split_comments{n}(1),1:size(comments,2))';
    line_num = arrayfun(@(n) str2num(line_num{n}), 1:size(comments,2))';
    % Get the lowest line number (which, in this case, is 18, NOT 19!)
    last_line = 18;
    % Get the idx of all last line points
    last_line_idx = find(line_num == last_line);
    % Get the x and y
    last_line_x = data_x_zeroed(last_line_idx);
    last_line_y = data_y_zeroed(last_line_idx);
    left_x_idx = find(last_line_x == min(last_line_x));
    right_x_idx = find(last_line_x == max(last_line_x));
    
    slope = (last_line_y(right_x_idx) - last_line_y(left_x_idx)) / (last_line_x(right_x_idx) - last_line_x(left_x_idx));
    
    % Determine the slope
    % slope = data_x_zeroed'\data_y_zeroed';
    % Figure out the angle between the horizontal and the data slope
    u = [1, 0, 0];
    v = [1, slope, 0];
    rot_angle = atan2(norm(cross(u,v)),dot(u,v));
    % Rotate the data
    [zero_x_rot, zero_y_rot] = rotate_data(data_x_zeroed, data_y_zeroed, -rot_angle);
    % Get max (and min) X and Y rotated
    min_x_rot = min(zero_x_rot);
    max_x_rot = max(zero_x_rot);
    min_y_rot = min(zero_y_rot);
    max_y_rot = max(zero_y_rot);
    % Grid
    [x,y] = meshgrid(min_x_rot - spacing : spacing : max_x_rot + spacing,...
        min_y_rot - spacing : spacing : max_y_rot + spacing);
    % Rotate x and y back
    [x,y] = rotate_data(x, y, rot_angle);
    % Send x and y back to the original location
    x = x + center_data_x;
    y = y + center_data_y;
    % Boundary Polygon
    bounds = boundary(data_x',data_y');
    % In and On Boundary Points
    [in, on] = inpolygon(x, y, data_x(bounds), data_y(bounds));
    % Combine the two logical matricies
    contained_points = or(in, on);
    % Set contained points x and y
    contained_x = x(contained_points);
    contained_y = y(contained_points);
    tic
    % Load contours
    [dried_contour, ~] = shaperead(fullfile(directory, location_contours));
    % Load mound traces
    [dried_mounds, ~] = shaperead(fullfile(directory, location_mounds));
    % Load reef trace
    [dried_reef_trace, ~] = shaperead(fullfile(directory, location_reef_trace));
      
    % Load vario_specs and out_points
    load('out_points');
    load('vario_specs');
    load('classes');
    
    % Create a map figure
    map_fig = figure;
    % Define options
    options.max = 8;
    
    for cl = 1:length(classes)
        % Process!
        [kriged, ~] = krig([data_x', data_y'], out_points(:, cl), [contained_x, contained_y], vario_specs{cl} , options);
        % Now, produce an output map
        out_surface = nan(size(contained_points));
        out_surface(contained_points) = kriged;
        %% PLOTTING
        subplot(2, 2, cl)
        hold on
        contour_spec = makesymbolspec('Line',{'Default', 'Color', [.75, .75, .75]});
        % Okay, now, plot the contours
        mapshow(dried_contour, 'SymbolSpec', contour_spec);
        % Plot the surface
        surf(x, y, out_surface, 'EdgeColor', 'none', 'LineStyle', 'none', 'FaceLighting', 'phong');
        colormap jet
        % For scaling
        caxis([0 1])
        axis equal
        % Include a colorbar
        colorbar
        % Set the view (top down)
        az = 0;   el = 90; view(az, el);
        %% CENTERING
        % Now, we want to center this map, using the extents of the data
        % Min X and Y of data (U N R O T A T E D)
        % offset border (in m)
        % Rounded to nearest 100 meter
        border = 50;
        axis([round(min(data_x) - border, -2), round(max(data_x) + border, -2), ...
            round(min(data_y) - border, -2), round(max(data_y) + border, -2)]);
        grid on

    end
    toc
    %% GEO FEATURES
    subplot(2, 2, 1);
    % Show the survey points
    mapshow(data, 'DisplayType','point','Marker','.','MarkerEdgeColor','blue');
    % Show the mound traces
    mapshow(dried_mounds, 'DisplayType', 'line', 'Color', 'red');
    % And the reef trace
    mapshow(dried_reef_trace, 'DisplayType', 'line', 'Color', 'black');
    % Print the map out
    print -painters -depsc dried_survey.eps

    %% NUMERIC OUTPUT
    % Total number of points
    point_count = length(comments);
    % Chart text
    chart_text = {'Presence of Outcrop', 'Presence of Microbial Facies',...
    'Presence of Skeletal Material', 'Presence of Cloudina Framework'};
    % Count of presence
    present = [nnz(out_points(:, 1)), nnz(out_points(:, 2)), nnz(out_points(:, 3)), nnz(out_points(:, 4))];
    % Count of absent
    absent = repmat(point_count, 1, 4) - present;
    % Percentage
    percentage = present ./ point_count * 100;
    %% PIE CHARTS
    figure
    subplot(4, 1, 1);
    pie_plot(out_points(:, 1), chart_text{1});
    subplot(4, 1, 2);
    pie_plot(out_points(:, 2), chart_text{2});
    subplot(4, 1, 3);
    pie_plot(out_points(:, 3), chart_text{3});
    subplot(4, 1, 4);
    pie_plot(out_points(:, 4), chart_text{4});
    % Print the pie chart out
    print -painters -depsc pie_charts.eps
    %% LATEX TABLE OUTPUT
    % We write to facies_table.tex
    fid = fopen('facies_table.tex', 'w');
    % Begin by entering a tabular environment
    fprintf(fid, '\\begin{tabular}{r r  r} \n');
    fprintf(fid, 'Description & Points Present & Percentage \\\\ \n');
    for f = 1:length(chart_text)
        fprintf(fid, '%s & %i & & %05.2f \\\\ \n', chart_text{f}, present(f), percentage(f)); 
    end
    fprintf(fid, '\\end{tabular} \n');
    %}
end

function [rotated_x, rotated_y] = rotate_data(x,y,rot_angle)
    rotated_x = x*cos(rot_angle) - y*sin(rot_angle);
    rotated_y = x*sin(rot_angle) + y*cos(rot_angle);
end

function pie_plot(points, title_string)
    % First, convert points to categories
    cats = categorical(points);
    % Count them
    counts = countcats(cats);
    % Convert to percentage (rounded)
    percents = round((counts ./ length(points)) * 100);
    % Labels
    labels = cellstr(num2str(percents));
    % Add percent signs
    labels = strcat(labels, '%');
    chart_handle = pie(cats, [], labels);
    for x = 2:2:length(labels)*2
        chart_handle(x).Position = chart_handle(x).Position * 1.0625;
    end
    % Add title
    title(title_string);
    % Change color
    pie_cmap = [0,0,0; 1,1,1];
    colormap(pie_cmap);
end