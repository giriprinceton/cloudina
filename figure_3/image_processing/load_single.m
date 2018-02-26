function output = load_single(path)
    % First, load the file
    loaded = load(path);
    % Next, get fieldnames
    fields = fieldnames(loaded);
    % Set output to the first field name
    output = loaded.(fields{1});
end