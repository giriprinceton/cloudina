function out = load_data(data, as_img, apply_gauss, gauss_filt, include_lab)
    % load_data does as its name implies - loads either image or label data and returns it as a structure 
    out = struct();
    out.ordered = {};
    for x = 1:length(data)
        [~, file_name, ~] = fileparts(data{x});
        % If we should treat this as an image
        if as_img
            % Load it
            loaded_data = imread(data{x});
            if apply_gauss
                loaded_data = imgaussfilt(loaded_data, gauss_filt);
            end
        else
            loaded_data = load(data{x});
            loaded_fields = fieldnames(loaded_data);
            loaded_data = loaded_data.(loaded_fields{1});
            % Save idx listings
            out.all_idx.(file_name) = label2idx(loaded_data);
        end
        out.(file_name) = loaded_data;
        out.ordered = [out.ordered; file_name];
        % If both as img and include lab, convert to lab
        if as_img && include_lab
            out.([file_name, '_lab']) = rgb2lab(loaded_data);
        end
    end
end

%{
function out = load_data(data, as_img, gauss_filt)
    out = struct();
    out.ordered = {};
    for x = 1:length(data)
        [~, file_name, ~] = fileparts(data{x});
        % If we should treat this as an image
        if as_img
            % Load it
            loaded_data = imread(data{x});
            % Now, blur it
            loaded_data = imgaussfilt(loaded_data, gauss_filt);
        else
            loaded_data = load(data{x});
            loaded_fields = fieldnames(loaded_data);
            loaded_data = loaded_data.(loaded_fields{1});
            % Save idx listings
            out.all_idx.(file_name) = label2idx(loaded_data);
        end
        out.(file_name) = loaded_data;
        out.ordered = [out.ordered; file_name];
    end
end
%}