function process_all_images(configuration_file)
    tic
    % Begin by loading in configuration_file
    load(configuration_file);
    % Set image directory
    img_dir = config.original_images;
    % Now, look for original images
    images = dir(fullfile(img_dir, ['*', config.ext]));
    % Produce a sorted listing
    % sorted_images = sort_dir_list(images, config.file_prefix);
    sorted_images = {images.name};
    % Define offsets, storage, gauss_filt, and number_pixels variables
    offsets = config.offsets;
    storage = config.storage;
    gauss_filt = config.gauss_filt;
    number_pixels = config.number_pixels;
    % Define the stats_matrix directory
    stat_dir = fullfile(storage, 'stats_matrix');
    % Check to make sure that a stats_matrix AND an output directory and
    % output_tiffs directory exist
    directory_test({stat_dir, fullfile(storage, 'output_data'), fullfile(storage, 'output_tiffs'), fullfile(storage, 'superpixels')});
    % Load in the neural network
    % Set boolean 
    trained_network = false;
    trained_network_path = fullfile(storage, 'trained_network', 'trained_net.mat');
    net = [];
    run_net = [];
    if exist(trained_network_path, 'file') == 2
        % Set boolean to true
        trained_network = true;
        % Load it
        net = load_single(trained_network_path);
        % Establish the training function
        run_net = @(data) net(data);
    end
    % At the same time, set the classified_path
    classified_path = fullfile(storage, 'classfied_data');
    directory_test({classified_path});
    % Now, parfor the list
    parfor x = 1:length(sorted_images)
        fprintf(['Processing image ', sorted_images{x}, '\n']);
        % this image full file name
        this_img = fullfile(img_dir, sorted_images{x});
        % Extract only this_img_name
        [~, this_name, ~] = fileparts(this_img);
        % Now, look for the statistics matrix
        stats = fullfile(stat_dir, [this_name, '_stats.mat']);
        % If a stats matrix doesn't exist, time to create one!
        if exist(stats, 'file') ~= 2
            no_stats = true;
        else
            no_stats = false;
            % Load in the stats matrix
            stats_matrix = load_single(stats);
        end
        % Check to see if offsets is empty
        if isempty(offsets)
            % Since we have no offsets, we just need to check to see if
            % this img has a stats file associated with it
            this_label = verify_create_label({this_img}, storage, gauss_filt, number_pixels);
            if no_stats
                img_struct.this_img = load_data({this_img}, true, false, '', true);
                img_struct.this_label = load_data(this_label, false, false, '', true);
                samples = 1:max(img_struct.this_label.(img_struct.this_label.ordered{1})(:));
                stats_matrix = produce_column_matrix(img_struct, samples);
                parsave_stats(stats, stats_matrix);
            end
        else
            % Produce adjacent images matricies
            [prev_img, next_img] = adj_image_list(x, sorted_images, img_dir, offsets);
            if ~isempty(prev_img) && ~isempty(next_img)
                % Great, these are the images we will process
                % Produce label images
                prev_label = verify_create_label(prev_img, storage, gauss_filt, number_pixels);
                this_label = verify_create_label({this_img}, storage, gauss_filt, number_pixels);
                next_label = verify_create_label(next_img, storage, gauss_filt, number_pixels);
                % If a stats matrix doesn't exist, time to create one!
                if no_stats
                    % Image structure - note how we can streamline this - load in
                    % the images first, and store them in the img_struct
                    % **** This needs to get replaced with a single function that
                    % loads in all associated images ****
                    img_struct = struct();
                    img_struct.prev_img = load_data(prev_img, true, false, '', true);
                    img_struct.this_img = load_data({this_img}, true, false, '', true);
                    img_struct.next_img = load_data(next_img, true, false, '', true);
                    img_struct.prev_label = load_data(prev_label, false, false, '', true);
                    img_struct.this_label = load_data(this_label, false, false, '', true);
                    img_struct.next_label = load_data(next_label, false, false, '', true);
                    % Get a list of unique labels in this_label
                    samples = 1:max(img_struct.this_label.(img_struct.this_label.ordered{1})(:));
                    stats_matrix = produce_column_matrix(img_struct, samples);
                    parsave_stats(stats, stats_matrix);
                end
            end
        end
        % Now, generate outputs using a trained network
        if trained_network
            classified = run_net(stats_matrix);
            % Save this
            parsave_classified(fullfile(classified_path, [this_name, '_classified.mat']), classified);
            % Finally, produce a labelled image
            produce_labeled_image(this_label, this_name, classified, storage);
        end
        fprintf(['Image ', sorted_images{x}, ' completed! \n']);
    end
    disp('All Done!');
    toc
end

