function create_plots(data)
    close all
    % Here, we produce a bunch of different plots for publication
    % Colors
    colors = [245, 93, 62;...
        247, 203, 21; ...
        55, 50, 62;...
        75, 136, 162];
    colors = colors ./ 255;
    %% PLOTS
    
    % Length vs. diameter
    length_diameter = figure;
    title('Length vs. Outer Diameter');
    grid on
    xlabel('Length, microns');
    ylabel('Outer Diameter Semi-Major Axis, microns');
    axis square
    hold on
    
    % Diameter Histograms
    diameter_hists = figure;
    hold on
    % Every 0.5mm centers
    hist_edges = centers_to_edges(0:500:6000);
    
    % Aspect Ratio Plot
    aspect_ratio = figure;
    title('Semi-Major vs. Semi-Minor Outer Diameters');
    hold on
    grid on
    xlabel('Outer Diameter Semi-Major Axis, microns');
    ylabel('Outer Diameter Semi-Minor Axis, microns');
    axis square
    
    % Semi minor axis orientation
    semi_minor_plot = figure;
    title('Semi-Minor Outer Axis Plunge');
    hold on
    grid on
    plunge_hist_centers = 0:10:90;
    plunge_hist_edges = centers_to_edges(plunge_hist_centers);
    
    
    %{
    curvature = figure;
    title('Curvature vs. Diameter');
    xlabel('Outer Diameter Semi-Major Axis');
    ylabel('Mean Curvature');
    hold on
    grid on
    %}
    % Comparing diameters from previous researchers -> resorted by date and
    % name
    diameter_comp = figure;
    % ranges = [100, 2000; 2500, 6500; 300, 1300;1000, 9000; 1000, 4000; 500, 2900; 1000, 3500; 1000, 4000];
    % ranges_labels = {'Cai, 2014', 'Grant, 1990', 'Grant, 1990', 'Wood 2016','Cortijo 2014', 'Kontorovich, 2008', 'Warren, 2011', 'Morris, 1990'};
    ranges_labels = {'Grant, 1989', 'Grant, 1989', 'Morris, 1990', 'Hofmann 2001' 'Kontorovich, 2008', ...
        'Warren, 2011', 'Cai, 2014', 'Cortijo 2014', 'Wood 2016'};
    ranges = [2500, 6500; 300, 1300; 1000, 4000; 3400, 4200; 500, 2900; 1000, 3500; 100, 2000; 1000, 4000; 1000, 9000];
    % Flip direction so that oldest papers plot on the top
    ranges_labels = flip(ranges_labels, 2);
    ranges = flip(ranges, 1);
    % Semi minor collector
    semi_minor_ranges = [];
    %% PLOTTING
    % How many compiled populations?
    pop_names = fieldnames(data);
    % Number of populations
    num_pop = length(pop_names);
    semi_minor_histograms = cell(num_pop, 1);
    for x = 1:num_pop
        % Now, loop through individuals
        individuals = fieldnames(data.(pop_names{x}).stats);
        % Get number of individuals
        num_individuals = length(individuals);
        
        % Collectors -> seriously, clean this up, it's super shitty
        spline_lengths = [];
        out_maj_median = [];
        out_min_median = [];
        out_maj_max = [];
        out_min_max = [];
        out_maj_min = [];
        out_min_min = [];
        mean_curv = [];
        trend_plunge = cell(1, 1, num_individuals);
        semi_major_orient = [];
        semi_minor_orient = [];
        percent_growth = [];
        
        for y = 1:num_individuals
            % Define these measures
            these_measures = data.(pop_names{x}).stats.(individuals{y}).compiled_measurements;
            spline_lengths = [spline_lengths; these_measures.spline_length];
            out_maj_median = [out_maj_median; these_measures.median_outer(1)];
            out_min_median = [out_min_median; these_measures.median_outer(2)];
            out_maj_max = [out_maj_max; these_measures.max_outer(1)];
            out_min_max = [out_min_max; these_measures.max_outer(2)];
            out_maj_min = [out_maj_min; these_measures.min_outer(1)];
            out_min_min = [out_min_min; these_measures.min_outer(2)];
            mean_curv = [mean_curv; mean(these_measures.spline_curvature)];
            trend_plunge{:,:,y} = these_measures.trend_plunge;
            semi_major_orient = [semi_major_orient; [repmat(y, size(these_measures.outer_major_trend_plunge, 1), 1), ...
                these_measures.outer_major_trend_plunge]];
            semi_minor_orient = [semi_minor_orient; [repmat(y, size(these_measures.outer_minor_trend_plunge, 1), 1), ...
                these_measures.outer_minor_trend_plunge]];
            percent_growth = [percent_growth; these_measures.percent_growth];
        end
        
        %% Report some statistics
        
        % Define percentiles matrix
        percent_matrix = [25, 50, 75];
        % Define aspect ratio
        calculated_ratio = double(out_min_median) ./ double(out_maj_median);
        disp(sprintf([(pop_names{x}), ' Statistics: \n', ...
            '____', '\n', ...
            'Percentiles Major Axis: ', num2str(round(prctile(double(out_maj_median), percent_matrix)/1000, 1)), '\n', ...
            'Percentiles Minor Axis: ', num2str(round(prctile(double(out_min_median), percent_matrix)/1000, 1)), '\n', ...
            'Mean Length: ', num2str(mean(spline_lengths)), '\n', ...
            '1 sigma Length: ', num2str(std(spline_lengths)), '\n', ...
            'Percentiles Length: ', num2str(round(prctile(spline_lengths, percent_matrix)/1000, 1)), '\n', ...
            'Mean percent growth: ', num2str(mean(percent_growth)), '\n'...
            'STD percent growth: ', num2str(std(percent_growth)), '\n', ...
            'Percentiles Aspect Ratios: ', num2str(round(prctile(calculated_ratio, percent_matrix), 2)), '\n', ...
            '\n']));
        
        %% Produce Figures
        
        % Length vs. Diameter Figure
        figure(length_diameter);
        scatter(spline_lengths, out_maj_median, [], colors(x,:));
        add_min_max([spline_lengths, out_maj_median], out_maj_min, out_maj_max, 'vert', colors(x, :));
        
        % Aspect Ratio Figure
        figure(aspect_ratio);
        aspect_data = [out_maj_median, out_min_median];
        scatter(aspect_data(:,1), aspect_data(:,2), [], colors(x,:));
        add_min_max(aspect_data, out_min_min, out_min_max, 'vert', colors(x, :));
        add_min_max(aspect_data, out_maj_min, out_maj_max, 'horz', colors(x, :));
        
        % Histograms Figure
        figure(diameter_hists);
        subplot(num_pop, 1, x);
        histogram(out_maj_median, hist_edges, 'Normalization', 'probability', 'FaceColor', colors(x, :));
        axis square
        title([data.(pop_names{x}).display, ' Histogram']);
        xlabel('Diameter, microns');
        ylabel('Fraction');
        xlim([0 6000]);
        
        % Export Trend and Plunge
        for y = 1:num_individuals
            to_write = trend_plunge{:,:,y};
            file_to_write = fullfile('Trend_Plunge_Data', 'csv_files', [pop_names{x}, '_tube_', num2str(y), '.csv']);
            fid = fopen(file_to_write, 'w');
            fprintf(fid, '%s\n', 'TP');
            fclose(fid);
            dlmwrite(file_to_write, to_write,'-append');
        end
        
        % Semi Minor Plunge Orientation
        [semi_minor_histograms{x}, ~] = histcounts(semi_minor_orient(:,3), plunge_hist_edges, 'Normalization', 'probability');
        
        pd = fitdist(semi_minor_orient(:,3), 'Normal');
        
        % Add to ranges plot
        if strcmp(pop_names{x}, 'zrFill')
            b_point = 2000;
            % Lower ranges
            ranges = [min(out_maj_min(out_maj_min < b_point)), max(out_maj_max(out_maj_max < b_point)); ranges];
            semi_minor_ranges = [min(out_min_min(out_maj_min < b_point)), max(out_min_max(out_maj_max < b_point)); semi_minor_ranges];
            ranges_labels = [data.(pop_names{x}).display, ranges_labels];
            % Upper ranges
            ranges = [min(out_maj_min(out_maj_min > b_point)), max(out_maj_max(out_maj_max > b_point)); ranges];
            semi_minor_ranges = [min(out_min_min(out_maj_min > b_point)), max(out_min_max(out_maj_max > b_point)); semi_minor_ranges];
            ranges_labels = [data.(pop_names{x}).display, ranges_labels];
        elseif strcmp(pop_names{x}, 'salient')
            b_point = 3500;
            % Lower ranges
            ranges = [min(out_maj_min(out_maj_min < b_point)), max(out_maj_max(out_maj_max < b_point)); ranges];
            semi_minor_ranges = [min(out_min_min(out_maj_min < b_point)), max(out_min_max(out_maj_max < b_point)); semi_minor_ranges];
            ranges_labels = [data.(pop_names{x}).display, ranges_labels];
            % Upper ranges
            ranges = [min(out_maj_min(out_maj_min > b_point)), max(out_maj_max(out_maj_max > b_point)); ranges];
            semi_minor_ranges = [min(out_min_min(out_maj_min > b_point)), max(out_min_max(out_maj_max > b_point)); semi_minor_ranges];
            ranges_labels = [data.(pop_names{x}).display, ranges_labels];
        else
            ranges = [min(out_maj_min), max(out_maj_max); ranges];
            ranges_labels = [data.(pop_names{x}).display, ranges_labels];
            semi_minor_ranges = [min(out_min_min), max(out_min_max); semi_minor_ranges];
        end

        % Export semi major axis orientation data
        csvwrite([pop_names{x}, '_semi_major_orientation.csv'], semi_major_orient);
        
        % Export semi minor axis orientation data
        csvwrite([pop_names{x}, '_semi_minor_orientation.csv'], semi_minor_orient);

    end
    %% Additional Plotting and printing
    
    % Length vs. Diameter
    figure(length_diameter);
    ylim([0, max(ylim)]);
    % print it
    print -painters -depsc Stat_Plots/length_vs_diameter.eps
    
    % Aspect Ratio Plot
    figure(aspect_ratio);
    ylim([0, max(ylim) + 500]);
    xlim([0, max(ylim)]);
    limits = [xlim; ylim];
    max_diameter = max(limits(:));
    diameter_line = [0:max_diameter];
    % One to one line
    plot(diameter_line, diameter_line, '--', 'Color', 'black');
    % One to one_half line
    plot(diameter_line, diameter_line * .5, '--', 'Color', 'black');
    % print it
    print -painters -depsc Stat_Plots/aspect_ratio.eps
    
    % Diameter Ranges Plot
    figure(diameter_comp)
    hold on
    for y = 1:length(ranges)
        line([ranges(y,1), ranges(y,2)], [y,y]);
    end
    % Also plot the semi-minor measurements (in red)
    for y = 1:length(semi_minor_ranges)
        line([semi_minor_ranges(y,1), semi_minor_ranges(y,2)], [y,y], 'Color', 'red');
    end
    ylim([0, length(ranges) + 1]);
    % legend(ranges_labels);
    yticks(1:length(ranges))
    yticklabels(ranges_labels)
    xlabel('Diameter, microns');
    % Add 1000 microns to the limits
    xlim([0, max(xlim) + 1000]);
    grid on
    % Set aspect ratio
    pbaspect([1, 1, 1]);
    % print it
    print -painters -depsc Stat_Plots/diameter_ranges.eps
    
    % Diameter Histograms
    figure(diameter_hists)
    print -painters -depsc Stat_Plots/diameter_histograms.eps
    
    % Plunge Histograms
    figure(semi_minor_plot);
    % Load in the rotated salient measurements
    rotated_salient = csvread('rotated_salient_mountain_semi_minor_trend_plunge.csv');
    % And the rotated thicketB measurements
    rotated_thicketB = csvread('rotated_thicketB_semi_minor_trend_plunge.csv');
    
    % Now, replace semi_minor_histograms{3} with the rotated salient data
    semi_minor_histograms{4} = histcounts(rotated_salient(:,2), plunge_hist_edges, 'Normalization', 'probability');
    % Do the same for thicketB
    semi_minor_histograms{2} = histcounts(rotated_thicketB(:,2), plunge_hist_edges, 'Normalization', 'probability');

    plunge_bar = bar(plunge_hist_centers', [semi_minor_histograms{1}', semi_minor_histograms{2}', semi_minor_histograms{3}', semi_minor_histograms{4}'], 1.0);
    
    for x = 1:num_pop
        plunge_bar(x).FaceColor = colors(x, :);
    end
    

    
    % Uniform distribution
    plunge_angles = 0:.01:90;
    uni_dist = makedist('Uniform', 'lower', 0, 'upper', 90);
    uni_pdf = pdf(uni_dist, plunge_angles);
    hold on
    stairs(plunge_angles, uni_pdf);
    % HalfNormal Distribution
    hf_dist = makedist('Normal', 'sigma', 1, 'mu', 90);
    hf_pdf = pdf(hf_dist, plunge_angles);
    plot(plunge_angles, hf_pdf, '-'); 
    xlim([-10, 100]);
    pbaspect([3, 2.25, 1]);
    print -painters -depsc Stat_Plots/plunge_histogram.eps
end

function add_errors(data, errors, direction, color)
    % Data is values and errors should be single std
    % First, check direction
    if strcmp(direction, 'vert')
        to_add = data(:,2);
    else
        to_add = data(:,1);
    end
    bar_lower = to_add - errors;
    bar_upper = to_add + errors;
    % Ugh, we have to use a for plot
    for x = 1:length(data)
        if strcmp(direction, 'vert')
            line([data(x,1), data(x,1)], [bar_lower(x), bar_upper(x)], 'Color', color);
        else
            line([bar_lower(x), bar_upper(x)], [data(x,2), data(x,2)], 'Color', color);
        end
    end
end

function add_min_max(data, lower, upper, direction, color)
    for x = 1:size(data, 1)
        if strcmp(direction, 'vert')
            line([data(x, 1), data(x, 1)], [lower(x), upper(x)], 'Color', color);
        else
            line([lower(x), upper(x)], [data(x, 2), data(x, 2)], 'Color', color);
        end
    end
end

function edges = centers_to_edges(centers)
    d = diff(centers)/2;
    edges = [centers(1) - d(1), centers(1:end-1) + d, centers(end) + d(end)];
    edges(2:end) = edges(2:end) + eps(edges(2:end));
end

        %{ 
            'Mean Major: ', num2str(median(out_maj_dia)), '\n', ...
            'STD Major: ', num2str(std(out_maj_dia)), '\n',...
            'Mean Minor: ', num2str(mean(out_min_dia)), '\n', ...
            'STD Minor: ', num2str(std(out_min_dia)), '\n',...
            ratio = out_min_median./out_maj_median;

            disp(sprintf([(pop_names{x}), ' Statistics: \n', ...
            '____', '\n', ...
            'PCT Major: ', num2str(prctile(double(out_maj_dia), [2.5, 97.5])), '\n', ...
            'PCT Minor: ', num2str(prctile(double(out_min_dia), [2.5, 97.5])), '\n', ...
            'Mean Length: ', num2str(mean(spline_lengths)), '\n', ...
            'STD Length: ', num2str(std(spline_lengths)), '\n' ...
            'Min Aspect: ', num2str(min(ratio)), '\n',...
            'Max Aspect: ', num2str(max(ratio)), '\n', ...
            'Mean Aspect: ', num2str(mean(ratio)), '\n' ...
            'STD Aspect: ', num2str(std(ratio)), '\n'...
            'Mean percent growth: ', num2str(mean(percent_growth)), '\n'...
            'STD percent growth: ', num2str(std(percent_growth)), '\n', ...
            '\n']));
        %}
        %{
        figure(curvature);
        scatter(out_maj_dia, mean_curv, [], colors(x,:));
        figure(diameter_hists);
        subplot(num_pop, 1, x);
        histogram(out_maj_dia, hist_edges, 'Normalization', 'probability', 'FaceColor', 'black');
        axis square
        title([data.(pop_names{x}).display, ' Histogram']);
        xlabel('Diameter, microns');
        ylabel('Proportion');
        xlim([0 6000]);
        grid on
        ranges = [ranges; min(out_maj_min), max(out_maj_max)];
        ranges_labels = [ranges_labels, data.(pop_names{x}).display];
        % Export semi major axis orientation data
        csvwrite([pop_names{x}, '_semi_major_orientation.csv'], semi_major_orient);
        %}