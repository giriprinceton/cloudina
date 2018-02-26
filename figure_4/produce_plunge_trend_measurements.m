function measured = produce_plunge_trend_measurements(data)
    % Here, some data to assert our math
    test_struct = struct();
    % First, a simple north facing vector (remember that the pixel grid
    % goes x 1 -> n and y 1 -> m, so going from high y to low y is actually
    % going north; conversely, going from low y to high y is south. 
    % Going from low x to high x is east, going from high x to
    % low x is west.
    test_struct.north.vector = [0 -1 0];
    test_struct.north.plunge = 0;
    test_struct.north.trend = 0;
    % Now, east, west, and south vectors
    test_struct.east.vector = [1 0 0];
    test_struct.east.plunge = 0;
    test_struct.east.trend = 90;
    test_struct.west.vector = [-1 0 0 ];
    test_struct.west.plunge = 0;
    test_struct.west.trend = 270;
    test_struct.south.vector = [0 1 0];
    test_struct.south.plunge = 0;
    test_struct.south.trend = 180;
    % Notice that these have no plunges, so plunge should be 0 degrees
    % Now, some plunge vectors
    % Perfectly 90
    % Remember that going up in z is actually going down the volume
    test_struct.positive_90.vector = [0 0 -1];
    test_struct.positive_90.plunge = 90;
    test_struct.positive_90.trend = 0;
    test_struct.negative_90.vector = [0 0 1];
    test_struct.negative_90.plunge = 90;
    test_struct.negative_90.trend = 0;
    % A 45 degree vector going north
    test_struct.north_45.vector = [0 -1 -1];
    test_struct.north_45.plunge = 45;
    test_struct.north_45.trend = 0;
    % A 45 degree vector pointing east
    test_struct.east_45.vector = [1 0 -1];
    test_struct.east_45.plunge = 45;
    test_struct.east_45.trend = 90;
    % What about a 75 degree vector pointing east?
    test_struct_east_75.vector = [1 0 -1];
    
    % Now, something more complex
    % Here, these vectors point north up 15 and southwest down 15
    test_struct.northeastup_15.vector = [0 -1 .267949192431123];
    test_struct.northeastup_15.plunge = 15;
    test_struct.northeastup_15.trend = 0;
    test_struct.southwestdown_15.vector = [-1 1 .3789];
    test_struct.southwestdown_15.plunge = 15;
    test_struct.southwestdown_15.trend = 225;
    % Fieldnames
    to_test = fieldnames(test_struct);
    % Let's try these all out
    for x = 1:length(to_test)
        % This vector
        this_data = test_struct.(to_test{x});
        this_vector = this_data.vector;
        [trend_result, plunge_result] = calculate_plunge_trend(this_vector);
                        
        assert((this_data.trend == trend_result),...
            ['Failed at: ', to_test{x}, '. Trend is supposed to be: ' num2str(this_data.trend),...
            ' but instead is: ', num2str(trend_result)]);

        assert((this_data.plunge == round(plunge_result)),...
            ['Failed at: ', to_test{x}, '. Plunge is supposed to be: ' num2str(this_data.plunge),...
            ' but instead is: ', num2str(plunge_result)]);

    end
    disp('All tests completed successfully!');
end

