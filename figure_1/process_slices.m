function [avg_dia, median_dia, all_feret_diameters, to_montage] = process_slices(slices_directory, to_select, scale_factor)
    % Okay, let's process all the slices, and select n at random to show
    % Lets get a directory listing of all .mat
    slice_names = dir(fullfile(slices_directory, '*.mat'));
    num_slices = length(slice_names);
    % Randomly select
    idxs = randsample(num_slices, to_select);
    % Image collector
    % collector = struct();
    collector = cell(num_slices,1);
    % waiting = waitbar(0,'Processing Slices');
    % Great, now loop through and extract information from each slice
    parfor x = 1:num_slices
        % First, load the slice
        slice = load(fullfile(slices_directory, slice_names(x).name));
        data = slice.data;
        [~, name_only, ~] = fileparts(slice_names(x).name);
        % What are the properites of the whole image? Note the cast to uint8!
        % This prevents regionprops from treating discontinuous regions as
        % different regions
        whole_image = regionprops(uint8(data), 'BoundingBox');
        % Next, extract individual region properties
        [labels, count] = bwlabel(data);
        % Aggregators
        feret_dia_aggregate = zeros(count, 1);
        for r = 1:count
            % Is creating a new matrix of zeros really the best way to do
            % this? There should be a better way (or at least some way to
            % skip a step)
            to_measure = data;
            to_measure(labels ~= count) = 0;
            % Note that orientation is angle between the x axis and the
            % major axis of the fitted ellipse!
            region_measures = regionprops(to_measure, 'BoundingBox', 'Orientation');
            % Now, rotate the image OR multiple imFeretDiameters
            % angle_range = 1:.1:180;
            % feret_dia_aggregate(count) = min(imFeretDiameter(to_measure, angle_range));
            rotated_data = imrotate(to_measure, 90-region_measures.Orientation, 'nearest', 'loose');
            feret_dia_aggregate(count) = imFeretDiameter(rotated_data, 0, 1);
        end
        storage_struct = struct();
        storage_struct.name_only = name_only;
        storage_struct.bbox = whole_image.BoundingBox;
        storage_struct.data = data;
        storage_struct.feret = feret_dia_aggregate;
        collector{x} = storage_struct;
        % waitbar(x / num_slices);
    end
    % close(waiting);
    % Now, figure out how large to make the montage
    width = 0;
    height = 0;
    for x = 1:num_slices
        bbox = collector{x}.bbox;
        if bbox(3) > width
            width = bbox(3);
        end
        if bbox(4) > height
            height = bbox(4);
        end
    end
    % Now, add 100 pixels to width and height
    width = width + 100;
    height = height + 100;
    % Next, let's collect to montage
    to_montage = zeros(height, width, 1, to_select);
    montage_count = 1;
    % And to produce a major axis histogram
    all_feret_diameters = [];
    for x = 1:num_slices
        % Find to see if this is something we want to store
        selected = find(idxs(idxs == x), 1);
        info = collector{x};
        if ~isempty(selected)
            % Let's get the data out and crop it
            data_cropped = imcrop(info.data, info.bbox);
            crop_size = size(data_cropped);
            % Next, let's figure out how much we need to pad
            width_to_pad = width - crop_size(2);
            height_to_pad = height - crop_size(1);
            % Let's do width, then height
            even_width_pad = (width_to_pad - mod(width_to_pad, 2)) / 2;
            % Now, pad the width
            data_cropped = padarray(data_cropped, [0, even_width_pad], 'both');
            % Add one if original to_pad was odd
            if mod(width_to_pad, 2)
                data_cropped = padarray(data_cropped, [0, 1], 'post');
            end
            % Do the same with height
            even_height_pad = (height_to_pad - mod(height_to_pad, 2)) / 2;
            data_cropped = padarray(data_cropped, [even_height_pad, 0], 'both');
            % Pad the height
            if mod(height_to_pad, 2)
                data_cropped = padarray(data_cropped, [1, 0], 'post');
            end
            % Complement the image and store in the montage
            to_montage(:,:,:, montage_count) = imcomplement(data_cropped);
            montage_count = montage_count + 1;
        end
        % Now, aggregate feret diameters
        all_feret_diameters = [all_feret_diameters; info.feret];
    end
    all_feret_diameters = nonzeros(all_feret_diameters .* scale_factor);
    avg_dia = mean(all_feret_diameters);
    median_dia = median(all_feret_diameters);
        %% Time to plot!
        figure
        img = montage(to_montage, 'Size', [8,8]);
        %% Here, write the montage
        imwrite(img.CData, fullfile(slices_directory, 'sectional_montage.png'));
        figure
        % Convert minor axis to real units
        % Generate edges from centers of histograms
        hist_edges = centers_to_edges(0:.5:max(all_feret_diameters(:)));
        h = histogram(all_feret_diameters, hist_edges, 'Normalization', 'probability');
        h.FaceColor = 'black';
        line([avg_dia, avg_dia], ylim);
        line([median_dia, median_dia], ylim, 'Color', 'red');
        print -painters -depsc plots/synth_hist.eps
end


% Put this function under helper functions that are accessible globally

function edges = centers_to_edges(centers)
    d = diff(centers)/2;
    edges = [centers(1) - d(1), centers(1:end-1) + d, centers(end) + d(end)];
    edges(2:end) = edges(2:end) + eps(edges(2:end));
end