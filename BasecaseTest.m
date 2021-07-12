classdef BasecaseTest < matlab.unittest.TestCase
   
    methods(Test)
        
        function case6468rte_modAddBusVG(testCase)
            basicCase = Basecase('case6468rte_mod');
            bus_VG = 10000;
            basicCase.addBus(bus_VG, 2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);
            expectedRowBus = [bus_VG, 2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381];
            testCase.verifyEqual(basicCase.Matpowercase.bus(end,:), expectedRowBus);
        end
        
        function case6468rte_modAddGenOn2076(testCase)
            basicCase = Basecase('case6468rte_mod');
            bus = 2076;
            maxGeneration = 66;
            minGeneration = 0;
            basicCase.addGenerator(bus, maxGeneration, minGeneration);
            expectedRowGen = [bus 0 0 300 -300 1.025 100 1 maxGeneration minGeneration zeros(1,11)];
            testCase.verifyEqual(basicCase.Matpowercase.gen(end,:), expectedRowGen);
        end
            
    end
    
end

%{ 
To run the test:
testCase = BasecaseTest;
results = testCase.run
%}