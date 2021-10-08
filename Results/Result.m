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

classdef Result < handle
   
    properties (SetAccess = protected)
        % State
        powerBranchFlow         % Fij
        powerCurtailment        % PC
        powerBattery            % PB
        energyBattery           % EB
        powerGeneration         % PG
        powerAvailable          % PA
        
        % Control
        controlCurtailment      % DeltaPC
        controlBattery          % DeltaPB
        
        % Disturbance
        disturbanceTransit      % DeltaPT
        disturbanceGeneration   % DeltaPG
        disturbanceAvailable    % DeltaPA
        
        step             % k
        
        branchFlowLimit  % maxFij
    end
    
    properties ( SetAccess = immutable)
        zoneName
        controlCycle
        numberOfIterations
        
        numberOfBuses
        numberOfBranches
        numberOfGen
        numberOfBatt
                    
        maxPowerGeneration
        
        busId
        branchIdx
        genOnIdx
        battOnIdx
        
        delayCurt
        delayBatt
        delayTimeSeries2Zone
        delayController2Zone
        delayZone2Controller
    end
    
    methods
        
        function obj = Result(zoneName, durationSimulation, controlCycle, ...
                numberOfBuses, numberOfBranches, numberOfGenerators, numberOfBatteries, ...
                maxPowerGeneration, branchFlowLimit, busId, branchIdx, genOnIdx, battOnIdx, delayCurt, delayBatt, ...
                delayTimeSeries2Zone, delayController2Zone, delayZone2Controller)
            obj.zoneName = zoneName;
            obj.numberOfIterations = floor(durationSimulation / controlCycle);
            obj.numberOfBuses = numberOfBuses;
            obj.numberOfBranches = numberOfBranches;
            obj.numberOfGen = numberOfGenerators;
            obj.numberOfBatt = numberOfBatteries;
            
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.branchFlowLimit = branchFlowLimit;
            obj.controlCycle = controlCycle;
            
            obj.busId = busId;
            obj.branchIdx = branchIdx;
            obj.genOnIdx = genOnIdx;
            obj.battOnIdx = battOnIdx;
            
            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            
            obj.delayTimeSeries2Zone = delayTimeSeries2Zone;
            obj.delayController2Zone = delayController2Zone;
            obj.delayZone2Controller = delayZone2Controller;
            
            obj.step = 0; % 0, i.e. initialization before the actual simulation
            
            % State
            obj.powerBranchFlow = NaN(numberOfBranches, obj.numberOfIterations + 1);
            obj.powerCurtailment = NaN(numberOfGenerators, obj.numberOfIterations + 1);
            obj.powerBattery = NaN(numberOfBatteries, obj.numberOfIterations + 1);
            obj.energyBattery = NaN(numberOfBatteries, obj.numberOfIterations + 1);
            obj.powerGeneration = NaN(numberOfGenerators, obj.numberOfIterations + 1);
            obj.powerAvailable = NaN(numberOfGenerators, obj.numberOfIterations + 1);
            
            % Control
            obj.controlCurtailment = NaN(numberOfGenerators, obj.numberOfIterations);
            obj.controlBattery = NaN(numberOfBatteries, obj.numberOfIterations);
            
            % Disturbance 
            obj.disturbanceTransit = NaN(numberOfBuses, obj.numberOfIterations);
            obj.disturbanceGeneration = NaN(numberOfGenerators, obj.numberOfIterations);
            obj.disturbanceAvailable = NaN(numberOfGenerators, obj.numberOfIterations);
        end
        
        
        function saveState(obj, powerBranchFlow, powerCurtailment, powerBattery, ...
                energyBattery, powerGeneration, powerAvailable)
            obj.powerBranchFlow(:, obj.step + 1) = powerBranchFlow;
            obj.powerCurtailment(:, obj.step + 1) = powerCurtailment;
            obj.powerBattery(:, obj.step + 1) = powerBattery;
            obj.energyBattery(:, obj.step + 1) = energyBattery;
            obj.powerGeneration(:, obj.step + 1) = powerGeneration;
            obj.powerAvailable(:, obj.step + 1) = powerAvailable;
        end
        
        function saveState2(obj, state)
            obj.powerBranchFlow(:, obj.step + 1) = state.getPowerBranchFlow();
            obj.powerCurtailment(:, obj.step + 1) = state.getPowerCurtailment();
            obj.powerBattery(:, obj.step + 1) = state.getPowerBattery();
            obj.energyBattery(:, obj.step + 1) = state.getEnergyBattery();
            obj.powerGeneration(:, obj.step + 1) = state.getPowerGeneration();
            obj.powerAvailable(:, obj.step + 1) = state.getPowerAvailable();
        end
        
        function saveControl(obj, controlCurt, controlBatt)
            obj.controlCurtailment(:, obj.step) = controlCurt;
            obj.controlBattery(:, obj.step) = controlBatt;
        end
        
        function saveControl2(obj, control)
            obj.controlCurtailment(:, obj.step) = control.getControlCurtailment();
            obj.controlBattery(:, obj.step) = control.getControlBattery();
        end
        
        function saveDisturbance(obj, transit, generation, available)
            obj.disturbanceTransit(:, obj.step) = transit;
            obj.disturbanceGeneration(:, obj.step) = generation;
            obj.disturbanceAvailable(:, obj.step) = available;
        end
        
        function prepareForNextStep(obj)
            obj.step = obj.step + 1;
        end
 
    end
    
end