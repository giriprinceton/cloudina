function [column_matrix] = produce_column_matrix(data, samples)
        % this label
        this_label = data.this_label.(data.this_label.ordered{1});
        % all idx
        all_idx = data.this_label.all_idx.(data.this_label.ordered{1});
        % get the centroids of each superpixel of this label
        stats = regionprops(this_label, 'Centroid');
        % Begin by getting the size of this_img, which is the same as the
        % 2D size of this_img
        [img_y, img_x] = size(this_label);
        column_matrix = [];
        % Loop through samples
        for x = 1:length(samples)
            %% Starting off, we would like to figure out the sample center
            % we want to know the centroid coordinate of this sample
            centers = stats(samples(x)).Centroid;
            % fix those coordinates
            centers = fix(centers);
            % get the index
            % note that centers is horizontal, vertical coordinates order
            centers_idx = sub2ind([img_y, img_x], centers(2), centers(1));
            %% Next, let's produce a column to put into the column matrix
            % Begin with the image of note, and then the previous and next
            % images
            %{
            col = [write_col(data.this_img.(data.this_img.ordered{1}),...
                data.this_img.([data.this_img.ordered{1}, '_lab']), ...
                all_idx{samples(x)}); ...
                process_adj(data, 'prev', centers_idx); ...
                process_adj(data, 'next', centers_idx)];
            %}
            col = [write_col(data.this_img.(data.this_img.ordered{1}),...
                data.this_img.([data.this_img.ordered{1}, '_lab']), ...
                all_idx{samples(x)})];  
            column_matrix = [column_matrix, col];
        end
end

function value_matrix = produce_value_matrix(data, idx)
    % Only works for 2D and 3D matricies!
    % Get data x y z
    [data_y, data_x, data_z] = size(data);
    value_matrix = [];
    for x = 1:data_z
        multiplier = x - 1;
        values = data(idx + (multiplier * data_y * data_x));
        value_matrix = [value_matrix, values];
    end
end

function col = write_col(rgb_img, lab_img, idx)
    %% Create column from rgb and lab vals
    % Define the rgb vals
    rgb_vals = produce_value_matrix(rgb_img, idx);
    % Define the lab vals
    lab_vals = produce_value_matrix(lab_img, idx);
    col = [double(mean(rgb_vals)), std(double(rgb_vals)),...
        reshape(cov(double(rgb_vals)), 1, []), ...
        double(mean(lab_vals)), std(lab_vals),...
        reshape(cov(lab_vals), 1, []), ...
        double(entropy(reshape(double(rgb_vals), [], 1, 3)))]';
end

function col = process_adj(data, direction, idx_to_examine)
    %% Process all prior and next images
    % Output column matrix
    col = [];
    % Build *_img and *_label tags
    img_tag = [direction, '_img'];
    label_tag = [direction, '_label'];
    % Get the list of ordered images
    to_process_img = data.(img_tag).ordered;
    % Now, process each of the ordered images
    for x = 1:length(to_process_img)
        % This label
        this_label = [to_process_img{x}, '_label'];
        % Extract the label value at the idx of interest
        value = data.(label_tag).(this_label)(idx_to_examine);
        % Get all of the indicies of this value
        all_idx = data.(label_tag).all_idx.(this_label){value};
        % Process
        col = [col; write_col(data.(img_tag).(to_process_img{x}),...
            data.(img_tag).([to_process_img{x}, '_lab']),...
            all_idx)];
    end
end

%{
function [column_matrix] = produce_column_matrix(data, samples)
        % this_img
        this_img = data.this_img.(data.this_img.ordered{1});
        % this label
        this_label = data.this_label.(data.this_label.ordered{1});
        % all idx
        all_idx = data.this_label.all_idx.(data.this_label.ordered{1});
        % get stats of this label
        stats = regionprops(this_label, 'Centroid');
        % Begin by getting the size of this_img
        [img_y, img_x, ~] = size(this_img);
        % Before starting, produce a L*a*b space image
        % disp('Producing a L*a*b image');
        lab_img = rgb2lab(this_img);
        % disp('L*a*b image produced');
        column_matrix = [];
        % Loop through samples
        for x = 1:length(samples)
            % we want to know the centroid coordinate of this sample
            centers = stats(samples(x)).Centroid;
            % now, we want the fix
            centers = fix(centers);
            % get the index
            % note that centers is horizontal, vertical coordinates order
            centers_idx = sub2ind([img_y, img_x], centers(2), centers(1));
            % get idx
            [idx] = all_idx{samples(x)}; 
            % Produce RGB col matrix
            rgb = produce_value_matrix(this_img, idx);
            % And a L channel 
            l_channel = lab_img(idx);
            % Now, the column matrix to be inserted into the
            % input_matrix. First, mean R, G, and B values, next
            % std R, G, and B values, then covariance of R, G, and
            % B values, after which the mean and std of 
            % the L channel. Finally, include an entropy term
            % Now, we need to include adjacent images as well
            col = [mean(rgb), std(double(rgb)),...
                reshape(cov(double(rgb)), 1, []), mean(l_channel),...
                std(double(l_channel)), entropy(reshape(rgb, [], 1, 3))]';
            % Now, include previous AND next layer(s)
            col = [col; process_adj(data, 'prev', centers_idx); process_adj(data, 'next', centers_idx)];
            column_matrix = [column_matrix, col];
        end
end

function value_matrix = produce_value_matrix(data, idx)
    % Only works for 2D and 3D matricies!
    % Get data x y z
    [data_y, data_x, data_z] = size(data);
    value_matrix = [];
    for x = 1:data_z
        multiplier = x - 1;
        values = data(idx + (multiplier * data_y * data_x));
        value_matrix = [value_matrix, values];
    end
end

function output_col = process_adj(data, direction, idx_to_examine)
    % Output column matrix
    output_col = [];
    % Build *_img and *_label tags
    img_tag = [direction, '_img'];
    label_tag = [direction, '_label'];
    % Begin, looking at the list of ordered images.
    to_process_img = data.(img_tag).ordered;
    for x = 1:length(to_process_img)
        % First, produce label name
        this_label = [to_process_img{x}, '_label'];
        % First, retrieve the value at the provided idx
        value = data.(label_tag).(this_label)(idx_to_examine);
        % Now, find indicies that relate to this value
        all_idx = data.(label_tag).all_idx.(this_label){value};
        % Get RGB values of associated image
        rgb_vals = produce_value_matrix(data.(img_tag).(to_process_img{x}), all_idx);
        % Now, append to the output column matrix. Values are: mean rgb,
        % std rgb, cov rgb, and entropy
        output_col = [output_col; [mean(rgb_vals), std(double(rgb_vals)),...
            reshape(cov(double(rgb_vals)), 1, []),...
            entropy(reshape(rgb_vals, [], 1, 3))]'];
    end
end
%}