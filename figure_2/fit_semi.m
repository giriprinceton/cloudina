function [gamma, h, out_points] = fit_semi(out_points, data_x, data_y, present)
    out_points(present) = 1;
    [gamma, h] = semivar_exp([data_x', data_y'], out_points);
end
