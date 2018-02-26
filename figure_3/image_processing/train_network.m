function net = train_network(configuration_file)
    % Load the configuration 
    load(configuration_file);
    % Now, look for training data
    training_data_path = fullfile(config.storage, 'training_data');
    input_path = fullfile(training_data_path, 'input_matrix.mat');
    output_path = fullfile(training_data_path, 'output_matrix.mat');
    % If BOTH input and output paths exists
    if exist(input_path, 'file') == 2 && exist(output_path, 'file') == 2
        % Load put input and output matricies
        inputs = load_single(input_path);
        desired_outputs = load_single(output_path);
        % Fantastic, now let's train the network
        % Number of hidden nodes (set at 10 as default)
        hidden_nodes = 10;
        % Define the net
        net = patternnet(hidden_nodes);
        % Set training divisions
        net.divideParam.trainRatio = 70/100;
        net.divideParam.valRatio = 15/100;
        net.divideParam.testRatio = 15/100;
        % Train it! 
        [net,tr] = train(net,inputs,desired_outputs);
        % Test the Network
        test_outputs = net(inputs);
        errors = gsubtract(desired_outputs,test_outputs);
        performance = perform(net,desired_outputs,test_outputs);
        disp(performance);
        % Save it! 
        % First, check to make sure the output folder exists
        trained_network_path = fullfile(config.storage, 'trained_network');
        directory_test({trained_network_path});
        save(fullfile(trained_network_path, 'trained_net'), 'net');
        disp('fully trained!');
    end
end