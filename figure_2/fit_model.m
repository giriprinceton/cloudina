function [r, s, n, fit] = fit_model(h, g, nugget, model)
    % For each nugget/model combo, produce a fit
    r = [];
    s = [];
    n = [];
    fit = struct;
    for x = 1:length(nugget)
        [r(x), s(x), n(x), fit.(['model_', num2str(x)])] = variogramfit(h, g, [], [], [],...
            'nugget', nugget(x), 'model', model{x}, 'plotit', false);
    end
end