function directory_test(list_dirs)
%DIRECTORY_TEST Check to see if directories exist; if they do not, create
%them
    % Loop through list of directories

    for x = 1:length(list_dirs)
        if ~isdir(list_dirs{x})
            mkdir(list_dirs{x});
        end
    end
    
end

