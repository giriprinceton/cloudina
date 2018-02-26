function process_samples(rects)
    % Load the sample struct
    loaded = load(rects);
    struct_name = fieldnames(loaded);
    sample_struct = loaded.(struct_name{1});
    % Samples
    samples = fieldnames(sample_struct);
    % Each sample
    for x = 1:length(samples)
        this_sample = sample_struct.(samples{x});
    end

    %{
    %% PLUNGE AND TREND
    %% Okay, we need to test this
    % North vector
    north_vector = [0 1 0];
    % Vertical vector
    vert_vector = [0 0 1];
    evaluation_break = 5;
    % Load the rectangle struct
    loaded = load(rects);
    struct_name = fieldnames(loaded);
    sample_struct = loaded.(struct_name{1});
    % Samples
    samples = fieldnames(sample_struct);
    % Each sample
    for x = 1:length(samples)
        this_sample = sample_struct.(samples{x});
        % Number evaluation points, skip the last one
        num_points = length(this_sample.evaluated_norms) - 1;
        % Evaluation points
        evaluate_points = 0:floor(num_points / evaluation_break):num_points;
        % Skip first and last
        evaluate_points = evaluate_points(2:end-1);
        % Points to look at
        % Get points
        points = this_sample.evaluated_points(:, evaluate_points);
        % Get evaluated normals
        norms = this_sample.evaluated_norms(:, evaluate_points);
        vectors = norms - points;
        trend_plunge = zeros(size(vectors, 2), 2);
        for y = 1:size(vectors, 2)
            v = vectors(:,y)';
            % Angle between north and this
            trend = atan2(norm(cross(north_vector,[v(1:2), 0])),dot(north_vector,[v(1:2), 0]));
            trend_deg = rad2deg(trend);
            % Angle between vertical and this
            plunge = atan2(norm(cross(vert_vector, v)), dot(vert_vector, v));
            plunge_deg = rad2deg(plunge);
            trend_plunge(y, :) = [trend_deg, plunge_deg];
        end
    end
    %}
end