function data_structure = process_all_measurements(listing)
    % Listing is a mx5 cell array where the first column is the hx file,
    % the second is the csv file, the third is the voxel dimensions,...
    % the fourth is the rectangle structure, the fifth is the struct name, 
    % and the sixth is the full (display/figure) name
    % Begin by producing a data structure
    data_structure = struct();
    % Next, let's go through each listing
    number_populations = size(listing, 1);
    for x = 1:number_populations
        % This population structure name
        pop_name = listing{x, 5};
        % Process the hx file
        data_structure.(pop_name).hx_data = process_hx(listing{x, 1});
        % Process the csv file
        data_structure.(pop_name).stats = process_csv(listing{x, 2});
        % Next, let's add the MATLAB measurement structure ("rectangles)
        data_structure.(pop_name).stats = append_rect_data(data_structure.(pop_name).stats, listing{x, 4});
        % Link hx and CSV data
        data_structure.(pop_name) = combine_hx_csv(data_structure.(pop_name));
        % Next, let's compile ALL of the measurements
        data_structure.(pop_name).stats = compile_measurements(data_structure.(pop_name).stats, listing{x, 3});
        % Add the display name
        data_structure.(pop_name).display = listing{x, 6};
    end
    % Fantastic, now we're free to plot up as we want
    create_plots(data_structure);
end