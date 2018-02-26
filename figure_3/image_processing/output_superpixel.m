function [label_matrix, number_labels] = output_superpixel(img, number_pixels)
    % Create superpixels
    [label_matrix, number_labels] = superpixels(img, number_pixels);
end