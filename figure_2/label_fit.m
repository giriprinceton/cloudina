function spec = label_fit(name, fitting)
    % Get fitting fieldnames
    fnames = fieldnames(fitting);
    % Grid on
    grid on
    % Plot the experimental values
    hold on
    plot(fitting.(fnames{1}).h, fitting.(fnames{1}).gamma, 'o');
    col = parula(length(fnames) + 1);
    legend_entries = {'Experimental data'};
    spec = {};
    for x = 1:length(fnames)
        % Taken from variogramfit
        this_fit = fitting.(fnames{x});
        % b(1) range
        % b(2) sill
        % b(3) nugget
        b = [this_fit.range, this_fit.sill, this_fit.nugget];
        h = this_fit.h;
        funnugget = @(b) b(3);
        func = this_fit.func;
        % Plot the model
        this_color = col(x,:);
        switch this_fit.type
            case 'bounded'
                fplot(@(h) funnugget(b) + func(b,h),[0 b(1)], 'Color', this_color);
                fplot(@(h) funnugget(b) + b(2),[b(1) max(h)], 'Color', this_color);
            case 'unbounded'
                fplot(@(h) funnugget(b) + func(b,h),[0 max(h)], 'Color', this_color);
        end
        legend_entries{x+1} = [upper(this_fit.model(1)), this_fit.model(2:end), ' r^2 = ', num2str(round(this_fit.Rs, 3))];
        % Finally, write the spec
        switch this_fit.model
            case 'exponential'
                abv = 'Exp';
            case 'spherical'
                abv = 'Sph';
        end
        spec{x} = [num2str(b(3)), ' Nug(0) + ', num2str(b(2)), ' ', abv, '(', num2str(b(1)), ')'];
    end
    % Set xlim
    xlim([0, max(this_fit.h) + 10]);
    existing_y_lim = ylim;
    % And ylim
    ylim([0, existing_y_lim(2)]);
    % Set title
    title(name);
    % Set x and y axes
    xlabel('Lag distance');
    ylabel('Semivariance');
    % Set legend
    legend(legend_entries, 'Location', 'southeast');
end