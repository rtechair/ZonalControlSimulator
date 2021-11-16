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
classdef MpcWithUncertaintyTest2 < matlab.unittest.TestCase
   
    properties
        % Setup objects
        zoneName
        delayCurt
        delayBatt
        controlCycle
        predictionHorizon
        numberOfScenarios
        
        amplifierQ_ep1
        maxPowerGeneration
        minPowerBattery
        maxPowerBattery
        maxEnergyBattery
        flowLimit
        maxEpsilon
        
        % the object of the test
        mpc
    end
    
    methods(TestMethodSetup)
        function setProperties(testCase)
            testCase.zoneName = 'VGsmall';
            testCase.delayCurt = 9;
            testCase.delayBatt = 1;
            testCase.controlCycle = 5;
            testCase.predictionHorizon = 10;
            testCase.numberOfScenarios = 1;
            
            testCase.amplifierQ_ep1 = 10^7;
            testCase.maxPowerGeneration = [78;66;54;10];
            testCase.minPowerBattery = -10;
            testCase.maxPowerBattery = 10;
            testCase.maxEnergyBattery = 800;
            testCase.flowLimit = 45;
            testCase.maxEpsilon = 0.05;
        end
        
        function createMpc(testCase)
            testCase.mpc = MpcWithUncertainty(testCase.zoneName,...
                testCase.delayCurt, testCase.delayBatt,...
                testCase.controlCycle, testCase.predictionHorizon, ...
                testCase.numberOfScenarios);
            
            testCase.mpc.setOtherElements(testCase.amplifierQ_ep1, ...
                testCase.maxPowerGeneration, ...
                testCase.minPowerBattery, ...
                testCase.maxPowerBattery, ...
                testCase.maxEnergyBattery, ...
                testCase.flowLimit, ...
                testCase.maxEpsilon);
        end
        
    end
    
    methods(Test)
        function iteration4LeadingToInfeasibility(testCase)
             Fij = [6.21439798106191;0.600706612700478;5.13013181476226;-13.7447302485695;-6.98523245925417;-6.43543885555796;-2.92003463744106];
             PC = zeros(4,1);
             PB = -8.565314754417242e-04;
             EB = 1.690352046217284e-06;
             PG = [18.000000017999998;4.909090914000000;0.909090910000000;9.452145846000000];
             PA = [18.000000017999998;4.909090914000000;0.909090910000000;9.452145846000000];
             
             ucK_delay = [0,0,0,0,0,0,0.000406529702558886,0.000451565418533862,0.000632946461848040;...
                 0,0,0,0,0,0,0.000413512716104902,0.000469925921674176,0.000673088160758996;...
                 0,0,0,0,0,0,0.000382999422856887,0.000440131934420258,0.000538930074855163;...
                 0,0,0,0,0,0,0.000415874049394707,0.000462089473108724,0.000630702774841456];
             
             ubK_delay = -3.528591890483582e-04;
             
             % don't forget, xK_extend is built without PA
             
             Delta_PG_est = [0,0,0,0,0,0,0.000406529702558886,4.50357159748069e-05,0.000181381043314734,-0.000632946461848860;...
                 0,0,0,0,0,0,0.000413512716104902,5.64132055690514e-05,0.000203162239084721,-0.000673088160758617;...
                 0,0,0,0,0,0,0.000382999422856887,5.71325115633469e-05,9.87981404348893e-05,-0.000538930074855171;...
                 -1.18421776200000,-1.18421776200000,-1.18421776200000,-1.18421776200000,-1.18421776200000,-1.18421776200000,-1.18380188795060,-1.16257529657629,0.000168613301732794,-0.000630702774841456];
             
             Delta_PT = [-0.707082888723868;0;-0.248718167317501;0;-0.199024946321148;0];
             Delta_PT_est = repmat(Delta_PT, 1, 10);
             
             Delta_PA = [ 0 ; 0 ; 0 ; -1.1842];
             
             numberOfBranches = 7;
             numberOfGen = 4;
             numberOfBatt = 1;
             state = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
             state.setPowerFlow(Fij);
             state.setPowerCurtailment(PC);
             state.setPowerBattery(PB);
             state.setEnergyBattery(EB);
             state.setPowerGeneration(PG);
             state.setPowerAvailable(PA);
            
            % testCase.mpc.decomposeState(state);
            % testCase.mpc.Delta_PG_est = Delta_PG_est;
            % testCase.mpc.Delta_PT_est = Delta_PT_est;
             testCase.mpc.ucK_delay = ucK_delay;
             testCase.mpc.ubK_delay = ubK_delay;
            % testCase.mpc.set_xK_extend(state);
            
            % testCase.mpc.doControl();
            
            claimedFeasibleU = zeros(numberOfGen + numberOfBatt,testCase.predictionHorizon);
            assign(testCase.mpc.u, claimedFeasibleU);
            check(testCase.mpc.constraints);
             testCase.mpc.operateOneOperation(state, Delta_PA, Delta_PT);
         end
        
    end
    
end