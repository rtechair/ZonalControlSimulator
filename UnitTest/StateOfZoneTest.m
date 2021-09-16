classdef StateOfZoneTest < matlab.unittest.TestCase
    

    
    properties
        numberOfBranches
        numberOfGenerators
        numberOfBatteries
        state
    end
    
    methods(TestMethodSetup)
        function parametrizeProperties(testCase)
            %{
            imagine a zone with such a topology:
            - 5 nodes
            - 4 branches
            - 3 generators
            - 2 battery

            Gen1 ------- Batt1 ------- node ------ Gen2+Batt2
                           |
                         Gen3
            %}
            testCase.numberOfBranches = 4;
            testCase.numberOfGenerators = 3;
            testCase.numberOfBatteries = 2;
        end
        
        function createState(testCase)
            nbOfBranches = testCase.numberOfBranches;
            nbOfGen = testCase.numberOfGenerators;
            nbOfBatt = testCase.numberOfBatteries;
            testCase.state = StateOfZone(nbOfBranches, nbOfGen, nbOfBatt);
        end
    end
    
   methods(Test)
       function initialPowerGeneration(testCase)
           initialPowerAvailable = [1 2 3]';
           testCase.state.setPowerAvailable(initialPowerAvailable);
           maxPowerGeneration = [2 2 2]';
           
           testCase.state.setInitialPowerGeneration(maxPowerGeneration);
           actValue = testCase.state.getPowerGeneration();
           expValue = [1 2 2]';
           testCase.verifyEqual(actValue, expValue);
       end
       
       function updatePowerBattery(testCase)
           initialPowerBattery = [3 2]';
           testCase.state.setPowerBattery(initialPowerBattery);
           controlBattery = [-1 1]';
           
           testCase.state.updatePowerBattery(controlBattery);
           actValue = testCase.state.getPowerBattery();
           expValue = initialPowerBattery + controlBattery;
           testCase.verifyEqual(actValue, expValue);
       end
       
       function updatePowerCurtailment(testCase)
           initialPowerCurtailment = [2 2 2]';
           testCase.state.setPowerCurtailment(initialPowerCurtailment);
           controlCurtailment = [-1 1 0]';
           
           testCase.state.updatePowerCurtailment(controlCurtailment);
           actValue = testCase.state.getPowerCurtailment();
           expValue = initialPowerCurtailment + controlCurtailment;
           testCase.verifyEqual(actValue, expValue);
       end
       
       function updatePowerGeneration(testCase)
          initialPowerGeneration = [2 2 2]';
          testCase.state.setPowerGeneration(initialPowerGeneration);
          disturbancePowerGeneration = [2 2 0]';
          controlCurtailment = [-1 1 2]';
          
          testCase.state.updatePowerGeneration(disturbancePowerGeneration, controlCurtailment);
          actValue = testCase.state.getPowerGeneration();
          expValue = initialPowerGeneration + disturbancePowerGeneration - controlCurtailment;
          testCase.verifyEqual(actValue, expValue);
       end
       
   end    
    
end