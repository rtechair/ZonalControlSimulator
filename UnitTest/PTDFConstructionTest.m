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
classdef PTDFConstructionTest < matlab.unittest.TestCase
    
    properties
        % Setup objects
        bus
        frontierBusInZone
        branchIdx
        genIdx
        battIdx

        grid

        % the object of the test
        PTDFObject
    end
    
    methods(TestMethodSetup)
        function setProperties(testCase)
            testCase.bus = [1445;2076;2135;2745;4720;10000];
            borderFromBus = [2504;4231;5313;2504;2504;5411;4720;1445;1445];
            borderToBus = [1445;1445;1445;1445;1445;2135;2694;1446;1446];
            testCase.frontierBusInZone = intersect(testCase.bus, union(borderFromBus, borderToBus), 'sorted');
            testCase.branchIdx = [2854;2856;2859;3881;3882;9000;9001];
            testCase.genIdx = [1297;1298;1299;1300];
            testCase.battIdx = 1301;

            basecaseFilename = "case6468rte_zone_VG_VTV_BLA.m";

            testCase.grid = ElectricalGrid(basecaseFilename);
            testCase.grid.setNetworkPTDF();
        end

        function createPTDFObject(testCase)
            testCase.PTDFObject = PTDFConstruction(testCase.bus, testCase.frontierBusInZone, ...
                                                   testCase.branchIdx, testCase.genIdx, testCase.battIdx);
            testCase.PTDFObject.setPTDF(testCase.grid);
        end
    end
    
    methods(Test)
        function checkPTDFBus(testCase)
            expectedPTDF = readmatrix("EstimatorPTDF/branchPerBusPTDF.txt");
            actualPTDF = testCase.PTDFObject.getPTDFBus();
            testCase.verifyEqual(actualPTDF, expectedPTDF, "AbsTol", 0.01);
        end

        function checkPTDFFrontierBus(testCase)
            actualPTDFFrontierBus = testCase.PTDFObject.getPTDFFrontierBus();
            actualPTDFBus = testCase.PTDFObject.getPTDFBus();
            testCase.verifyEqual(actualPTDFBus(:, [1 3 5]), actualPTDFFrontierBus, "AbsTol", 0.01);
        end

        function checkPTDFGen(testCase)
            expectedPTDF = readmatrix("EstimatorPTDF/branchPerBusOfGenPTDF.txt");
            actualPTDF = testCase.PTDFObject.getPTDFGen();
            testCase.verifyEqual(actualPTDF, expectedPTDF,  "AbsTol", 0.01);
        end

        function checkPTDFBatt(testCase)
            expectedPTDF = readmatrix("EstimatorPTDF/branchPerBusOfBattPTDF.txt");
            actualPTDF = testCase.PTDFObject.getPTDFBatt();
            testCase.verifyEqual(actualPTDF, expectedPTDF,  "AbsTol", 0.01);
        end
    end
end