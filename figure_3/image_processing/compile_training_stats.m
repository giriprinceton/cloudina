function compile_training_stats(configuration_file)
    close
    % Okay, let's load the configuration file first
    load(configuration_file);
    % First, number of classes
    number_classes = length(config.classes);
    % Also, number of images
    number_images = length(config.image_list);
    % Okay, let's build an input matrix, where each
    % column is a data point and each row is a stat
    % At the same time, let's produce an output matrix where each column 
    % is a data point and each row is a class.
    input_matrix = [];
    output_matrix = [];
    for x = 1:number_images
        % This image
        image = config.image_list{x};
        [~, image_name, ~] = fileparts(image);
        % First step, produce the adjacent image and label list
        [prev_img, this_img, next_img, prev_label,...
            this_label, next_label] = produce_labels(config, image);
        % Next, open everything and store into a structure
        % First, the structure
        disp('Loading Data');
        img_struct = struct();
        % LOAD DATA - STREAMLINE!
        img_struct.prev_img = load_data(prev_img, true, false, '', true);
        img_struct.this_img = load_data(this_img, true, false, '', true);
        img_struct.next_img = load_data(next_img, true, false, '', true);
        img_struct.prev_label = load_data(prev_label, false, false, '', true);
        img_struct.this_label = load_data(this_label, false, false, '', true);
        img_struct.next_label = load_data(next_label, false, false, '', true);
        disp('Data Loaded');
        % Now, we need to iterate through each class for this image
        waiting = waitbar(0, 'Compiling Training Stats');
        for y = 1:number_classes
            % Search superpixels training to find the samples
            samples_exist = search_struct(config, {'superpixels_training', config.classes{y}, image_name});
            if samples_exist
                samples = config.superpixels_training.(config.classes{y}).(image_name);
                % Produce the stats matrix
                stats_matrix = produce_column_matrix(img_struct, samples);
                % Produce a class matrix - essentially number_classes *
                % length(samples)
                class_matrix = zeros(number_classes, length(samples));
                class_matrix(y, :) = 1;
                % Append to the input and output matricies
                input_matrix = [input_matrix, stats_matrix];
                output_matrix = [output_matrix, class_matrix];
            end
            waitbar(y/number_classes);
        end
        close(waiting);
    end
    % Display 
    disp('Training Stats Produced!');
    % Save training stats
    directory_test({fullfile(config.storage, 'training_data')});
    save(fullfile(config.storage, 'training_data', 'input_matrix.mat'), 'input_matrix');
    save(fullfile(config.storage, 'training_data', 'output_matrix.mat'), 'output_matrix');
    disp('All Done!');
end
%{
function compile_training_stats(configuration_file)
    close
    % Okay, let's load the configuration file first
    load(configuration_file);
    % First, number of classes
    number_classes = length(config.classes);
    % Also, number of images
    number_images = length(config.image_list);
    % Okay, let's build an input matrix, where each
    % column is a data point and each row is a stat
    % At the same time, let's produce an output matrix where each column 
    % is a data point and each row is a class.
    input_matrix = [];
    output_matrix = [];
    for x = 1:number_images
        % This image
        image = config.image_list{x};
        [~, image_name, ~] = fileparts(image);
        % First step, produce the adjacent image and label list
        [prev_img, this_img, next_img, prev_label,...
            this_label, next_label] = produce_labels(config, image);
        % Next, open everything and store into a structure
        % First, the structure
        disp('Loading Data');
        img_struct = struct();
        % Maybe one day this can be streamlined? Screw this
        img_struct.prev_img = load_data(prev_img, true, config.gauss_filt);
        img_struct.this_img = load_data(this_img, true, config.gauss_filt);
        img_struct.next_img = load_data(next_img, true, config.gauss_filt);
        img_struct.prev_label = load_data(prev_label, false, config.gauss_filt);
        img_struct.this_label = load_data(this_label, false, config.gauss_filt);
        img_struct.next_label = load_data(next_label, false, config.gauss_filt);
        disp('Data Loaded');
        % Now, we need to iterate through each class for this image
        for y = 1:number_classes
            % Search superpixels training to find the samples
            samples_exist = search_struct(config, {'superpixels_training', config.classes{y}, image_name});
            if samples_exist
                tic
                samples = config.superpixels_training.(config.classes{y}).(image_name);
                % Produce the stats matrix
                stats_matrix = produce_column_matrix(img_struct, samples);
                % Produce a class matrix - essentially number_classes *
                % length(samples)
                class_matrix = zeros(number_classes, length(samples));
                class_matrix(y, :) = 1;
                toc
                % Append to the input and output matricies
                input_matrix = [input_matrix, stats_matrix];
                output_matrix = [output_matrix, class_matrix];
            end
        end
    end
    
    % Display 
    disp('Training Stats Produced!');
    % Save training stats
    directory_test({fullfile(config.storage, 'training_data')});
    save(fullfile(config.storage, 'training_data', 'input_matrix.mat'), 'input_matrix');
    save(fullfile(config.storage, 'training_data', 'output_matrix.mat'), 'output_matrix');
    disp('All Done!');
end
%}