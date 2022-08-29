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
classdef ZonePTDFConstructorTest < matlab.unittest.TestCase

    methods(Test)
        function testCase6ww_networkPTDF(testCase)
            basecaseName = 'case6ww';
            case6wwPTDF = [0   -0.4706   -0.4026   -0.3149   -0.3217   -0.4064;
                                         0   -0.3149   -0.2949   -0.5044   -0.2711   -0.2960;
                                         0   -0.2145   -0.3026   -0.1807   -0.4072   -0.2976;
                                         0    0.0544   -0.3416    0.0160   -0.1057   -0.1907;
                                         0    0.3115    0.2154   -0.3790    0.1013    0.2208;
                                         0    0.0993   -0.0342    0.0292   -0.1927   -0.0266;
                                         0    0.0642   -0.2422    0.0189   -0.1246   -0.4100;
                                         0    0.0622    0.2890    0.0183   -0.1207    0.1526;
                                         0   -0.0077    0.3695   -0.0023    0.0150   -0.3433;
                                         0   -0.0034   -0.0795    0.1166   -0.1698   -0.0752;
                                         0   -0.0565   -0.1273   -0.0166    0.1096   -0.2467];
            ptdfConstructor = ZonePTDFConstructor(basecaseName);
            actualNetworkPTDF = ptdfConstructor.getNetworkPTDF();

            testCase.verifyEqual(actualNetworkPTDF, case6wwPTDF, "RelTol", 0.1);
        end

        function testCase6ww_zonePTDF(testCase)
            basecaseName = 'case6ww';
            case6wwPTDF = [0   -0.4706   -0.4026   -0.3149   -0.3217   -0.4064;
                                         0   -0.3149   -0.2949   -0.5044   -0.2711   -0.2960;
                                         0   -0.2145   -0.3026   -0.1807   -0.4072   -0.2976;
                                         0    0.0544   -0.3416    0.0160   -0.1057   -0.1907;
                                         0    0.3115    0.2154   -0.3790    0.1013    0.2208;
                                         0    0.0993   -0.0342    0.0292   -0.1927   -0.0266;
                                         0    0.0642   -0.2422    0.0189   -0.1246   -0.4100;
                                         0    0.0622    0.2890    0.0183   -0.1207    0.1526;
                                         0   -0.0077    0.3695   -0.0023    0.0150   -0.3433;
                                         0   -0.0034   -0.0795    0.1166   -0.1698   -0.0752;
                                         0   -0.0565   -0.1273   -0.0166    0.1096   -0.2467];
            zoneBuses = [1 2 4 5]';
            %{
                ================================================================================
                |     Branch Data                                                              |
                ================================================================================
                Brnch   From   To    From Bus Injection   To Bus Injection     Loss (I^2 * Z)  
                  #     Bus    Bus    P (MW)   Q (MVAr)   P (MW)   Q (MVAr)   P (MW)   Q (MVAr)
                -----  -----  -----  --------  --------  --------  --------  --------  --------
                   1      1      2     28.69    -15.42    -27.78     12.82     0.905      1.81
                   2      1      4     43.58     20.12    -42.50    -19.93     1.088      4.35
                   3      1      5     35.60     11.25    -34.53    -13.45     1.074      4.03
                   4      2      3      2.93    -12.27     -2.89      5.73     0.040      0.20
                   5      2      4     33.09     46.05    -31.59    -45.13     1.505      3.01
                   6      2      5     15.51     15.35    -15.02    -18.01     0.498      1.49
                   7      2      6     26.25     12.40    -25.67    -16.01     0.583      1.67
                   8      3      5     19.12     23.17    -18.02    -26.10     1.094      2.37
                   9      3      6     43.77     60.72    -42.77    -57.86     1.003      5.02
                  10      4      5      4.08     -4.94     -4.05     -2.79     0.036      0.07
                  11      5      6      1.61     -9.66     -1.56      3.87     0.050      0.15
            %}
            zoneBranches = [1 2 3 5 6 10]';
            expBranchPerBusPTDF = case6wwPTDF(zoneBranches, zoneBuses);
            ptdfConstructor = ZonePTDFConstructor(basecaseName);
            [actBranchPerBusPTDF, ~, ~] = ...
                ptdfConstructor.getZonePTDF(zoneBuses);

            testCase.verifyEqual(actBranchPerBusPTDF, expBranchPerBusPTDF, "RelTol", 0.1);
        end

        function testCase6ww_branchPerBusOfgenPTDF(testCase)
            basecaseName = 'case6ww';
            case6wwPTDF = [0   -0.4706   -0.4026   -0.3149   -0.3217   -0.4064;
                                         0   -0.3149   -0.2949   -0.5044   -0.2711   -0.2960;
                                         0   -0.2145   -0.3026   -0.1807   -0.4072   -0.2976;
                                         0    0.0544   -0.3416    0.0160   -0.1057   -0.1907;
                                         0    0.3115    0.2154   -0.3790    0.1013    0.2208;
                                         0    0.0993   -0.0342    0.0292   -0.1927   -0.0266;
                                         0    0.0642   -0.2422    0.0189   -0.1246   -0.4100;
                                         0    0.0622    0.2890    0.0183   -0.1207    0.1526;
                                         0   -0.0077    0.3695   -0.0023    0.0150   -0.3433;
                                         0   -0.0034   -0.0795    0.1166   -0.1698   -0.0752;
                                         0   -0.0565   -0.1273   -0.0166    0.1096   -0.2467];
            zoneBuses = [1 2 4 5]';
            zoneBranches = [1 2 3 5 6 10]';
            busOfGenInZone = [1 2]';
            branchPerBusOfGenInZonePTDF = case6wwPTDF(zoneBranches, busOfGenInZone);
            ptdfConstructor = ZonePTDFConstructor(basecaseName);
            [~, actBranchPerBusOfGenPTDF, ~] = ...
                ptdfConstructor.getZonePTDF(zoneBuses);
            testCase.verifyEqual(actBranchPerBusOfGenPTDF, branchPerBusOfGenInZonePTDF, "RelTol", 0.1);
        end

        function testCase300(testCase)
            basecaseName = 'case300';
            busId = [9001;9005;9006;9012;9051;9052;9053];
            branchIdx = [2 3 4 5 6 7]';
            genOnIdx = [66 67]';
            busOfGenOn = [9051 9053]';

             
            
            grid = ElectricalGrid(basecaseName);
            internalCase = grid.getInternalMatpowercase();
            networkPTDF = makePTDF(internalCase);


            mapBus_id_e2i = grid.getMapBus_id_e2i();
            internalBusId = mapBus_id_e2i(busId);
            internalBusIdOfGenOn = mapBus_id_e2i(busOfGenOn);
            
            expBranchPerBusPTDF = networkPTDF(branchIdx, internalBusId);
            expBranchPerBusOfGenPTDF = networkPTDF(branchIdx, internalBusIdOfGenOn);

            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);
            [actBranchPerBusPTDF, actBranchPerBusOfGenPTDF, ~] = zonePTDFConstructor.getZonePTDF(busId);

            testCase.verifyEqual(actBranchPerBusPTDF, expBranchPerBusPTDF, "RelTol", 0,1);
            testCase.verifyEqual(actBranchPerBusOfGenPTDF, expBranchPerBusOfGenPTDF, "RelTol", 0.1);
        end

        function test_VGsmall(testCase)
            basecaseName = 'case6468rte_zone_VG_VTV_BLA';
            busId = [1445, 2076, 2135, 2745, 4720, 10000]';
            branchIdx = [2854;2856;2859;3881;3882;9000;9001];
            genOnIdx = [1297;1298;1299;1300];
            battOnIdx = 1301;

            busOfGenOn = [2076;2745;4720;10000];
            busOfBattOn = 10000;

            grid = ElectricalGrid(basecaseName);
            internalCase = grid.getInternalMatpowercase();
            networkPTDF = makePTDF(internalCase);

            mapBus_id_e2i = grid.getMapBus_id_e2i();
            internalBusId = mapBus_id_e2i(busId);
            internalBusIdOfGenOn = mapBus_id_e2i(busOfGenOn);
            internalBusIdOfBattOn = mapBus_id_e2i(busOfBattOn);

            expBranchPerBusPTDF = networkPTDF(branchIdx, internalBusId);
            expBranchPerBusOfGenPTDF = networkPTDF(branchIdx, internalBusIdOfGenOn);
            expBranchPerBusOfBattPTDF = networkPTDF(branchIdx, internalBusIdOfBattOn);
            
            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);
            [actBranchPerBusPTDF, actBranchPerBusOfGenPTDF, actBranchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            testCase.verifyEqual(actBranchPerBusPTDF, expBranchPerBusPTDF, "RelTol", 0,1);
            testCase.verifyEqual(actBranchPerBusOfGenPTDF, expBranchPerBusOfGenPTDF, "RelTol", 0.1);
            testCase.verifyEqual(actBranchPerBusOfBattPTDF, expBranchPerBusOfBattPTDF, "RelTol", 0.1);
        end

    end
end