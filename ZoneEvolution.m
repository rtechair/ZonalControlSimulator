classdef ZoneEvolution < handle
    
    
    properties (SetAccess = protected, GetAccess = protected)
        state
        
        queueControlCurt
        queueControlBatt
        queuePowerTransit % to compute disturbancePowerTransit
        
        disturbancePowerTransit
        disturbancePowerGeneration
        disturbancePowerAvailable
    end
    
    properties (SetAccess = immutable, GetAccess = protected)
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
            obj.disturbancePowerAvailable = objectDisturbancePowerAvailable.getValue();
        end
        
        function receiveControl(obj, controlOfZone)
            obj.queueControlCurt(:,end+1) = controlOfZone.getControlCurtailment;
            obj.queueControlBatt(:,end+1) = controlOfZone.getControlBattery;
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
            f = powerAvailable ...
                + obj.disturbancePowerAvailable ...
                - powerGeneration ...
                + appliedControlCurt;
            
            powerCurtailment = obj.state.getPowerCurtailment;
            g = obj.maxPowerGeneration...
                - powerCurtailment...
                - powerGeneration;
            obj.disturbancePowerGeneration = min(f,g);
        end
        
        function updateState(obj)
            appliedControlCurt = obj.queueControlCurt(:,1);
            appliedControlBatt = obj.queueControlBatt(:,1);
            
            % energyBattery requires powerBattery, thus the former must be
            % updated prior to the latter
            % EB += -cb * ( PB(k) + DeltaPB(k - delayBatt) )
            oldPowerBattery = obj.state.getPowerBattery;
            oldEnergyBattery = obj.state.getEnergyBattery;
            newEnergyBattery = oldEnergyBattery - obj.battConstPowerReduc * ...
                (oldPowerBattery + appliedControlBatt);
            obj.state.setEnergyBattery(newEnergyBattery);
            
            % PA += DeltaPA
            oldPowerAvailable = obj.state.getPowerAvailable();
            newPowerAvailable = oldPowerAvailable + obj.disturbancePowerAvailable;
            obj.state.setPowerAvailable(newPowerAvailable);
               
            % PG += DeltaPG(k) - DeltaPC(k - delayCurt)
            oldPowerGeneration = obj.state.getPowerGeneration();
            newPowerGeneration = oldPowerGeneration + obj.disturbancePowerGeneration ...
                - appliedControlCurt;
            obj.state.setPowerGeneration(newPowerGeneration);
            
            % PC += DeltaPC(k - delayCurt)
            oldPowerCurtailment = obj.state.getPowerCurtailment;
            newPowerCurtailment = oldPowerCurtailment + appliedControlCurt;
            obj.state.setPowerCurtailment(newPowerCurtailment);
            
            % PB += DeltaPB(k - delayBatt)
            newPowerBattery = oldPowerBattery - appliedControlBatt;
            obj.state.setPowerBattery(newPowerBattery);
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
            initialPowerAvailable = timeSeries.getInitialPowerAvailable();
            obj.state.setPowerAvailable(initialPowerAvailable);
        end
        
        function setInitialPowerGeneration(obj)
            powerAvailable = obj.state.getPowerAvailable;
            initialPowerGeneration = min(powerAvailable, obj.maxPowerGeneration);
            obj.state.setPowerGeneration(initialPowerGeneration);
        end
    end
    
end