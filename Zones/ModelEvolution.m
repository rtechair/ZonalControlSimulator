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

classdef ModelEvolution < handle
% ModelEvolution aims at representing the evolution of the zone during the simulation.
% The associate mathematical model is based on the paper:
%'Modeling the Partial Renewable Power Curtailment for Transmission Network Management'[1].
%
% [1] https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v2/document
    
    properties (SetAccess = protected)
        state
        
        controlQueue
        controlCurt
        controlBatt
        
        queuePowerTransit % to compute disturbancePowerTransit
        
        disturbancePowerTransit
        disturbancePowerGeneration
        disturbancePowerAvailable
    end
    
    properties (SetAccess = immutable)
       %{
        From the paper 'Modeling the Partial Renewable Power Curtailment
        for Transmission Network Management', battConstPowerReduc corresponds to:
        T * C_n^B in the battery energy equation
        %}
       battConstPowerReduc
       delayCurt
       delayBatt
       maxPowerGeneration
       
       numberOfGenOn
       numberOfBattOn
    end
    
    methods
       
        function obj = ModelEvolution(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, ...
                delayCurt, delayBatt, maxPowerGeneration, battConstPowerReduc)
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.battConstPowerReduc = battConstPowerReduc;
            obj.delayCurt = delayCurt;
            obj.delayBatt = delayBatt;
            
            obj.numberOfGenOn = numberOfGenOn;
            obj.numberOfBattOn = numberOfBattOn;
            
            % blank state
            obj.state = StateOfZone(numberOfBranches, numberOfGenOn, numberOfBattOn);
            
            % blank queues
            obj.controlQueue = ControlQueue(numberOfGenOn, delayCurt, numberOfBattOn, delayBatt);
            
            obj.queuePowerTransit = NaN(numberOfBuses,2);
            
            % blank transit disturbance
            obj.disturbancePowerTransit = zeros(numberOfBuses, 1);
            
            obj.disturbancePowerAvailable = zeros(numberOfGenOn, 1);
        end
        
        %% GETTER
        function object = getState(obj)
            object = obj.state;
        end
        
        function value = getPowerBattery(obj)
            value = obj.state.getPowerBattery();
        end
        
        function value = getPowerGeneration(obj)
            value = obj.state.getPowerGeneration();
        end
        
        function value = getDisturbancePowerTransit(obj)
            value = obj.disturbancePowerTransit;
        end
        
        function value = getDisturbancePowerAvailable(obj)
            value = obj.disturbancePowerAvailable;
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
            initialPowerAvailable = timeSeries.getInitialPowerAvailable();
            obj.state.setPowerAvailable(initialPowerAvailable);
        end
        
        function setInitialPowerGeneration(obj)
            obj.state.setInitialPowerGeneration(obj.maxPowerGeneration);
        end
        
        function setPowerFlow(obj, value)
            obj.state.setPowerFlow(value);
        end
        
        function receiveDisturbancePowerAvailable2(obj, timeSeries)
            value = timeSeries.sendDisturbancePowerAvailable();
            obj.setDisturbancePowerAvailable(obj, value);
        end
        
        function setDisturbancePowerAvailable(obj, value)
            obj.disturbancePowerAvailable = value;
        end
        
        function receiveDisturbancePowerAvailable(obj, value)
            % FIXME this method should be replaced with method 2
            obj.disturbancePowerAvailable = value;
        end
        
        function receiveControl(obj, controlOfZone)
            obj.controlQueue.enqueue(controlOfZone);
        end
        
        function applyControlFromController(obj)
            control = obj.controlQueue.dequeue();
            obj.controlCurt = control.getControlCurtailment();
            obj.controlBatt = control.getControlBattery();
        end
        
        function applyNoControl(obj)
            obj.controlCurt = zeros(obj.numberOfGenOn,1);
            obj.controlBatt = zeros(obj.numberOfBattOn,1);
        end
        
        function computeDisturbancePowerGeneration(obj)
            % DeltaPG = min(f,g)
            % with  f = PA    + DeltaPA - PG + DeltaPC(k - delayCurt)
            % and   g = maxPG - PC      - PG
            powerAvailable = obj.state.getPowerAvailable();
            powerGeneration = obj.state.getPowerGeneration();
            powerCurtailment = obj.state.getPowerCurtailment();
            
            f = powerAvailable + obj.disturbancePowerAvailable - powerGeneration + obj.controlCurt;
            g = obj.maxPowerGeneration - powerCurtailment - powerGeneration;
            obj.disturbancePowerGeneration = min(f,g);
        end
        
        function updateState(obj)
            % energyBattery requires powerBattery, thus the former must be
            % updated prior to the latter
            obj.updateEnergyBattery();
            obj.updatePowerAvailable();
            obj.updatePowerGeneration();
            obj.updatePowerCurtailment();
            obj.updatePowerBattery();
        end
        
        function updateEnergyBattery(obj)
            obj.state.updateEnergyBattery(obj.controlBatt, obj.battConstPowerReduc);
        end
        
        function updatePowerAvailable(obj)
            obj.state.updatePowerAvailable(obj.disturbancePowerAvailable);
        end
        
        function updatePowerGeneration(obj)
            obj.state.updatePowerGeneration(obj.disturbancePowerGeneration, obj.controlCurt);
        end
        
        function updatePowerCurtailment(obj)
            obj.state.updatePowerCurtailment(obj.controlCurt);
        end
        
        function updatePowerBattery(obj)
            obj.state.updatePowerBattery(obj.controlBatt);
        end
        
        function updatePowerTransit(obj, electricalGrid, zoneBusesId, branchBorderIdx)
            obj.queuePowerTransit(:,2) = ...
                electricalGrid.getPowerTransit(zoneBusesId, branchBorderIdx);
        end
        
        function updateDisturbancePowerTransit(obj)
            obj.disturbancePowerTransit = obj.queuePowerTransit(:,2) - obj.queuePowerTransit(:,1);
        end
        
        function dropOldestPowerTransit(obj)
            obj.queuePowerTransit = obj.queuePowerTransit(:,2);
        end
        
        function saveState(obj, memory)
            memory.saveState(obj.state);
        end
        
        function saveDisturbance(obj, memory)
            memory.saveDisturbance(obj.disturbancePowerTransit,...
                obj.disturbancePowerGeneration,...
                obj.disturbancePowerAvailable);
        end
    end
    
end