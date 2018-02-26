function data = append_rect_data(data, rect_location)
    % Load the sample struct
    loaded = load(rect_location);
    struct_name = fieldnames(loaded);
    rect_struct = loaded.(struct_name{1});
    % Rectangles
    rects = fieldnames(rect_struct);
    % Number of rectangles
    num_rects = length(rects);
    % Now, for each rectangle, we want to see if a field exists in the data
    % structure
    for x = 1 : num_rects
        % Does this field exist?
        if isfield(data, rects{x})
            % If it does, add the rect data to the structure
            data.(rects{x}).rect_data = rect_struct.(rects{x});
        end
    end
    % Done!
    return
end