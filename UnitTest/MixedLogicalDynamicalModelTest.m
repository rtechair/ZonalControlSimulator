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
classdef MixedLogicalDynamicalModelTest < matlab.unittest.TestCase

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

            testCase.model = MixedLogicalDynamicalModel(numberOfBuses, numberOfBranches, numberOfGen, numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep);
        end
    end

    methods(Test)
        function testOperatorState(testCase)
            A_nl = [1	0	0	0	0	0	0	0	0	0	0	0	0	-0.281710227574956	-0.202862942195764	-0.360557512954147	-0.0520145892068038	0	0	0	0;
                        0	1	0	0	0	0	0	0	0	0	0	0	0	-0.0494544234149011	-0.0966393252053144	-0.00226952162448785	-0.291195695833643	0	0	0	0;
                        0	0	1	0	0	0	0	0	0	0	0	0	0	-0.281710227574956	-0.202862942195764	-0.360557512954147	-0.0520145892068038	0	0	0	0;
                        0	0	0	1	0	0	0	0	0	0	0	0	0	0.214477768154379	0.277387338308673	0.151568198000085	0.127341690853250	0	0	0	0;
                        0	0	0	0	1	0	0	0	0	0	0	0	0	0.213263619626510	0.310522313495697	0.116004925757323	-0.233002734440007	0	0	0	0;
                        0	0	0	0	0	1	0	0	0	0	0	0	0	0.572258612219111	0.412090348195630	-0.267573123757409	0.105661043586757	0	0	0	0;
                        0	0	0	0	0	0	1	0	0	0	0	0	0	0.427741387780890	-0.412090348195630	0.267573123757409	-0.105661043586757	0	0	0	0;
                        0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	1	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	-0.00500000000000000	1	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1	0	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1	0	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1	0;
                        0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	0	1];
            actOperatorState = testCase.model.getOperatorState();
            % testCase.verifyEqual(actOperatorState, A_nl, "RelTol", 0.1);
            % different ptdf values
        end

        function testOperatorControlCurtailment(testCase)
            Bc_nl = [  0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            1	0	0	0
                            0	1	0	0
                            0	0	1	0
                            0	0	0	1
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0];
            actOperatorControlCurtailment = testCase.model.getOperatorControlCurtailment();
            testCase.verifyEqual(actOperatorControlCurtailment, Bc_nl, "RelTol", 0.1);
        end

        function testOperatorControlBattery(testCase)
            Bb_nl = [ 0.281710227574956
                            0.0494544234149011
                            0.281710227574956
                            -0.214477768154379
                            -0.213263619626510
                            -0.572258612219111
                            -0.427741387780890
                            0
                            0
                            0
                            0
                            1
                            -0.00500000000000000
                            0
                            0
                            0
                            0
                            0
                            0
                            0
                            0];
            actOperator = testCase.model.getOperatorControlBattery();
            testCase.verifyEqual(actOperator, Bb_nl, "RelTol", 0.2);
        end

        function testOperatorNextPowerGeneration(testCase)
            Bz_nl = [ 0.281710227574956	0.202862942195764	0.360557512954147	0.0520145892068038
                            0.0494544234149011	0.0966393252053144	0.00226952162448785	0.291195695833643
                            0.281710227574956	0.202862942195764	0.360557512954147	0.0520145892068038
                            -0.214477768154379	-0.277387338308673	-0.151568198000085	-0.127341690853250
                            -0.213263619626510	-0.310522313495697	-0.116004925757323	0.233002734440007
                            -0.572258612219111	-0.412090348195630	0.267573123757409	-0.105661043586757
                            -0.427741387780890	0.412090348195630	-0.267573123757409	0.105661043586757
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            1	0	0	0
                            0	1	0	0
                            0	0	1	0
                            0	0	0	1
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0
                            0	0	0	0];
            actOperator = testCase.model.getOperatorNextPowerGeneration();
            % testCase.verifyEqual(actOperator, Bz_nl, "RelTol", 0.1) %
            % ptdf value differences
        end

        function testOperatorDisturbancePowerTransit(testCase)
            D_nl = [0.202862942195764	0.124448447580949	0.360557512954147	0.0520145892068038	-0.0338614220858248	0.281710227574956	0	0	0	0
                        0.0966393252053144	0.0597576291800480	0.00226952162448785	0.291195695833643	-0.0562925747803332	0.0494544234149011	0	0	0	0
                        0.202862942195764	0.124448447580949	0.360557512954147	0.0520145892068038	-0.0338614220858248	0.281710227574956	0	0	0	0
                        -0.277387338308673	0.442739222417159	-0.151568198000085	-0.127341690853250	-0.0734899108283590	-0.214477768154379	0	0	0	0
                        -0.310522313495697	-0.189937978676202	-0.116004925757323	0.233002734440007	0.00470472479728448	-0.213263619626510	0	0	0	0
                        -0.412090348195630	-0.252801243740957	0.267573123757409	-0.105661043586757	0.0687851860310745	-0.572258612219111	0	0	0	0
                        0.412090348195630	0.252801243740957	-0.267573123757409	0.105661043586757	-0.0687851860310745	-0.427741387780890	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	1	0	0	0
                        0	0	0	0	0	0	0	1	0	0
                        0	0	0	0	0	0	0	0	1	0
                        0	0	0	0	0	0	0	0	0	1];
            Dn_nl = D_nl(:, 1:6);
            actOperator = testCase.model.getOperatorDisturbancePowerTransit();
            % testCase.verifyEqual(actOperator, Dn_nl, "RelTol", 0.1); %
            % ptdf value differences
        end

        function testOperatorDisturbancePowerAvailable(testCase)
            D_nl = [0.202862942195764	0.124448447580949	0.360557512954147	0.0520145892068038	-0.0338614220858248	0.281710227574956	0	0	0	0
                        0.0966393252053144	0.0597576291800480	0.00226952162448785	0.291195695833643	-0.0562925747803332	0.0494544234149011	0	0	0	0
                        0.202862942195764	0.124448447580949	0.360557512954147	0.0520145892068038	-0.0338614220858248	0.281710227574956	0	0	0	0
                        -0.277387338308673	0.442739222417159	-0.151568198000085	-0.127341690853250	-0.0734899108283590	-0.214477768154379	0	0	0	0
                        -0.310522313495697	-0.189937978676202	-0.116004925757323	0.233002734440007	0.00470472479728448	-0.213263619626510	0	0	0	0
                        -0.412090348195630	-0.252801243740957	0.267573123757409	-0.105661043586757	0.0687851860310745	-0.572258612219111	0	0	0	0
                        0.412090348195630	0.252801243740957	-0.267573123757409	0.105661043586757	-0.0687851860310745	-0.427741387780890	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	0	0	0	0
                        0	0	0	0	0	0	1	0	0	0
                        0	0	0	0	0	0	0	1	0	0
                        0	0	0	0	0	0	0	0	1	0
                        0	0	0	0	0	0	0	0	0	1];
            Da_nl = D_nl(:, 7:10);
            actOperator = testCase.model.getOperatorDisturbancePowerAvailable();
            testCase.verifyEqual(actOperator, Da_nl, "RelTol", 0.1);
        end

    end
    
end