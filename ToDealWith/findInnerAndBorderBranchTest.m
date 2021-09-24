%{
SPDX-License-Identifier: Apache-2.0

Copyright 2021 CentraleSupélec and Réseau de Transport d'Électricité (RTE)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
%}

classdef findInnerAndBorderBranchTest < matlab.unittest.TestCase
    methods (Test)
        %% Error
        function errorNoBus(testCase)
            basecase = loadcase('case5');
            bus_id = [];
            testCase.verifyError(@() findInnerAndBorderBranch(basecase, bus_id), 'MATLAB:validators:mustBeNonempty')
        end
        
        function errorBusNotInBasecase(testCase)
            basecase = loadcase('case5');
            bus_id_wrong = [ 4 5 6]; % bus id = 6 does not exist
            testCase.verifyError(@()findInnerAndBorderBranch(basecase, bus_id_wrong),'mustBusBeFromBasecase:busNotFromBasecase')
        end
            
        
        function errorBusNotInteger(testCase)
            basecase = loadcase('case5');
            bus_id_wrong = [ 4.5 5 ]; % bus_id is integer
            testCase.verifyError(@()findInnerAndBorderBranch(basecase, bus_id_wrong),'MATLAB:validators:mustBeInteger')
        end 
        
        function errorBusNotVector(testCase)
            basecase = loadcase('case5');
            bus_id_wrong = [1 2; 3 4]; % 2x2 matrix
            testCase.verifyError(@() findInnerAndBorderBranch(basecase, bus_id_wrong), 'MATLAB:validation:IncompatibleSize')
        end
        
        %% Special case
        function noInnerBranch(testCase)
            basecase = loadcase('case5');
            bus_id = 3;
            [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(basecase, bus_id);
            expected_inner = find([0;0]==1); % 0x1 empty double column vector
            expected_border = [ 4 5]';
            testCase.verifyEqual(branch_inner_idx, expected_inner) % actual value: 0x1 empty double column vector
            testCase.verifyEqual(branch_border_idx, expected_border)
        end
        
        function noBorderBranch(testCase)
            basecase = loadcase('case9');
            bus_id = (1:size(basecase.bus,1))'; % all buses
            [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(basecase, bus_id);
            expected_inner = (1: size(basecase.branch,1))'; % all branches
            expected_border = find([0;0]==1); % 0x1 empty double column vector
            testCase.verifyEqual(branch_inner_idx, expected_inner) 
            testCase.verifyEqual(branch_border_idx, expected_border) % actual value: 0x1 empty double column vector
        end
        
        function case5Bus3_4(testCase)
            basecase = loadcase('case5');
            bus_id = [3 4];
            [branch_inner_idx, branch_border_idx] = findInnerAndBorderBranch(basecase, bus_id);
            expected_inner = 5;
            expected_border = [ 2 4 6]';
            testCase.verifyEqual(branch_inner_idx, expected_inner)
            testCase.verifyEqual(branch_border_idx, expected_border)
        end
        
    end
    
end