function output = produce_labeled_image(label, name, classified, storage)
    % First, load the data
    loaded_label = load_data(label, false, []);
    % Name
    struct_name = loaded_label.ordered{1};
    % Define all idx
    all_idx = loaded_label.all_idx.(struct_name);
    % Create a mxnxz matrix where mxn are the size of the label and z is
    % the number of classes
    [y_dim, x_dim, ~] = size(loaded_label.(struct_name));
    z_dim = size(classified, 1);
    output = zeros(y_dim,x_dim,z_dim);
    % Reshape
    reshaped = permute(classified, [3, 2, 1]);
    for x = 1:length(all_idx)
        idx_of_interest = all_idx{x};
        for y = 1:z_dim
            multiplier = y-1;
            output(idx_of_interest + (multiplier * y_dim * x_dim)) = reshaped(1, x, y);
        end
    end
    % Now, save this
    save(fullfile(storage, 'output_data', [name, '_final_output.mat']), 'output', '-v7.3');
    % And, in our case, output a max value matrix
    % First, we want to get the max value
    [~, max_idx] = max(output, [], 3);
    % Convert max_idx
    max_idx = uint8(max_idx);
    imwrite(max_idx, fullfile(storage, 'output_tiffs', [name, '_max_probability.tif']));
end

%{
function output = produce_labeled_image(label, name, classified, storage, class_of_interest)
    % First, load the data
    loaded_label = load_data(label, false, []);
    % Name
    struct_name = loaded_label.ordered{1};
    % Define all idx
    all_idx = loaded_label.all_idx.(struct_name);
    % Create a mxnxz matrix where mxn are the size of the label and z is
    % the number of classes
    [y_dim, x_dim, ~] = size(loaded_label.(struct_name));
    z_dim = size(classified, 1);
    output = zeros(y_dim,x_dim,z_dim);
    % Reshape
    reshaped = permute(classified, [3, 2, 1]);
    for x = 1:length(all_idx)
        idx_of_interest = all_idx{x};
        for y = 1:z_dim
            multiplier = y-1;
            output(idx_of_interest + (multiplier * y_dim * x_dim)) = reshaped(1, x, y);
        end
    end
    % Now, save this
    save(fullfile(storage, 'output_data', [name, '_final_output.mat']), 'output', '-v7.3');
    % And, in our case, output a matrix of probabilities for
    % the class of interest
    imwrite(output(:,:,class_of_interest), fullfile(storage, 'output_tiffs', [name, '_percent_probability.tif']));
end
%}