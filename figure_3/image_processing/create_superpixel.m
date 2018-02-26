function [label_matrix, input_matrix] = create_superpixel(img_location)
    % Load the image
    img = imread(img_location);
    % Get image metadata, such as height and width
    [img_rows, img_cols, ~] = size(img);
    % Create a L*a*b version of the image
    img_lab = rgb2lab(img);
    % Blur the image, std is 2
    blurred_img = imgaussfilt(img, 2);
    % Convert blurred image to L*a*b
    blurred_img_lab = rgb2lab(blurred_img);
    % Create superpixels
    [label_matrix, number_labels] = superpixels(blurred_img_lab, 25000, 'isInputLab', true);
    % Get indicies of all labels
    label_idx = label2idx(label_matrix);
    % Now, feed this into a loop to produce: an m x n
    % matrix where m is r, g, b mean (3), rgb covariance (9), rgb std (3), luminance mean (1),
    % luminance std (1), and some form of entropy AND n is the number of
    % regions
    % Produce this input (confusing name, I know)
    number_inputs = 18;
    input_matrix = zeros(number_inputs, number_labels);
    for x = 1:number_labels
        indicies = label_idx{x};
        % Define input column
        input_col = zeros(number_inputs, 1);
        % Now, retrieve the RGB indicies - this can all be streamlined in
        % the future
        r_idx = indicies;
        g_idx = indicies + img_rows * img_cols;
        b_idx = indicies + 2 * img_rows * img_cols;
        % Produce RGB col matrix
        rgb_col_matrix = [img(r_idx), img(g_idx), img(b_idx)];
        % Mean R, G, and B values
        input_col(1:3, 1) = mean(rgb_col_matrix);
        % Covariance
        input_col(4:12) = reshape(cov(double(rgb_col_matrix)), [],1);
        % Standard Deviation
        input_col(13:15) = std(double(rgb_col_matrix));
        % Get luminance mean and std - note that we can use indicies since
        % we only care about the first layer of the lab image
        input_col(16) = mean(img_lab(indicies));
        input_col(17) = std(img_lab(indicies));
        % Finally get entropy
        input_col(18) = entropy(reshape(rgb_col_matrix, [], 1, 3));
        input_matrix(:, x) = input_col;
    end
end
    