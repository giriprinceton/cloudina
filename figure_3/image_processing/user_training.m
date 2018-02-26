function user_training(configuration_file)
    global global_collector;
    close all
    % First, load the config - the structure should be named config
    load(configuration_file);
    %% Directory Tests
    % Check to make sure that the storage, label images, output images
    % exist and if not, produce them
    % First, produce the directory listing
    directory_listing = {config.storage; fullfile(config.storage, 'superpixels')};
    % Then run directory_test
    directory_test(directory_listing);
    %% Process Superpixels + Produce Training Set
    % First, produce superpixels for each image in config
    for img_name = 1:length(config.image_list)
        % File to open
        to_open = config.image_list{img_name};
        % Get file name
        [~, file_name, ~] = fileparts(to_open);
        % Replace spaces with underscores
        file_name = strrep(file_name, ' ', '_');
        % Do the same for dashes
        file_name = strrep(file_name, '-', '_');
        % Open the image
        img = open_tiff(to_open);
        % Superpixels label and numbers name
        labels_name = fullfile(config.storage, 'superpixels', [file_name, '_label']);
        numbers_name = fullfile(config.storage, 'superpixels',[file_name, '_numbers']);
        % Now, check to see if the superpixels file already exist
        superpixel_exist = search_struct(config, {'superpixels', file_name});
        if (~superpixel_exist)
            % Let the user know we're going to make a superpixel
            disp(['Creating superpixels for image ', file_name]);
            % Blur the image
            blurred_img = imgaussfilt(img, config.gauss_filt);
            % Get the superpixels
            [label, ~] = output_superpixel(blurred_img, config.number_pixels);
            % We do not need to store both the label and number matricies
            save(labels_name, 'label');
            config.superpixels.(file_name) = true;
            % Save the config structure
            save(configuration_file, 'config');
            % Confirm that the superpixel was created
            disp('Superpixels created');
        else
            load(labels_name);
        end
        % Now, with this image open, let's start training
        % BW boundaries from label image
        bw_mask = boundarymask(label);
        % First, display the image
        image = imshow(imoverlay(img, bw_mask, 'cyan'));
        % Add UI element
        btn = uicontrol('Style', 'pushbutton',...
            'Position', [20 20 150 20],...
            'Callback', @resume_callback);
        % Get the image size
        [img_y, img_x, ~] = size(img);
        two_d_img = [img_y, img_x];
        % Now, loop through the classes in config

        % Number of classes
        number_classes = length(config.classes);
        for y = 1:number_classes
            % Create a mask overlay
            % First, produce an influence matrix
            influence = zeros(two_d_img);
            mask_elements = ones(two_d_img);
            hold on
            mask = imshow(mask_elements);
            hold off
            mask.AlphaData = influence;
            mask.ButtonDownFcn = {@cursor_callback, label, mask};
            mask.HitTest = 'on';
            % Show graph window; bring the image to the front
            shg;
            % Now, check to see if there are any existing classes
            % Note that this can become a function!
            class_exists = search_struct(config, {'superpixels_training', config.classes{y}, file_name});
            % Set the global collector
            % If class training already exists, then load it in
            if class_exists
                global_collector = config.superpixels_training.(config.classes{y}).(file_name);
                % Update the influence mask
                influence(find(ismember(label, global_collector))) = 1;
                mask.AlphaData = influence;
            else
                global_collector = [];
            end
            % Set the button string
            button_string = 'Next Class';
            if y == number_classes
                button_string = 'Finish Image';
            end
            btn.String = button_string;
            title(['Defining ', config.classes{y}, ' Class']);
            % Now, wait until continue is hit
            uiwait
            % Now, let's go through and save these values
            % First, in the structure
            config.superpixels_training.(config.classes{y}).(file_name) = global_collector;
            % And then save the structure
            save(configuration_file, 'config');
            % Delete the mask
            delete(mask)
            % Move on
            if y == number_classes
                close;
            end
        end
    end
end