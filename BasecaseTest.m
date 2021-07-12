classdef BasecaseTest < matlab.unittest.TestCase
   
    methods(Test)
        
        function case6468rte_modAddBus(testCase)
            basicCase = Basecase('case6468rte_mod');
            basicCase.addBus(10000, 2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381);
            expectedRowBus = [10000, 2,   0 ,      0,       0 ,  0,   1,  1.03864259,	-11.9454015,	63,	1,	1.07937,	0.952381];
            testCase.verifyEqual(basicCase.Matpowercase.bus(end,:), expectedRowBus);
        end
            
    end
    
end

%{ 
To run the test:
testCase = BasecaseTest;
results = testCase.run
%}