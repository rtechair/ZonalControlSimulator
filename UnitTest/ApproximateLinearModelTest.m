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
classdef ApproximateLinearModelTest < matlab.unittest.TestCase

    properties
        model
    end
    
    methods(TestMethodSetup)
        function setProperties(testCase)
            basecaseName = 'case6468rte_zone_VG_VTV_BLA';
            busId = [1445, 2076, 2135, 2745, 4720, 10000]';

            numberOfBuses = 6;
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            
            batteryCoef = 0.001;
            timestep = 5;
            
            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);
            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);

            testCase.model = ApproximateLinearModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep);
        end    
    end

    methods(Test)
        function testOperatorStateA(testCase)
            A = [1	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                    0	1	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                    0	0	1	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                    0	0	0	1	0	0	0	0	0	0	0	0	0	0	0	0	0;
                    0	0	0	0	1	0	0	0	0	0	0	0	0	0	0	0	0;
                    0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0	0;
                    0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0;
                    0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0;
                    0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0;
                    0	0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0;
                    0	0	0	0	0	0	0	0	0	0	1	0	0	0	0	0	0;
                    0	0	0	0	0	0	0	0	0	0	0	1	0	0	0	0	0;
                    0	0	0	0	0	0	0	0	0	0	0	-0.00500000000000000	1	0	0	0	0;
                    0	0	0	0	0	0	0	0	0	0	0	0	0	1	0	0	0;
                    0	0	0	0	0	0	0	0	0	0	0	0	0	0	1	0	0;
                    0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1	0;
                    0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1];
            actualA = testCase.model.getOperatorState();
            testCase.verifyEqual(actualA, A, "RelTol", 0.1);
        end

        function testOperatorControlCurtailmentBc(testCase)
            Bc = [-0.139859138422979	-0.416910660971000	-0.0358602490585421	-0.278384899696989;
                    -0.136888900991948	0.0238648073407408	-0.301515792385676	-0.0565120468256036;
                    -0.135604779774731	-0.404228704710950	-0.0347694203688278	-0.269916742242841;
                    0.331050340997051	0.116724437833407	0.141101025161563	0.223887389415229;
                    0.393485740805238	0.0621361964846430	-0.211730694588934	0.227810968644941;
                    0.275463918197710	-0.178860634318050	0.0706296694273700	0.548301641939830;
                    -0.275463918197710	0.178860634318050	-0.0706296694273701	0.451698358060170;
                    1	0	0	0;
                    0	1	0	0;
                    0	0	1	0;
                    0	0	0	1;
                    0	0	0	0;
                    0	0	0	0;
                    -1	0	0	0;
                    0	-1	0	0;
                    0	0	-1	0;
                    0	0	0	-1];
            actualBc = testCase.model.getOperatorControlCurtailment();
            testCase.verifyEqual(actualBc, Bc, "RelTol",0.1);
        end

        function testOperatorControlBatteryBb(testCase)
            Bb = [0.278384899696989
                        0.0565120468256036
                        0.269916742242841
                        -0.223887389415229
                        -0.227810968644941
                        -0.548301641939830
                        -0.451698358060170
                        0
                        0
                        0
                        0
                        1
                        -0.00500000000000000
                        0
                        0
                        0
                        0];
            actualBb = testCase.model.getOperatorControlBattery();
            testCase.verifyEqual(actualBb, Bb, "RelTol",0.1);
        end

        function testOperatorDisturbancePowerGenerationDg(testCase)
            Dg = [0.139859138422979	0.416910660971000	0.0358602490585421	0.278384899696989;
                        0.136888900991948	-0.0238648073407408	0.301515792385676	0.0565120468256036;
                        0.135604779774731	0.404228704710950	0.0347694203688278	0.269916742242841;
                        -0.331050340997051	-0.116724437833407	-0.141101025161563	-0.223887389415229;
                        -0.393485740805238	-0.0621361964846430	0.211730694588934	-0.227810968644941;
                        -0.275463918197710	0.178860634318050	-0.0706296694273700	-0.548301641939830;
                        0.275463918197710	-0.178860634318050	0.0706296694273701	-0.451698358060170;
                        0	0	0	0;
                        0	0	0	0;
                        0	0	0	0;
                        0	0	0	0;
                        0	0	0	0;
                        0	0	0	0;
                        1	0	0	0;
                        0	1	0	0;
                        0	0	1	0;
                        0	0	0	1];
            actualDg = testCase.model.getOperatorDisturbancePowerGeneration();
            testCase.verifyEqual(actualDg, Dg, "RelTol",0.1);
        end

        function testOperatorDisturbancePowerTransitDn(testCase)
            Dn = [-0.0233449700937994	0.139859138422979	0.0857980884451168	0.416910660971000	0.0358602490585421	0.278384899696989;
                    -0.0630109426583430	0.136888900991948	0.0844491631202616	-0.0238648073407408	0.301515792385676	0.0565120468256036;
                    -0.0226348421998947	0.135604779774731	0.0831882065046485	0.404228704710950	0.0347694203688278	0.269916742242841;
                    -0.0645326041623123	-0.331050340997051	0.409819077885999	-0.116724437833407	-0.141101025161563	-0.223887389415229;
                    0.0185527918686182	-0.393485740805238	-0.240832782936233	-0.0621361964846430	0.211730694588934	-0.227810968644941;
                    0.0459798122936942	-0.275463918197710	-0.168986294949765	0.178860634318050	-0.0706296694273700	-0.548301641939830;
                    -0.0459798122936942	0.275463918197710	0.168986294949765	-0.178860634318050	0.0706296694273701	-0.451698358060170;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0;
                    0	0	0	0	0	0];
            actualDn = testCase.model.getOperatorDisturbancePowerTransit();
            testCase.verifyEqual(actualDn, Dn, "RelTol",0.1);
        end

    end
end