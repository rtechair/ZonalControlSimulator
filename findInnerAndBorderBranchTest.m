classdef findInnerAndBorderBranchTest < matlab.unittest.TestCase
    methods (Test)
        function errorBusNotInBasecase(testCase)
            basecase = loadcase('case5');
            bus_id_wrong = [ 4 5 6]; % bus id = 6 does not exist
            testCase.verifyError(@()findInnerAndBorderBranch(bus_id_wrong, basecase),'mustBusBeFromBasecase:busNotFromBasecase')
        end
            
        
        function errorBusNotInteger(testCase)
            basecase = loadcase('case5');
            bus_id_wrong = [ 4.5 5 ]; % bus_id is integer
            testCase.verifyError(@()findInnerAndBorderBranch(bus_id_wrong, basecase),'MATLAB:validators:mustBeInteger')
        end 
        
        function noInnerBranch(testCase)
            basecase = loadcase('case5');
            bus_id = 3;
            [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(bus_id, basecase);
            expected_inner = find([0;0]==1); % 0x1 empty double column vector
            expected_border = [ 4 5]';
            testCase.verifyEqual(branch_inner_idx, expected_inner) % actual value: 0x1 empty double column vector
            testCase.verifyEqual(branch_border_idx, expected_border)
        end
        
        function noBorderBranch(testCase)
            basecase = loadcase('case9');
            bus_id = (1:size(basecase.bus,1))'; % all buses
            [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(bus_id, basecase);
            expected_inner = (1: size(basecase.branch,1))'; % all branches
            expected_border = find([0;0]==1); % 0x1 empty double column vector
            testCase.verifyEqual(branch_inner_idx, expected_inner) 
            testCase.verifyEqual(branch_border_idx, expected_border) % actual value: 0x1 empty double column vector
        end
        
        function case5Bus3_4(testCase)
            basecase = loadcase('case5');
            bus_id = [3 4];
            [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(bus_id, basecase);
            expected_inner = 5;
            expected_border = [ 2 4 6]';
            testCase.verifyEqual(branch_inner_idx, expected_inner)
            testCase.verifyEqual(branch_border_idx, expected_border)
        end
        
    end
    
end