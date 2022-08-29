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
classdef MixedLogicalDynamicalModelPredictiveControllerTest1 < matlab.unittest.TestCase
    
    properties
        % Setup objects
        zoneName
        delayCurt
        delayBatt
        delayTelecom
        controlCycle
        predictionHorizonInSeconds
        predictionHorizon
        numberOfScenarios
        
        maxPowerGeneration
        minPowerBattery
        maxPowerBattery
        maxEnergyBattery
        flowLimit
        maxEpsilon

        numberOfBuses
        numberOfBranches
        numberOfGen
        numberOfBatt
        
        % the object of the test
        controller
    end
    
    methods(TestMethodSetup)
        function setProperties(testCase)
            testCase.delayCurt = 9;
            testCase.delayBatt = 1;
            testCase.delayTelecom = 0;
            testCase.controlCycle = 5;
            testCase.predictionHorizonInSeconds = 50; %such that the horizon is 10 iterations
            horizonInIterations = ceil(testCase.predictionHorizonInSeconds / testCase.controlCycle);
            testCase.predictionHorizon = horizonInIterations;
            
            testCase.maxPowerGeneration = [78;66;54;10];
            testCase.minPowerBattery = -10;
            testCase.maxPowerBattery = 10;
            testCase.maxEnergyBattery = 800;
            testCase.flowLimit = 45;
            testCase.maxEpsilon = 0.05;

            testCase.numberOfBuses = 6;
            testCase.numberOfBranches = 7;
            testCase.numberOfGen = 4;
            testCase.numberOfBatt = 1;
        end
        
        function createController(testCase)
            basecaseName = 'case6468rte_zone_VG_VTV_BLA';
            busId = [1445, 2076, 2135, 2745, 4720, 10000]';
            batteryCoef = 0.001;
            timestep = 5;
            zonePTDFConstructor = ZonePTDFConstructor(basecaseName);
            [branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF] = zonePTDFConstructor.getZonePTDF(busId);
            model = MixedLogicalDynamicalModel(testCase.numberOfBuses, testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt, ...
                    branchPerBusPTDF, branchPerBusOfGenPTDF, branchPerBusOfBattPTDF, batteryCoef, timestep, testCase.delayCurt, testCase.delayBatt);

            operatorStateExtended = model.getOperatorStateExtended();
            operatorControlExtended = model.getOperatorControlExtended();
            operatorNextPowerGenerationExtended = model.getOperatorNextPowerGenerationExtended();
            operatorDisturbanceExtended = model.getOperatorDisturbanceExtended();

            testCase.controller = MixedLogicalDynamicalModelPredictiveController(testCase.delayCurt, testCase.delayBatt, testCase.delayTelecom, ...
                testCase.controlCycle, testCase.predictionHorizonInSeconds, ...
                operatorStateExtended, operatorControlExtended, operatorNextPowerGenerationExtended, operatorDisturbanceExtended, ...
                testCase.numberOfBuses, testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt, ... % following: where starts setOtherElements
                testCase.maxPowerGeneration, testCase.minPowerBattery, testCase.maxPowerBattery, testCase.maxEnergyBattery, testCase.flowLimit);
        end
        
    end
    
    methods(Test)
        
         function correctDeltaPA1(testCase)
            state = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 0 * ones(testCase.numberOfBranches,1);
            PC = zeros(testCase.numberOfGen, 1);
            PB = 0 * ones(testCase.numberOfBatt, 1);
            EB = 0 * ones(testCase.numberOfBatt, 1);
            PG = [10.5; 5; 5.8; 7];
            PA = PG;
            state.setPowerFlow(Fij);
            state.setPowerCurtailment(PC);
            state.setPowerBattery(PB);
            state.setEnergyBattery(EB);
            state.setPowerGeneration(PG);
            state.setPowerAvailable(PA);
            
            deltaPA = [ -2; 1; -2.3; -0.2];
            
            testCase.controller.decomposeState(state);
            testCase.controller.setDelta_PA_est_constant_over_horizon(deltaPA);
            
            
            realDelta_PA_est = testCase.controller.Delta_PA_est;
            
            expected_Delta_PA_est = ...
                [-2,-2,-2,-2,-2,-0.5,0,0,0,0;...
                1,1,1,1,1,1,1,1,1,1;...
                -2.3,-2.3,-1.2,0,0,0,0,0,0,0;...
                -0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2,-0.2];
            
            testCase.verifyEqual(realDelta_PA_est, expected_Delta_PA_est, "AbsTol", 0.01);
         end
         
         function correctDeltaPA2(testCase)
            state = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 0 * ones(testCase.numberOfBranches,1);
            PC = zeros(testCase.numberOfGen, 1);
            PB = 0 * ones(testCase.numberOfBatt, 1);
            EB = 0 * ones(testCase.numberOfBatt, 1);
            PG = [10.5; 5; 5.8; 7];
            PA = PG;
            state.setPowerFlow(Fij);
            state.setPowerCurtailment(PC);
            state.setPowerBattery(PB);
            state.setEnergyBattery(EB);
            state.setPowerGeneration(PG);
            state.setPowerAvailable(PA);
            
            deltaPA = [ 0.0 ; 0.1; 0.5; 0.02];
            
            testCase.controller.decomposeState(state);
            testCase.controller.setDelta_PA_est_constant_over_horizon(deltaPA);
            
            
            realDelta_PA_est = testCase.controller.Delta_PA_est;
            expected_Delta_PA_est = repmat(deltaPA, 1, testCase.predictionHorizon);
            testCase.verifyEqual(realDelta_PA_est, expected_Delta_PA_est, "AbsTol", 0.01);
         end
         
         function correctDeltaPA3(testCase)
            state = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 0 * ones(testCase.numberOfBranches,1);
            PC = zeros(testCase.numberOfGen, 1);
            PB = 0 * ones(testCase.numberOfBatt, 1);
            EB = 0 * ones(testCase.numberOfBatt, 1);
            PG = [10.5; 10.5; 10.5; 7.0];
            PA = PG;
            state.setPowerFlow(Fij);
            state.setPowerCurtailment(PC);
            state.setPowerBattery(PB);
            state.setEnergyBattery(EB);
            state.setPowerGeneration(PG);
            state.setPowerAvailable(PA);
            
            deltaPA = [ -4.3; -0.01; -12.1; -7.0];
            
            testCase.controller.decomposeState(state);
            testCase.controller.setDelta_PA_est_constant_over_horizon(deltaPA);
            
            
            realDelta_PA_est = testCase.controller.Delta_PA_est;
            expected_Delta_PA_est = ...
                [- 4.3, - 4.3, -1.9, zeros(1, 7);...
                 -0.01 * ones(1,10);...
                 -10.5, zeros(1,9);...
                 -7.0, zeros(1,9)];
            testCase.verifyEqual(realDelta_PA_est, expected_Delta_PA_est, "AbsTol", 0.01);
         end
        
        
        %% CLOSED LOOP SIMULATION
        
        function attemptSituation1(testCase)
            initialState = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 40 * ones(testCase.numberOfBranches,1); % near branch limit
            PC = zeros(testCase.numberOfGen, 1);
            PB = zeros(testCase.numberOfBatt, 1);
            EB = 750 * ones(testCase.numberOfBatt, 1);
            PG = [50;50;50;10]; % a medium margin to increase
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 4 * ones(testCase.numberOfGen, 1); % a high increase
            deltaPT = zeros(testCase.numberOfBuses, 1);
            testCase.controller.operateOneOperation(initialState, deltaPA, deltaPT);
        end
        
         function attemptSituation2(testCase)
            
            initialState = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 40 * ones(testCase.numberOfBranches,1); % near branch limit
            PC = zeros(testCase.numberOfGen, 1);
            PB = zeros(testCase.numberOfBatt, 1);
            EB = 750 * ones(testCase.numberOfBatt, 1);
            PG = [20;20;20;10]; % high margin of progression
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 4 * ones(testCase.numberOfGen, 1); % high increase
            deltaPT = zeros(testCase.numberOfBuses, 1);
            testCase.controller.operateOneOperation(initialState, deltaPA, deltaPT);
         end
        
         function attemptSituation3(testCase)
            initialState = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 20 * ones(testCase.numberOfBranches,1);  % low flow
            PC = zeros(testCase.numberOfGen, 1);
            PB = zeros(testCase.numberOfBatt, 1);
            EB = 750 * ones(testCase.numberOfBatt, 1);
            PG = [20;20;20;10];
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 4 * ones(testCase.numberOfGen, 1);
            deltaPT = zeros(testCase.numberOfBuses, 1);
            testCase.controller.operateOneOperation(initialState, deltaPA, deltaPT);
         end
        
         function attemptSituation4(testCase)
            initialState = StateOfZone(testCase.numberOfBranches, testCase.numberOfGen, testCase.numberOfBatt);
            Fij = 20 * ones(testCase.numberOfBranches,1);  % low flow
            PC = zeros(testCase.numberOfGen, 1);
            PB = -10 * ones(testCase.numberOfBatt, 1); % max injection in the battery
            EB = 750 * ones(testCase.numberOfBatt, 1);
            PG = [20;20;20;10];
            PA = PG;
            initialState.setPowerFlow(Fij);
            initialState.setPowerCurtailment(PC);
            initialState.setPowerBattery(PB);
            initialState.setEnergyBattery(EB);
            initialState.setPowerGeneration(PG);
            initialState.setPowerAvailable(PA);
            
            deltaPA = 3 * ones(testCase.numberOfGen, 1);
            deltaPT = zeros(testCase.numberOfBuses, 1);
            testCase.controller.operateOneOperation(initialState, deltaPA, deltaPT);
         end
        
         
    end
    
    
end