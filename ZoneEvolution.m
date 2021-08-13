classdef ZoneEvolution < handle
    
   
    properties
        state
        
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
            memory.saveState(obj.state.getPowerFlow, ...
                obj.state.powerCurtailment, ...
                obj.state.powerBattery,...
                obj.state.energyBattery,...
                obj.state.powerGeneration,...
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
            f = powerAvailable ...
                + obj.disturbancePowerAvailable ...
                - obj.state.powerGeneration ...
                + obj.queueControlCurt(:,1);
            g = obj.maxPowerGeneration...
                - obj.state.powerCurtailment...
                - obj.state.powerGeneration;
            obj.disturbancePowerGeneration = min(f,g);
        end
        
        function updateState(obj)
            appliedControlCurt = obj.queueControlCurt(:,1);
            appliedControlBatt = obj.queueControlBatt(:,1);
            
            % energyBattery requires powerBattery, thus the former must be
            % updated prior to the latter
            % EB += -cb * ( PB(k) + DeltaPB(k - delayBatt) )
            obj.state.energyBattery = obj.state.energyBattery ...
                - obj.battConstPowerReduc * ...
                ( obj.state.powerBattery + appliedControlBatt);
            
            % PA += DeltaPA
            oldPowerAvailable = obj.state.getPowerAvailable();
            newPowerAvailable = oldPowerAvailable + obj.disturbancePowerAvailable;
            obj.state.setPowerAvailable(newPowerAvailable);
               
            % PG += DeltaPG(k) - DeltaPC(k - delayCurt)
            obj.state.powerGeneration = obj.state.powerGeneration ...
                + obj.disturbancePowerGeneration ...
                - appliedControlCurt;
            
            % PC += DeltaPC(k - delayCurt)
            obj.state.powerCurtailment = obj.state.powerCurtailment + appliedControlCurt;
            
            % PB += DeltaPB(k - delayBatt)
            obj.state.powerBattery = obj.state.powerBattery - appliedControlBatt;
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
            initialPowerAvailable = timeSeries.getInitialPowerAvailable();
            obj.state.setPowerAvailable(initialPowerAvailable);
        end
        
        function setInitialPowerGeneration(obj)
            powerAvailable = obj.state.getPowerAvailable;
            obj.state.powerGeneration = min(powerAvailable, obj.maxPowerGeneration);
        end
    end
    
end