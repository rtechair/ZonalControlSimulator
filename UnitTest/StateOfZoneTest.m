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
            - 1 battery

            Gen1 ------- Batt ------- node ------ Gen2
                           |
                         Gen3
            %}
            testCase.numberOfBranches = 4;
            testCase.numberOfGenerators = 3;
            testCase.numberOfBatteries = 1;
        end
        
        function createState(testCase)
            nbOfBranches = testCase.numberOfBranches;
            nbOfGen = testCase.numberOfGenerators;
            nbOfBatt = testCase.numberOfBatteries;
            testCase.state = StateOfZone(nbOfBranches, nbOfGen, nbOfBatt);
        end
    end
    
   methods(Test)
       function initialPowerGenerationIsPowerAvailable(testCase)
           initialPowerAvailable = 1;
           testCase.state.setPowerAvailable(initialPowerAvailable);
           maxPowerGeneration = 2;
           testCase.state.setInitialPowerGeneration(maxPowerGeneration);
           
           actValue = testCase.state.getPowerGeneration();
           expValue = initialPowerAvailable;
           testCase.verifyEqual(actValue, expValue);
       end
       
       function initialPowerGenerationIsMaxPowerGeneration(testCase)
           initialPowerAvailable = 2;
           testCase.state.setPowerAvailable(initialPowerAvailable);
           maxPowerGeneration = 1;
           testCase.state.setInitialPowerGeneration(maxPowerGeneration);
           
           actValue = testCase.state.getPowerGeneration();
           expValue = maxPowerGeneration;
           testCase.verifyEqual(actValue, expValue);
       end
       
   end    
    
end