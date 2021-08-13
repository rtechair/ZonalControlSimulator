classdef ZoneEvolution < handle
    
   
    properties
        state
        
        queueControlCurt
        queueControlBatt
        
        queuePowerTransit % to compute disturbanceTransit
        
        disturbanceTransit
        disturbanceGeneration
        disturbanceAvailable
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
            obj.disturbanceTransit = zeros(numberOfBuses, 1);
        end
        
        function receiveTimeSeries(obj, disturbancePowerAvailable)
            obj.disturbanceAvailable = disturbancePowerAvailable.getValue();
        end
        
        function receiveControl(obj, controlOfZone)
            obj.queueControlCurt(:,end+1) = controlOfZone.controlCurtailment;
            obj.queueControlBatt(:,end+1) = controlOfZone.controlBattery;
        end
        
        function dropOldestControl(obj)
            obj.queueControlCurt = obj.queueControlCurt(:, 2:end);
            obj.queueControlBatt = obj.queueControlBatt(:, 2:end);
        end
        
        function updatePowerTransit(obj, electricalGrid, zoneBusesId, branchBorderIdx)
            obj.queuePowerTransit(:,end+1) = ...
                electricalGrid.getPowerTransit(zoneBusesId, branchBorderIdx);
        end
                
        function updateDisturbanceTransit(obj)
            obj.disturbanceTransit = obj.queuePowerTransit(:,2) - obj.queuePowerTransit(:,1);
        end
        
        function dropOldestPowerTransit(obj)
            obj.queuePowerTransit = obj.queuePowerTransit(:,2);
        end
        
        function saveState(obj, memory)
            memory.saveState(obj.state.powerFlow, ...
                obj.state.powerCurtailment, ...
                obj.state.powerBattery,...
                obj.state.energyBattery,...
                obj.state.powerGeneration,...
                obj.state.powerAvailable);
        end
        
        function saveDisturbance(obj, memory)
            memory.saveDisturbance(obj.disturbanceTransit,...
                obj.disturbanceGeneration,...
                obj.disturbanceAvailable);
        end
        
        function object = getStateAndDisturbancePowerTransit(obj)
            object = StateAndDisturbancePowerTransit(obj.state, obj.disturbanceTransit);
        end
        
        function computeDisturbanceGeneration(obj)
            % DeltaPG = min(f,g)
            % with  f = PA    + DeltaPA - PG + DeltaPC(k - delayCurt)
            % and   g = maxPG - PC      - PG
            f = obj.state.powerAvailable ...
                + obj.disturbanceAvailable ...
                - obj.state.powerGeneration ...
                + obj.queueControlCurt(:,1);
            g = obj.maxPowerGeneration...
                - obj.state.powerCurtailment...
                - obj.state.powerGeneration;
            obj.disturbanceGeneration = min(f,g);
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
            obj.state.powerAvailable = obj.state.powerAvailable + obj.disturbanceAvailable;
               
            % PG += DeltaPG(k) - DeltaPC(k - delayCurt)
            obj.state.powerGeneration = obj.state.powerGeneration ...
                + obj.disturbanceGeneration ...
                - appliedControlCurt;
            
            % PC += DeltaPC(k - delayCurt)
            obj.state.powerCurtailment = obj.state.powerCurtailment + appliedControlCurt;
            
            % PB += DeltaPB(k - delayBatt)
            obj.state.powerBattery = obj.state.powerBattery - appliedControlBatt;
        end
        
        function setInitialPowerAvailable(obj, timeSeries)
           obj.state.powerAvailable = timeSeries.getInitialPowerAvailable(); 
        end
        
        function setInitialPowerGeneration(obj)
           obj.state.powerGeneration = min(obj.state.powerAvailable, obj.maxPowerGeneration); 
        end
    end
    
end