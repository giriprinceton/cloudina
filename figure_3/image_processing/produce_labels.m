function [prev_img, this_img, next_img, prev_label, this_label, next_label] = produce_labels(config, img)
    this_img = {img};
    [~, img_name, ext] = fileparts(img);
    storage = config.storage;
    gauss_filt = config.gauss_filt;
    number_pixels = config.number_pixels;
    
    % Set image directory
    img_dir = config.original_images;
    % Now, look for original images
    images = dir(fullfile(img_dir, '*.tif'));
    % Produce a sorted listing
    sorted_images = sort_dir_list(images, config.file_prefix);
    % Retrieve the index for this image
    index = find(ismember(sorted_images, [img_name,ext]));
    
    % Check to see that a superpixels directory exists
    directory_test({fullfile(config.storage, 'superpixels')});
    
    % Get a listing of adjacent images, as according to the config.offsets
    % value
    
    [prev_img, next_img] = adj_image_list(index, sorted_images, config.original_images, config.offsets);

    % Great, now for the image, prev, and next, a) check to see if a label
    % image exists and b) if it does not, produce one
    prev_label = verify_create_label(prev_img, storage, gauss_filt, number_pixels);
    this_label = verify_create_label(this_img, storage, gauss_filt, number_pixels);
    next_label = verify_create_label(next_img, storage, gauss_filt, number_pixels);
    
    % Completed!
    disp('All Done With Labels!');
end