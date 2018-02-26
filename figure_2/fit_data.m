function fit_data(directory, location_points)
    close all
    % First, load the shapefile
    info = shapeinfo(fullfile(directory, location_points));
    [data, attributes] = shaperead(fullfile(directory, location_points));
    % Data X and Data Y
    data_x = [data.X];
    data_y = [data.Y];
    % Empty points matrix
    points = zeros(info.NumFeatures, 1);
    fit_fig = figure;
    % I. Begin by looking for any points with ONLY cover ... any place with
    % some rock is not covered
    % Determining where outcrop is should be done by looking for
    % 0s in all attributes except for Comment, Feat_Name, GNSS_Heigh,
    % Latitude, Longitude, trimple_po, trimble__1, trimble __2, garmin_poi,
    % descritptio, C, POINT_X, and POINT_Y - so, in this case, 1:10, 13 and
    % end-1:end are the indicies
    % This is janky, I know.
    attribute_cells = struct2cell(attributes);
    selected_attributes = cell2mat(attribute_cells([11:12, 14:end-2], :)');
    % These are the points that have some sort of outcrop (even if they
    % include cover, see above)
    some_outcrop_pts = find(max(selected_attributes, [], 2));
    % Here are the hardcoded parts, sorry :(
    % Fit an experimental
    [o_g, o_h, o_p] = fit_semi(points, data_x, data_y, some_outcrop_pts);
    % Try an exponential
    [o_r, o_s, o_n, o_fit] = fit_model(o_h, o_g, [.25; .25],...
        {'exponential'; 'spherical'});
    figure(fit_fig);
    subplot(2, 2, 1);
    o_spec = label_fit('Presence of Outcrop', o_fit);
    % 
    % II. Now, all points with any sort of microbial features
    % These include: Tm (Throm Mounding), Strom Encrustions (Se), Columnar
    % Throms (Tc), Columnar (Co), Stroms (So), and Throm (T)
    % We're leaving out Microbial Texture (in all of its forms) and Mounds
    microbial_pts = find(...
        ([attributes.Tm] | [attributes.Se]  | [attributes.Tc] | ...
        [attributes.Co] | [attributes.So] | [attributes.T]));
    % Fit an experimental
    [m_g, m_h, m_p] = fit_semi(points, data_x, data_y, microbial_pts);
    % Try an exponential
    [m_r, m_s, m_n, m_fit] = fit_model(m_h, m_g, [.15; .1],...
        {'exponential'; 'spherical'});
    figure(fit_fig);
    subplot(2, 2, 2);
    m_spec = label_fit('Presence of Microbial Textures', m_fit);
    % III. All skeletal presence
    % These include: Cloudina Thicket (Ct), Sinuous Texture (St), Cloudina
    % in Fill (Cf), Cloudina (Cl), Nama (Na), Skeletal (Sk), Potential
    % Thicket (Pt), Potential Framework (Pfw), Skeletal Fill (Skf),
    % Skeletal FIll, Partially Dolomitized (Skfpdl), Skeletal Fill,
    % Dolomitized (Skfd), Framework (Fw), Packestone/Wackestone (PKWK)
    skeletal_pts = find([attributes.Ct] | [attributes.St] ...
        | [attributes.Cf] | [attributes.Cl] | [attributes.Na] ...
        | [attributes.Sk] | [attributes.Pt] | [attributes.Pfw] ...
        | [attributes.Skf] | [attributes.Skfpdl] | [attributes.Skfd] ...
        | [attributes.Fw] | [attributes.PKWK]);
        % Fit an experimental
    [s_g, s_h, s_p] = fit_semi(points, data_x, data_y, skeletal_pts);
    % Try an exponential
    [s_r, s_s, s_n, s_fit] = fit_model(s_h, s_g, [.1; .1],...
        {'exponential'; 'spherical'});
    figure(fit_fig);
    subplot(2, 2, 3);
    s_spec = label_fit('Presence of Skeletal Textures', s_fit);
    % IV. Framework only
    % This includes: Cloudina Thicket (Ct), Potential Thicket (Pt), Framework (Fw), and
    % Potential Framework (Pfw)
    framework_pts = find([attributes.Ct] | ...
        [attributes.Pt] | [attributes.Fw] | [attributes.Pfw]);
    [f_g, f_h, f_p] = fit_semi(points, data_x, data_y, framework_pts);
    % Try an exponential
    [f_r, f_s, f_n, f_fit] = fit_model(f_h, f_g, [.025; .025],...
        {'exponential'; 'spherical'});
    figure(fit_fig);
    subplot(2, 2, 4);
    f_spec = label_fit('Presence of Cloudina Thicket', f_fit);
    % Output
    % Totally hand done
    vario_specs = {o_spec{1}, m_spec{1}, s_spec{2}, f_spec{2}};
    out_points = [o_p, m_p, s_p, f_p];
    classes = {'Outcrop', 'Microbial', 'Skeletal', 'Framework'};
    save('vario_specs', 'vario_specs');
    save('out_points', 'out_points');
    save('classes', 'classes');
end

function [gamma, h, out_points] = fit_semi(out_points, data_x, data_y, present)
    out_points(present) = 1;
    [gamma, h] = semivar_exp([data_x', data_y'], out_points);
end

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