function add_field(configuration, fieldname, type)
    load(configuration);
    if strcmp(type, 'structure')
        config.(fieldname) = struct();
    elseif strcmp(type, 'matrix')
        config.(fieldname) = [];
    elseif strcmp(type, 'cell');
        config.(fieldname) = {};
    end
    save(configuration, 'config');
end