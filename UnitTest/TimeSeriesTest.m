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
            %{      
            Consider there are 3 generators.
            Gen1 starts at time 10 sec
            Gen2 starts at time 20 sec
            Gen3 starts at time 30 sec
            The window of the simulation is 1 sec
            The duration is 100 sec
            The maximal generation for each generator is respectively:
            - 20 MW
            - 30 MW
            - 40 Mw
            %}
            testCase.chargingRateFilename = 'tauxDeChargeMTJLMA2juillet2018.txt';
            testCase.windowSimulation = 5;
            testCase.durationSimulation = 600;
            testCase.maxPowerGeneration = [20 30 40]';
            testCase.genStart = [1 200 500]';
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
    end
    
    %{
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