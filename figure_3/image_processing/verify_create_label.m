function output = verify_create_label(to_process, storage, gauss_filt, number_pixels)
    % Number of to_process
    number_process = length(to_process);
    output = cell(number_process, 1);
    % Loop through to_process, which should be a cell array
    for x = 1:number_process
        % First, retrieve the image file name
        [~, file_name, ~] = fileparts(to_process{x});
        % Label path 
        label_path = fullfile(storage, 'superpixels', [file_name, '_label.mat']);
        % Check to see if this file exists
        if exist(label_path, 'file') ~= 2
            % Oh shit, something doesn't exist
           disp(['Producing superpixels for ', file_name]);
           % Now, open the image
           img = imread(to_process{x});
           % Blur it 
           blurred_img = imgaussfilt(img, gauss_filt);
           % Generate the superpixels
           [label, ~] = output_superpixel(blurred_img, number_pixels);
           % Now, save the label
           save(label_path, 'label');
        end
        % Update output
        output{x} = label_path;
    end
end