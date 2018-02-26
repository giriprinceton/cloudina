function points = circular_arc_endpoints(p1, p2, r)
    % If radius is less than 1/2 distance between p1 and p2, we'll end up
    % with imaginary numbers, so warn
    if pdist([p1; p2])/2 > r
        error('Radius must be greater than 1/2 the distance between point 1 and point 2');
    end
    centers = calculate_center(p1, p2, r);
    % Take the center with the lower x
    centers = sortrows(centers, 1, 'ascend');
    cp = centers(1,:);
    s = 2 * atan( (p1(2) - cp(2)) / (p1(1) - cp(1) + r) );
    t = 2 * atan( (p2(2) - cp(2)) / (p2(1) - cp(1) + r) );
    if s < t
        thetas = s:1e-3:t;
    else
        thetas = t:1e-3:s;
    end
    points = cp + (r .* [cos(thetas)', sin(thetas)']);
end

function centers = calculate_center(p1, p2, r)
    subtracted = p1 - p2;
    mapping = [-subtracted(2), subtracted(1)];
    over_two = (p1 + p2) / 2;
    pt_dist = pdist([p1; p2]);
    sqrt_term = (mapping * sqrt((r^2/pt_dist^2) - .25));
    centers = [over_two + sqrt_term; over_two - sqrt_term];
end

