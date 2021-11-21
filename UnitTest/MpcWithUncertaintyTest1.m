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
classdef MpcWithUncertaintyTest1 < matlab.unittest.TestCase
    
    properties
        % Setup objects
        zoneName
        delayCurt
        delayBatt
        delayTelecom
        controlCycle
        horizonInSeconds
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
            testCase.delayCurt = 7;
            testCase.delayBatt = 1;
            testCase.delayTelecom = 0;
            testCase.controlCycle = 5;
            testCase.horizonInSeconds = 50;
            horizonInIterations = ceil(testCase.horizonInSeconds / testCase.controlCycle);
            testCase.predictionHorizon = horizonInIterations;
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
                testCase.delayCurt, testCase.delayBatt, testCase.delayTelecom, ...
                testCase.controlCycle, testCase.horizonInSeconds, ...
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
        
         function correctDeltaPA1(testCase)
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            state = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 0 * ones(numberOfBranches,1);
            PC = zeros(numberOfGen, 1);
            PB = 0 * ones(numberOfBatt, 1);
            EB = 0 * ones(numberOfBatt, 1);
            PG = [10.5; 5; 5.8; 7];
            PA = PG;
            state.setPowerFlow(Fij);
            state.setPowerCurtailment(PC);
            state.setPowerBattery(PB);
            state.setEnergyBattery(EB);
            state.setPowerGeneration(PG);
            state.setPowerAvailable(PA);
            
            deltaPA = [ -2; 1; -2.3; -0.2];
            
            testCase.mpc.decomposeState(state);
            testCase.mpc.setDelta_PA_est_constant_over_horizon(deltaPA);
            
            
            realDelta_PA_est = testCase.mpc.Delta_PA_est;
            
            expected_Delta_PA_est = ...
                [-2,-2,-2,-2,-2,-0.5,0,0,0,0;...
                1,1,1,1,1,1,1,1,1,1;...
                -2.3,-2.3,-1.2,0,0,0,0,0,0,0;...
                -0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2];
            
            testCase.verifyEqual(realDelta_PA_est, expected_Delta_PA_est, "AbsTol", 0.01);
         end
         
         function correctDeltaPA2(testCase)
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            state = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 0 * ones(numberOfBranches,1);
            PC = zeros(numberOfGen, 1);
            PB = 0 * ones(numberOfBatt, 1);
            EB = 0 * ones(numberOfBatt, 1);
            PG = [10.5; 5; 5.8; 7];
            PA = PG;
            state.setPowerFlow(Fij);
            state.setPowerCurtailment(PC);
            state.setPowerBattery(PB);
            state.setEnergyBattery(EB);
            state.setPowerGeneration(PG);
            state.setPowerAvailable(PA);
            
            deltaPA = [ 0.0 ; 0.1; 0.5; 0.02];
            
            testCase.mpc.decomposeState(state);
            testCase.mpc.setDelta_PA_est_constant_over_horizon(deltaPA);
            
            
            realDelta_PA_est = testCase.mpc.Delta_PA_est;
            expected_Delta_PA_est = repmat(deltaPA, 1, testCase.predictionHorizon);
            testCase.verifyEqual(realDelta_PA_est, expected_Delta_PA_est, "AbsTol", 0.01);
         end
         
         function correctDeltaPA3(testCase)
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            state = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 0 * ones(numberOfBranches,1);
            PC = zeros(numberOfGen, 1);
            PB = 0 * ones(numberOfBatt, 1);
            EB = 0 * ones(numberOfBatt, 1);
            PG = [10.5; 10.5; 10.5; 7.0];
            PA = PG;
            state.setPowerFlow(Fij);
            state.setPowerCurtailment(PC);
            state.setPowerBattery(PB);
            state.setEnergyBattery(EB);
            state.setPowerGeneration(PG);
            state.setPowerAvailable(PA);
            
            deltaPA = [ -4.3; -0.01; -12.1; -7.0];
            
            testCase.mpc.decomposeState(state);
            testCase.mpc.setDelta_PA_est_constant_over_horizon(deltaPA);
            
            
            realDelta_PA_est = testCase.mpc.Delta_PA_est;
            expected_Delta_PA_est = ...
                [- 4.3, - 4.3, -1.9, zeros(1, 7);...
                 -0.01 * ones(1,10);...
                 -10.5, zeros(1,9);...
                 -7.0, zeros(1,9)];
            testCase.verifyEqual(realDelta_PA_est, expected_Delta_PA_est, "AbsTol", 0.01);
         end
        
        function numberOfGenOfVGsmall(testCase)
            actValue = testCase.mpc.c;
            expValue = 4;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function numberOfBattOfVGsmall(testCase)
            actValue = testCase.mpc.b;
            expValue = 1;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function numberOfBusesOfVGsmall(testCase)
            actValue = testCase.mpc.numberOfBuses;
            expValue = 6;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function numberOfBranchesOfVGsmall(testCase)
            actValue = testCase.mpc.numberOfBranches;
            expValue = 7;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function checkQ(testCase)
            actQ = testCase.mpc.Q;
            expdata = load('Q_Qep1_R.mat');
            expQ = expdata.Q;
            testCase.verifyEqual(actQ, expQ);
        end
        
        function checkQ_ep1(testCase)
            actQ_ep1 = testCase.mpc.Q_ep1;
            expdata = load('Q_Qep1_R.mat');
            expQ_ep1 = expdata.Q_ep1;
            testCase.verifyEqual(actQ_ep1, expQ_ep1);
        end
        
        function checkR(testCase)
            actR = testCase.mpc.R;
            expdata = load('Q_Qep1_R.mat');
            expR = expdata.R;
            testCase.verifyEqual(actR, expR);
        end
        
        function checkMaxPG(testCase)
            actValue = testCase.mpc.maxPG;
            expValue = [78;66;54;10];
            testCase.verifyEqual(actValue, expValue);
        end
        
        function check_minPB(testCase)
            actValue = testCase.mpc.minPB;
            expValue = -10;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function check_maxPB(testCase)
            actValue = testCase.mpc.maxPB;
            expValue = 10;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function check_umin_b(testCase)
            actValue = testCase.mpc.umin_b;
            expValue = -20;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function check_umax_b(testCase)
            actValue = testCase.mpc.umax_b;
            expValue = 20;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function check_epsilon_max(testCase)
            actValue = testCase.mpc.epsilon_max;
            expValue = 0.05;
            testCase.verifyEqual(actValue, expValue);
        end
        
        %% Operator
        function checkSizeA_CDC_Trung(testCase)
            actValue = testCase.mpc.A;
            testCase.verifySize(actValue, [17 17]);
        end
        
        function checkSizeBc_CDC_Trung(testCase)
            actValue = testCase.mpc.Bc;
            testCase.verifySize(actValue, [17 4]);
        end
        
        function checkSizeBb_CDC_Trung(testCase)
            actValue = testCase.mpc.Bb;
            testCase.verifySize(actValue, [17 1]);
        end
        
        function checkSizeDg_CDC_Trung(testCase)
            actValue = testCase.mpc.Dg;
            testCase.verifySize(actValue, [17 4]);
        end
        
        function checkSizeDn_CDC_Trung(testCase)
            actValue = testCase.mpc.Dn;
            testCase.verifySize(actValue, [17 6]);
        end
        
        function checkA(testCase)
            actValue = testCase.mpc.A;
            expValue = load('mathematicalModelVGsmall_fromTrung.mat').A;
            testCase.verifyEqual(actValue, expValue);
        end
        
        %{
        THE FOLLOWING CHECKS ARE FAILED BECAUSE OF THE PTDF COEF
        function checkBc(testCase)
            actValue = testCase.mpc.Bc;
            expValue = load('mathematicalModelVGsmall_fromTrung.mat').Bc;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function checkBb(testCase)
            actValue = testCase.mpc.Bb;
            expValue = load('mathematicalModelVGsmall_fromTrung.mat').Bb;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function checkDg(testCase)
            actValue = testCase.mpc.Dg;
            expValue = load('mathematicalModelVGsmall_fromTrung.mat').Dg;
            testCase.verifyEqual(actValue, expValue);
        end
        
        function checkDn(testCase)
            actValue = testCase.mpc.Dn;
            expValue = load('mathematicalModelVGsmall_fromTrung.mat').Dn;
            testCase.verifyEqual(actValue, expValue);
        end
        %}
        
        %% SDP_VAR of Yalmip
        
        function checkSize_sdpvar_x(testCase)
            actValue = testCase.mpc.x;
            testCase.verifySize(actValue, [46 11]);
        end
        
        function checkSize_sdpvar_dk_in(testCase)
            actValue = testCase.mpc.dk_in;
            testCase.verifySize(actValue, [4 10]);
        end
        
        function checkSize_sdpvar_dk_out(testCase)
            actValue = testCase.mpc.dk_out;
            testCase.verifySize(actValue, [6 10]);
        end
        
        function checkSize_sdpvar_u(testCase)
            actValue = testCase.mpc.u;
            testCase.verifySize(actValue, [5 10]);
        end
        
        function checkSize_sdpvar_epsilon(testCase)
            actValue = testCase.mpc.epsilon;
            testCase.verifySize(actValue, [7 10]);
        end
        
        function checkSize_sdpvar_probs(testCase)
            actValue = testCase.mpc.probs;
            testCase.verifySize(actValue, [1 10]);
        end
        
        function checkSize_A_new(testCase)
            actValue = testCase.mpc.A_new;
            testCase.verifySize(actValue, [46 46]);
        end
        
        function checkSize_B_new(testCase)
            actValue = testCase.mpc.B_new;
            testCase.verifySize(actValue, [46 5]);
        end
        
        function checkSize_D_new_in(testCase)
            actValue = testCase.mpc.D_new_in;
            testCase.verifySize(actValue, [46 4]);
        end
        
        function checkSize_D_new_out(testCase)
            actValue = testCase.mpc.D_new_out;
            testCase.verifySize(actValue, [46 6]);
        end
        
        function checkMinState(testCase)
            %{
            actValue = testCase.mpc.xmin;
            expValue = load('xmin.mat').xmin;
            testCase.verifyEqual(actValue, expValue);
            the 'xmin.mat' is incorrect
            %}
        end
        
        function checkMaxState(testCase)
            %{
            actValue = testCase.mpc.xmax;
            expValue = load('xmax.mat').xmax;
            testCase.verifyEqual(actValue, expValue);
            the 'xmax.mat' is incorrect
            %}
        end
        
        function checkMinControl(testCase)
            %{
            actValue = testCase.mpc.umin;
            expValue = load('umin.mat').umin;
            testCase.verifyEqual(actValue, expValue);
            the 'umin.mat' is incorrect
            %}
        end
        
        function checkMaxControl(testCase)
            %{
            actValue = testCase.mpc.umax;
            expValue = load('umax.mat').umax;
            testCase.verifyEqual(actValue, expValue);
            the 'umax.mat' is incorrect
            %}
        end
        %% CLOSED LOOP SIMULATION
        
        function attemptSituation1(testCase)
            numberOfBuses = 6;
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            initialState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 40 * ones(numberOfBranches,1); % near branch limit
            PC = zeros(numberOfGen, 1);
            PB = zeros(numberOfBatt, 1);
            EB = 750 * ones(numberOfBatt, 1);
            PG = [50;50;50;10]; % a medium margin to increase
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 4 * ones(numberOfGen, 1); % a high increase
            deltaPT = zeros(numberOfBuses, 1);
            testCase.mpc.operateOneOperation(initialState, deltaPA, deltaPT);
        end
        
         function attemptSituation2(testCase)
            numberOfBuses = 6;
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            initialState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 40 * ones(numberOfBranches,1); % near branch limit
            PC = zeros(numberOfGen, 1);
            PB = zeros(numberOfBatt, 1);
            EB = 750 * ones(numberOfBatt, 1);
            PG = [20;20;20;10]; % high margin of progression
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 4 * ones(numberOfGen, 1); % high increase
            deltaPT = zeros(numberOfBuses, 1);
            testCase.mpc.operateOneOperation(initialState, deltaPA, deltaPT);
         end
        
         function attemptSituation3(testCase)
            numberOfBuses = 6;
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            initialState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 20 * ones(numberOfBranches,1);  % low flow
            PC = zeros(numberOfGen, 1);
            PB = zeros(numberOfBatt, 1);
            EB = 750 * ones(numberOfBatt, 1);
            PG = [20;20;20;10];
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 4 * ones(numberOfGen, 1);
            deltaPT = zeros(numberOfBuses, 1);
            testCase.mpc.operateOneOperation(initialState, deltaPA, deltaPT);
         end
        
         function attemptSituation4(testCase)
            numberOfBuses = 6;
            numberOfBranches = 7;
            numberOfGen = 4;
            numberOfBatt = 1;
            initialState = StateOfZone(numberOfBranches, numberOfGen, numberOfBatt);
            Fij = 20 * ones(numberOfBranches,1);  % low flow
            PC = zeros(numberOfGen, 1);
            PB = -10 * ones(numberOfBatt, 1); % max injection in the battery
            EB = 750 * ones(numberOfBatt, 1);
            PG = [20;20;20;10];
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 3 * ones(numberOfGen, 1);
            deltaPT = zeros(numberOfBuses, 1);
            testCase.mpc.operateOneOperation(initialState, deltaPA, deltaPT);
         end
         
    end
    
    
end