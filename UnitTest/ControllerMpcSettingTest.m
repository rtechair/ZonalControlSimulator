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
classdef ControllerMpcSettingTest < matlab.unittest.TestCase
    properties (SetAccess = protected)
        jsonFilename1
    end
    
    methods(TestClassSetup)
        
        function setJsonFilename1(testCase)
            testCase.jsonFilename1 = 'controllerMpcTest1.json';
        end
        
        function setJsonTest1(testCase)
            jsonStruct.predictionHorizonInSeconds = 50;
            jsonStruct.numberOfScenarios = 1;
            jsonStruct.overloadCost = 10^7;
            jsonStruct.maxOverload = 0.05;
            
            fileId = fopen(testCase.jsonFilename1,'w');
            encodedJson = jsonencode(jsonStruct);
            fprintf(fileId, encodedJson);
        end
        
    end
    
    methods(TestClassTeardown)
        
        function removeJsonTest1(testCase)
            delete(testCase.jsonFilename1);
        end
    end
    
    methods (Test)
        
        function readJsonTest1(testCase)
            mpc = ControllerMpcSetting(testCase.jsonFilename1);
            
            predictionHorizonInSeconds = mpc.getPredictionHorizonInSeconds();
            numberOfScenarios = mpc.getNumberOfScenarios();
            overloadCost = mpc.getOverLoadCost();
            maxOverload = mpc.getMaxOverload();
            
            testCase.verifyEqual(predictionHorizonInSeconds, 50);
            testCase.verifyEqual(numberOfScenarios, 1);
            testCase.verifyEqual(overloadCost, 10^7);
            testCase.verifyEqual(maxOverload, 0.05);
        end
    end
    
end