function [trend_deg, plunge_deg] = calculate_plunge_trend(input_vector)
    % Define reference vector
    horizontal_reference_vector = [0 -1 0];
    vector_norm = norm(input_vector);
    % Get vector norm and unitize
    normalized_vector = input_vector ./ vector_norm;
    % Okay, first, let's break down the vector into its component parts
    xy_component = [normalized_vector(1:2), 0];
    % Also, for plunge calculations, we want to know the angle in reference
    % to a projected horizontal line
    % So all you care about is the norm!
    % Now, calculate the trend and plunge angle
    % Old code, only returns positive values, so useless for cardinal direction:
    % trend = atan2d(norm(cross(xy_component, horizontal_reference_vector)), dot(xy_component, horizontal_reference_vector));
    % Here's a special case, where something is purely vertical (x and y
    % of the vector are both 0)
    if xy_component(1) ==0 && xy_component(2) == 0
        trend_deg = 0;
    else
        % Let's do something a bit ghetto
        % You add 180 to adjust for rotated coordinate system
        trend_deg = round(mod(abs(atan2d(xy_component(1), xy_component(2)) - 180), 360));
    end
    % Angle between vertical and this
    % Old code:
    % plunge = atan2(norm(cross(yz_component, horizontal_reference_vector)), dot(yz_component, horizontal_reference_vector));
    % Here, we just need positive and negative
    % plunge_deg = mod(atan2d(norm(cross(yz_component, horizontal_reference_vector)), dot(yz_component, horizontal_reference_vector)), 180);
    % plunge_deg = rad2deg(plunge);
    % Calculate length
    projected_length = sqrt(normalized_vector(1)^2 + normalized_vector(2)^2);
    plunge_deg = round(abs(atan2d(normalized_vector(3), projected_length)));
end