classdef TimeSeriesTest < matlab.unittest.TestCase
    
    
    properties
        %Setup object
        chargingRateFilename
        windowSimulation
        durationSimulation
        maxPowerGeneration
        genStart
        
        % object of test
        timeSeries
    end
    
    methods(TestMethodSetup)
        function parametrizeProperties(testCase)
            testCase.chargingRateFilename = 'tauxDeChargeMTJLMA2juillet2018.txt';
            testCase.windowSimulation = 5;
            testCase.durationSimulation = 600;
            testCase.maxPowerGeneration = [20 30 40]';
            testCase.genStart = [1 200 500]'; % i.e. [0.181818182000000 0.363636364000000 0.136363636000000]
        end
        
        function createState(testCase)
            testCase.timeSeries = TimeSeries(testCase.chargingRateFilename, testCase.windowSimulation, ...
                testCase.durationSimulation, testCase.maxPowerGeneration, testCase.genStart);
        end
    end
    
    methods(Test)
        function initialPowerGeneration(testCase)
            actValue = testCase.timeSeries.getInitialPowerAvailable();
            expValue = [0.181818182000000 0.363636364000000 0.136363636000000]' .* testCase.maxPowerGeneration;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function disturbanceAfter40Steps(testCase)
            for k =1:40
                testCase.timeSeries.goToNextStep();
            end
            actValue = testCase.timeSeries.getDisturbancePowerAvailable();
            % 705: 0.136363636000000
            % 700: 0.136363636000000
            % 405: 0.212090448000000
            % 400: 0.227272727000000
            % 206: 0.363636364000000
            % 201: 0.363636364000000
            followingState = [0.363636364000000 0.212090448000000 0.136363636000000]';
            previousState = [0.363636364000000 0.227272727000000 0.136363636000000]';
            expValue = (followingState - previousState) .* testCase.maxPowerGeneration;
            testCase.verifyEqual(actValue, expValue, "AbsTol",0.0001);
        end
    end
    
    %{
    % Parameterized test:
    % https://www.mathworks.com/help/matlab/matlab_prog/create-basic-parameterized-test.html
    properties
        chargingRateFilename
        %timeSeries
    end
    
    properties (TestParameter)
        windowSimulation = {1,5,15};
        durationSimulation = {100,600,1000};
        % 4 generators are considered for the test suite
        maxPowerGeneration = {[20 30 40 50]', [10 10 10 10]'}
        genStart = {[1 1 1 1]', [1 100 200 400]'}
    end
    
    methods (TestMethodSetup)
        function createTimeSeries(testCase)
            testCase.chargingRateFilename = 'tauxDeChargeMTJLMA2juillet2018.txt';
        end
    end
    
    methods (Test)
        function initialPowerGeneration(testCase, windowSimulation, durationSimulation, ...
                maxPowerGeneration, genStart)
            timeSeries = TimeSeries(testCase.chargingRateFilename,windowSimulation, durationSimulation,...
                maxPowerGeneration, genStart);
            chargingRate = table2array(readtable(testCase.chargingRateFilename))';
            actValue = timeSeries.getInitialPowerAvailable();
            expValue = chargingRate(genStart) .* maxPowerGeneration;
            testCase.verifyEqual(actValue, expValue, ...
                'incorrectValue of the initial power generation');
        end
    end
    %}
end