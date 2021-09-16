classdef ZoneEvolution < handle
% ZoneEvolution aims at representing the evolution of the zone during the simulation.
% The associate mathematical model is based on the paper:
%'Modeling the Partial Renewable Power Curtailment for Transmission Network Management'[1].
%
% [1] https://hal-centralesupelec.archives-ouvertes.fr/hal-03004441v2/document
    
    properties (SetAccess = protected)
        state
        
        % When received from the telecom, the controls are delayed before applied, thus the queues
        queueControlCurt
        queueControlBatt
        
        queuePowerTransit % to compute disturbancePowerTransit
        
        disturbancePowerTransit
        disturbancePowerGeneration
        disturbancePowerAvailable
    end
    
    properties (SetAccess = immutable)
       maxPowerGeneration
       
       %{
        From the paper 'Modeling the Partial Renewable Power Curtailment
        for Transmission Network Management', battConstPowerReduc corresponds to:
        T * C_n^B in the battery energy equation
        %}
       battConstPowerReduc
    end
    
    methods
       
        function obj = ZoneEvolution(numberOfBuses, numberOfBranches, numberOfGenOn, numberOfBattOn, ...
                delayCurt, delayBatt, maxPowerGeneration, battConstPowerReduc)
            obj.maxPowerGeneration = maxPowerGeneration;
            obj.battConstPowerReduc = battConstPowerReduc;
            
            % blank state
            obj.state = StateOfZone(numberOfBranches, numberOfGenOn, numberOfBattOn);
            
            % blank queues
            obj.queueControlCurt = zeros(numberOfGenOn, delayCurt);
            obj.queueControlBatt = zeros(numberOfBattOn, delayBatt);
            
            obj.queuePowerTransit = zeros(numberOfBuses,1);
            
            % blank transit disturbance
            obj.disturbancePowerTransit = zeros(numberOfBuses, 1);
        end
        
        function object = getState(obj)
            object = obj.state;
        end
        
        
        function receiveDisturbancePowerAvailable(obj, objectDisturbancePowerAvailable)
            % the telecommunication from time series to zone, transmits objects, not values directly
            obj.disturbancePowerAvailable = objectDisturbancePowerAvailable.getValue();
        end
        
        function receiveControl(obj, controlOfZone)
            % the telecommunication from controller to zone, transmits objects, not values directly
            obj.queueControlCurt(:,end+1) = controlOfZone.getControlCurtailment();
            obj.queueControlBatt(:,end+1) = controlOfZone.getControlBattery();
        end
        
        function dropOldestControl(obj)
            obj.queueControlCurt = obj.queueControlCurt(:, 2:end);
            obj.queueControlBatt = obj.queueControlBatt(:, 2:end);
        end
        
        function updatePowerTransit(obj, electricalGrid, zoneBusesId, branchBorderIdx)
            obj.queuePowerTransit(:,end+1) = ...
                electricalGrid.getPowerTransit(zoneBusesId, branchBorderIdx);
        end
                
        function updateDisturbancePowerTransit(obj)
            obj.disturbancePowerTransit = obj.queuePowerTransit(:,2) - obj.queuePowerTransit(:,1);
        end
        
        function dropOldestPowerTransit(obj)
            obj.queuePowerTransit = obj.queuePowerTransit(:,2);
        end
        
        function saveState(obj, memory)
            memory.saveState(...
                obj.state.getPowerFlow, ...
                obj.state.getPowerCurtailment, ...
                obj.state.getPowerBattery,...
                obj.state.getEnergyBattery,...
                obj.state.getPowerGeneration,...
                obj.state.getPowerAvailable);
        end
        
        function saveDisturbance(obj, memory)
            memory.saveDisturbance(obj.disturbancePowerTransit,...
                obj.disturbancePowerGeneration,...
                obj.disturbancePowerAvailable);
        end
        
        function object = getStateAndDisturbancePowerTransit(obj)
            object = StateAndDisturbancePowerTransit(obj.state, obj.disturbancePowerTransit);
        end
        
        function computeDisturbancePowerGeneration(obj)
            % DeltaPG = min(f,g)
            % with  f = PA    + DeltaPA - PG + DeltaPC(k - delayCurt)
            % and   g = maxPG - PC      - PG
            powerAvailable = obj.state.getPowerAvailable();
            powerGeneration = obj.state.getPowerGeneration();
            appliedControlCurt = obj.queueControlCurt(:,1);
            powerCurtailment = obj.state.getPowerCurtailment();
            
            f = powerAvailable + obj.disturbancePowerAvailable - powerGeneration + appliedControlCurt;
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
            % energyBattery requires powerBattery, thus the former must be
            % updated prior to the latter
            % EB += -cb * ( PB(k) + DeltaPB(k - delayBatt) )
            appliedControlBatt = obj.queueControlBatt(:,1);
            oldPowerBattery = obj.state.getPowerBattery();
            oldEnergyBattery = obj.state.getEnergyBattery();
            newEnergyBattery = oldEnergyBattery ...
                - obj.battConstPowerReduc * (oldPowerBattery + appliedControlBatt);
            obj.state.setEnergyBattery(newEnergyBattery);
        end
        
        function updatePowerAvailable(obj)
            % PA += DeltaPA
            oldPowerAvailable = obj.state.getPowerAvailable();
            newPowerAvailable = oldPowerAvailable + obj.disturbancePowerAvailable;
            obj.state.setPowerAvailable(newPowerAvailable);
        end
        
        function updatePowerGeneration(obj)
            % PG += DeltaPG(k) - DeltaPC(k - delayCurt)
            appliedControlCurt = obj.queueControlCurt(:,1);
            oldPowerGeneration = obj.state.getPowerGeneration();
            newPowerGeneration = oldPowerGeneration + obj.disturbancePowerGeneration ...
                - appliedControlCurt;
            obj.state.setPowerGeneration(newPowerGeneration);
        end
        
        function updatePowerCurtailment(obj)
            % PC += DeltaPC(k - delayCurt)
            appliedControlCurt = obj.queueControlCurt(:,1);
            obj.state.updatePowerCurtailment(appliedControlCurt);
        end
        
        function updatePowerBattery(obj)
            % PB += DeltaPB(k - delayBatt)
            appliedControlBatt = obj.queueControlBatt(:,1);
            obj.state.updatePowerBattery(appliedControlBatt);
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
            initialPowerAvailable = timeSeries.getInitialPowerAvailable();
            obj.state.setPowerAvailable(initialPowerAvailable);
        end
        
        function setInitialPowerGeneration(obj)
            % DEPRECATED
            powerAvailable = obj.state.getPowerAvailable();
            initialPowerGeneration = min(powerAvailable, obj.maxPowerGeneration);
            obj.state.setPowerGeneration(initialPowerGeneration);
        end
    end
    
end